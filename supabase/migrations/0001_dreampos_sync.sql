-- =============================================================================
-- DreamPOS multi-register sync: server side (D-025, docs/specs/multi-register-sync.md §7).
--
-- Target: Supabase (PostgreSQL 15). Run once in the SQL editor of the project
-- (see docs/SYNC_SETUP.md). The script is idempotent: running it again only
-- (re)creates missing objects and replaces the functions and policies.
--
-- Principles
--   * The server is a dumb, append-only change log per store. It never looks
--     inside `payload` (the raw SQLite row of the register) and never merges.
--     Conflict resolution happens on the registers (row-level LWW by version).
--   * Nothing in this file deletes rows. Retention/compaction is a later stage.
--   * Clients never write tables directly: every write goes through the
--     SECURITY DEFINER functions below, which check membership first.
--     Row level security lets a signed-in user read only the rows of stores
--     they are a member of; anonymous users get nothing.
--   * `changes.seq` is global, but within one store it is assigned in commit
--     order (push_changes locks the store row), so a register that pulled up to
--     seq N can never miss a change of its store with seq <= N.
--
-- Wire format (must match lib/core/sync/transport.dart, SyncChange.toJson):
--   {"change_id": uuid, "entity": text, "entity_id": text,
--    "op": "upsert" | "delete", "version": bigint, "device_id": uuid,
--    "payload": object | null, "seq": bigint (server -> client only)}
--
-- RPC parameter names (JSON body keys of POST /rest/v1/rpc/<name>):
--   create_store(p_name, p_environment)                -> uuid (store id)
--   register_device(p_store_id, p_device_id, p_name)   -> text (code A, B, ... Z, AA, ...)
--   store_info(p_store_id)                             -> {id, name, environment, has_data}
--   list_stores()                                      -> [{id, name, environment, has_data}]
--   push_changes(p_store_id, p_device_id, p_changes)   -> {accepted, max_seq}
--   pull_changes(p_store_id, p_since, p_max)           -> [change, ...] ordered by seq
--
-- Errors are raised with a stable message the client maps to SyncErrorKind:
--   not_authenticated (42501), not_member (42501), store_not_found,
--   invalid_name, invalid_environment, invalid_changes, device_not_registered,
--   device_mismatch, too_many_changes (all others: P0001 / 22023).
-- =============================================================================

-- ----------------------------------------------------------------- tables

create table if not exists public.stores (
  id          uuid        primary key default gen_random_uuid(),
  name        text        not null check (length(btrim(name)) between 1 and 200),
  environment text        not null check (environment in ('test', 'production')),
  created_by  uuid        not null references auth.users (id),
  created_at  timestamptz not null default now()
);

create table if not exists public.store_members (
  store_id   uuid        not null references public.stores (id),
  user_id    uuid        not null references auth.users (id),
  -- Informational only: every member has FULL access to the store's data
  -- (reads every row incl. users' PIN hashes, pushes any change). Who may do
  -- what at the till is enforced by the registers (user roles + PINs), not by
  -- the cloud account. Give cloud accounts to the owner / trusted admins only.
  role       text        not null default 'owner' check (role in ('owner', 'admin', 'cashier')),
  created_at timestamptz not null default now(),
  primary key (store_id, user_id)
);

create index if not exists store_members_user_idx on public.store_members (user_id);

-- One row per register and store. `id` is the register's device id (uuid
-- generated once per local database). The primary key is (store_id, id), so
-- one database may be registered in more than one store over its lifetime
-- (same semantics as the in-memory test server).
create table if not exists public.devices (
  id           uuid        not null,
  store_id     uuid        not null references public.stores (id),
  code         text        not null check (code ~ '^[A-Z]+$'),
  name         text,
  register_id  text,
  created_at   timestamptz not null default now(),
  last_seen_at timestamptz,
  primary key (store_id, id),
  unique (store_id, code)
);

create table if not exists public.changes (
  seq         bigserial   primary key,
  store_id    uuid        not null references public.stores (id),
  change_id   uuid        not null unique,
  device_id   uuid        not null,
  entity      text        not null check (length(entity) between 1 and 100),
  entity_id   text        not null check (length(entity_id) between 1 and 200),
  op          text        not null check (op in ('upsert', 'delete')),
  -- millisecond clock; above 2200-01-01 only a broken / hand-made client
  -- (it would overflow the clients' hybrid clock), see maxSyncVersion
  version     bigint      not null check (version between 0 and 7258118400000),
  payload     jsonb,
  received_at timestamptz not null default now(),
  constraint changes_payload_matches_op check (
    (op = 'upsert' and jsonb_typeof(payload) = 'object')
    or (op = 'delete' and payload is null)
  )
);

create index if not exists changes_store_seq_idx on public.changes (store_id, seq);

-- -------------------------------------------------------- privileges + RLS

alter table public.stores        enable row level security;
alter table public.store_members enable row level security;
alter table public.devices       enable row level security;
alter table public.changes       enable row level security;

-- Supabase grants everything on new public tables to anon/authenticated by
-- default. Take it back: reads only, for signed-in users, filtered by RLS.
revoke all on table public.stores, public.store_members, public.devices, public.changes from anon, authenticated;
grant select on table public.stores, public.store_members, public.devices, public.changes to authenticated;
revoke all on sequence public.changes_seq_seq from anon, authenticated;

-- Membership test used by the policies and the RPCs. SECURITY DEFINER so the
-- store_members policy does not recurse into itself.
create or replace function public.is_store_member(p_store_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.store_members m
    where m.store_id = p_store_id
      and m.user_id = auth.uid()
  );
$$;

revoke all on function public.is_store_member(uuid) from public, anon, authenticated;
grant execute on function public.is_store_member(uuid) to authenticated;

drop policy if exists stores_select_member on public.stores;
create policy stores_select_member on public.stores
  for select to authenticated
  using (public.is_store_member(id));

drop policy if exists store_members_select_member on public.store_members;
create policy store_members_select_member on public.store_members
  for select to authenticated
  using (user_id = auth.uid() or public.is_store_member(store_id));

drop policy if exists devices_select_member on public.devices;
create policy devices_select_member on public.devices
  for select to authenticated
  using (public.is_store_member(store_id));

drop policy if exists changes_select_member on public.changes;
create policy changes_select_member on public.changes
  for select to authenticated
  using (public.is_store_member(store_id));

-- No INSERT / UPDATE / DELETE policies: with RLS enabled and the grants
-- revoked, clients can write only through the functions below.

-- ------------------------------------------------------------ helpers

-- Raises unless the caller is signed in and a member of the store.
create or replace function public.dreampos_require_member(p_store_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;
  if p_store_id is null or not exists (select 1 from public.stores s where s.id = p_store_id) then
    raise exception 'store_not_found';
  end if;
  if not public.is_store_member(p_store_id) then
    raise exception 'not_member' using errcode = '42501';
  end if;
end;
$$;

-- 0 -> A, 25 -> Z, 26 -> AA, 27 -> AB ... (same as deviceCodeForIndex in
-- lib/core/sync/transport.dart).
create or replace function public.dreampos_device_code(p_index integer)
returns text
language plpgsql
immutable
strict
set search_path = ''
as $$
declare
  v_n   integer := p_index + 1;
  v_out text    := '';
begin
  if p_index < 0 then
    raise exception 'invalid_index' using errcode = '22023';
  end if;
  while v_n > 0 loop
    v_n   := v_n - 1;
    v_out := chr(65 + v_n % 26) || v_out;
    v_n   := v_n / 26;
  end loop;
  return v_out;
end;
$$;

create or replace function public.dreampos_store_json(p_store_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', s.id,
    'name', s.name,
    'environment', s.environment,
    'has_data', exists (select 1 from public.changes c where c.store_id = s.id)
  )
  from public.stores s
  where s.id = p_store_id;
$$;

revoke all on function public.dreampos_require_member(uuid) from public, anon, authenticated;
revoke all on function public.dreampos_device_code(integer) from public, anon, authenticated;
revoke all on function public.dreampos_store_json(uuid) from public, anon, authenticated;

-- --------------------------------------------------------------- RPCs

-- Creates a store; the caller becomes its owner. The environment can never
-- be changed afterwards (no function updates it, clients cannot write).
create or replace function public.create_store(p_name text, p_environment text)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_id  uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;
  if p_name is null or length(btrim(p_name)) not between 1 and 200 then
    raise exception 'invalid_name' using errcode = '22023';
  end if;
  if p_environment is null or p_environment not in ('test', 'production') then
    raise exception 'invalid_environment' using errcode = '22023';
  end if;

  insert into public.stores (name, environment, created_by)
  values (btrim(p_name), p_environment, v_uid)
  returning id into v_id;

  insert into public.store_members (store_id, user_id, role)
  values (v_id, v_uid, 'owner');

  return v_id;
end;
$$;

-- Registers a register (device) in a store and returns its letter code.
-- Idempotent per (store, device id): a second call returns the same code.
create or replace function public.register_device(p_store_id uuid, p_device_id uuid, p_name text)
returns text
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_code text;
  v_i    integer := 0;
begin
  perform public.dreampos_require_member(p_store_id);
  if p_device_id is null then
    raise exception 'invalid_device' using errcode = '22023';
  end if;

  -- Serialises code allocation (and pushes) per store.
  perform 1 from public.stores s where s.id = p_store_id for update;

  select d.code into v_code
  from public.devices d
  where d.store_id = p_store_id and d.id = p_device_id;

  if found then
    update public.devices d
    set last_seen_at = now(),
        name = coalesce(nullif(btrim(p_name), ''), d.name)
    where d.store_id = p_store_id and d.id = p_device_id;
    return v_code;
  end if;

  loop
    v_code := public.dreampos_device_code(v_i);
    exit when not exists (
      select 1 from public.devices d where d.store_id = p_store_id and d.code = v_code
    );
    v_i := v_i + 1;
  end loop;

  insert into public.devices (id, store_id, code, name, last_seen_at)
  values (p_device_id, p_store_id, v_code, nullif(btrim(p_name), ''), now());

  return v_code;
end;
$$;

-- Name, environment and has_data (the store already has changes).
create or replace function public.store_info(p_store_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.dreampos_require_member(p_store_id);
  return public.dreampos_store_json(p_store_id);
end;
$$;

-- Stores the caller is a member of (for «Подключить к существующему»).
create or replace function public.list_stores()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_out jsonb;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;
  select coalesce(jsonb_agg(public.dreampos_store_json(s.id) order by s.created_at, s.id), '[]'::jsonb)
  into v_out
  from public.stores s
  join public.store_members m on m.store_id = s.id and m.user_id = v_uid;
  return v_out;
end;
$$;

-- Appends a batch of changes. Idempotent on change_id: a retried batch
-- (response lost after the server accepted it) inserts nothing new.
-- Returns {accepted: rows inserted now, max_seq: highest seq of the store}.
create or replace function public.push_changes(p_store_id uuid, p_device_id uuid, p_changes jsonb)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_change   jsonb;
  v_accepted integer := 0;
  v_rows     integer;
  v_max      bigint;
begin
  perform public.dreampos_require_member(p_store_id);
  if p_changes is null or jsonb_typeof(p_changes) <> 'array' then
    raise exception 'invalid_changes' using errcode = '22023';
  end if;
  if jsonb_array_length(p_changes) > 1000 then
    raise exception 'too_many_changes' using errcode = '22023';
  end if;

  -- Lock the store row until commit: seqs of one store are then assigned in
  -- commit order, so a concurrent pull never skips a lower seq.
  perform 1 from public.stores s where s.id = p_store_id for update;

  if not exists (
    select 1 from public.devices d where d.store_id = p_store_id and d.id = p_device_id
  ) then
    raise exception 'device_not_registered' using errcode = '22023';
  end if;

  for v_change in
    select e.value
    from jsonb_array_elements(p_changes) with ordinality as e(value, ord)
    order by e.ord
  loop
    if jsonb_typeof(v_change) <> 'object' then
      raise exception 'invalid_changes' using errcode = '22023';
    end if;
    -- A row is a flat object of scalars (clients reject anything else).
    if jsonb_typeof(v_change -> 'payload') = 'object' and exists (
      select 1 from jsonb_each(v_change -> 'payload') p where jsonb_typeof(p.value) in ('object', 'array')
    ) then
      raise exception 'invalid_changes' using errcode = '22023';
    end if;
    if (v_change ->> 'device_id')::uuid is distinct from p_device_id then
      raise exception 'device_mismatch' using errcode = '22023';
    end if;

    insert into public.changes (store_id, change_id, device_id, entity, entity_id, op, version, payload)
    values (
      p_store_id,
      (v_change ->> 'change_id')::uuid,
      p_device_id,
      v_change ->> 'entity',
      v_change ->> 'entity_id',
      v_change ->> 'op',
      (v_change ->> 'version')::bigint,
      nullif(v_change -> 'payload', 'null'::jsonb)
    )
    on conflict (change_id) do nothing;

    get diagnostics v_rows = row_count;
    v_accepted := v_accepted + v_rows;
  end loop;

  update public.devices d
  set last_seen_at = now()
  where d.store_id = p_store_id and d.id = p_device_id;

  select coalesce(max(c.seq), 0) into v_max
  from public.changes c
  where c.store_id = p_store_id;

  return jsonb_build_object('accepted', v_accepted, 'max_seq', v_max);
end;
$$;

-- Changes of the store with seq > p_since, ordered by seq, at most p_max
-- (1..1000, default 500). Returned as one JSON array so the order is kept.
create or replace function public.pull_changes(p_store_id uuid, p_since bigint, p_max integer default 500)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_limit integer := least(greatest(coalesce(p_max, 500), 1), 1000);
  v_out   jsonb;
begin
  perform public.dreampos_require_member(p_store_id);

  select coalesce(
           jsonb_agg(
             jsonb_build_object(
               'seq', c.seq,
               'change_id', c.change_id,
               'entity', c.entity,
               'entity_id', c.entity_id,
               'op', c.op,
               'version', c.version,
               'device_id', c.device_id,
               'payload', c.payload
             )
             order by c.seq
           ),
           '[]'::jsonb
         )
  into v_out
  from (
    select ch.*
    from public.changes ch
    where ch.store_id = p_store_id
      and ch.seq > coalesce(p_since, 0)
    order by ch.seq
    limit v_limit
  ) c;

  return v_out;
end;
$$;

-- Only signed-in users may call the RPCs (each one checks membership itself).
revoke all on function public.create_store(text, text) from public, anon;
revoke all on function public.register_device(uuid, uuid, text) from public, anon;
revoke all on function public.store_info(uuid) from public, anon;
revoke all on function public.list_stores() from public, anon;
revoke all on function public.push_changes(uuid, uuid, jsonb) from public, anon;
revoke all on function public.pull_changes(uuid, bigint, integer) from public, anon;

grant execute on function public.create_store(text, text) to authenticated;
grant execute on function public.register_device(uuid, uuid, text) to authenticated;
grant execute on function public.store_info(uuid) to authenticated;
grant execute on function public.list_stores() to authenticated;
grant execute on function public.push_changes(uuid, uuid, jsonb) to authenticated;
grant execute on function public.pull_changes(uuid, bigint, integer) to authenticated;

-- Make PostgREST see the new functions right away.
-- Re-running on a database created by an earlier version of this script.
alter table public.store_members alter column role set default 'owner';
comment on column public.store_members.role is
  'Informational only: every member has full access to the store data (PIN hashes, users, settings). '
  'Till permissions are enforced by the registers, not by this role.';

notify pgrst, 'reload schema';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'product_logic.dart';
import 'product_widgets.dart';
import 'products_repo.dart';

/// Create ([category] == null) or rename/recolor a category.
/// Returns the category id on save.
Future<String?> showCategoryEditDialog(BuildContext context, {Category? category}) =>
    showDialog<String>(context: context, builder: (_) => _CategoryEditDialog(category: category));

class _CategoryEditDialog extends ConsumerStatefulWidget {
  const _CategoryEditDialog({this.category});
  final Category? category;

  @override
  ConsumerState<_CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends ConsumerState<_CategoryEditDialog> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.category?.name ?? '');
  late int _color = widget.category?.color ?? categoryPalette.first;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_key.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final id = await ref
          .read(productsRepoProvider)
          .saveCategory(id: widget.category?.id, name: _name.text, color: _color);
      if (mounted) Navigator.pop(context, id);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Новая категория' : 'Категория'),
      content: Form(
        key: _key,
        child: SizedBox(
          width: 380,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Название *', counterText: ''),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Введите название' : null,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: Gap.l),
            Text('Цвет', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: Gap.s),
            Wrap(spacing: Gap.s, runSpacing: Gap.s, children: [
              for (final c in categoryPalette)
                Semantics(
                  label: 'Цвет',
                  selected: c == _color,
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                            width: 3,
                            color: c == _color ? Theme.of(context).colorScheme.onSurface : Colors.transparent),
                      ),
                      child: c == _color ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                    ),
                  ),
                ),
            ]),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(onPressed: _busy ? null : _save, child: const Text('Сохранить')),
      ],
    );
  }
}

/// Full categories management: list, reorder, edit, delete.
Future<void> showCategoriesManager(BuildContext context) => showFormDialog<void>(
      context,
      title: 'Категории',
      width: 560,
      child: const _CategoriesManager(),
    );

class _CategoriesManager extends ConsumerStatefulWidget {
  const _CategoriesManager();
  @override
  ConsumerState<_CategoriesManager> createState() => _CategoriesManagerState();
}

class _CategoriesManagerState extends ConsumerState<_CategoriesManager> {
  List<Category>? _local; // optimistic order while reordering

  Future<void> _delete(Category c, List<Category> all) async {
    final repo = ref.read(productsRepoProvider);
    final userId = ref.read(sessionProvider)?.user.id;
    final count = await repo.categoryProductCount(c.id);
    if (!mounted) return;
    if (count == 0) {
      final ok = await confirm(context,
          title: 'Удалить категорию «${c.name}»?',
          message: 'В категории нет товаров.',
          ok: 'Удалить',
          destructive: true);
      if (!ok || !mounted) return;
      await runGuarded(context, () => repo.deleteCategory(c.id, userId: userId),
          success: 'Категория удалена');
      return;
    }
    // Has products: ask where to move them.
    String? target;
    final others = all.where((x) => x.id != c.id).toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dc) => StatefulBuilder(
        builder: (dc, setS) => AlertDialog(
          title: Text('Удалить «${c.name}»?'),
          content: SizedBox(
            width: 400,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('В категории $count товаров. Куда их перенести?'),
              const SizedBox(height: Gap.l),
              DropdownButtonFormField<String?>(
                initialValue: target,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Перенести в'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Без категории')),
                  for (final o in others)
                    DropdownMenuItem(
                      value: o.id,
                      child: Row(children: [
                        CategoryDot(color: o.color),
                        const SizedBox(width: Gap.s),
                        Flexible(child: Text(o.name, overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                ],
                onChanged: (v) => setS(() => target = v),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dc, false), child: const Text('Отмена')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(dc, true),
              child: const Text('Перенести и удалить'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    await runGuarded(
        context, () => repo.deleteCategory(c.id, moveTo: target, moveToNone: target == null, userId: userId),
        success: 'Категория удалена, товары перенесены');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final canEdit = session?.can(Perm.editProducts) ?? false;
    final cats = ref.watch(productCategoriesProvider);
    final counts = ref.watch(categoryCountsProvider).value ?? const {};
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, Gap.l),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (canEdit)
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: () => showCategoryEditDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Новая категория'),
            ),
          ),
        const SizedBox(height: Gap.s),
        Flexible(
          child: AsyncView<List<Category>>(
            value: cats,
            data: (list) {
              if (_local != null && _local!.length == list.length) list = _local!;
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.category_outlined,
                  title: 'Категорий пока нет',
                  message: 'Категории помогают быстро находить товары на кассе и в отчётах.',
                );
              }
              return ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 120, maxHeight: 520),
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemCount: list.length,
                  onReorder: !canEdit
                      ? (_, _) {}
                      : (from, to) {
                          final l = [...list];
                          if (to > from) to--;
                          l.insert(to, l.removeAt(from));
                          setState(() => _local = l);
                          ref
                              .read(productsRepoProvider)
                              .reorderCategories([for (final c in l) c.id]).whenComplete(() {
                            if (mounted) setState(() => _local = null);
                          });
                        },
                  itemBuilder: (_, i) {
                    final c = list[i];
                    return ListTile(
                      key: ValueKey(c.id),
                      contentPadding: const EdgeInsets.only(left: Gap.s, right: 0),
                      leading: canEdit
                          ? ReorderableDragStartListener(
                              index: i,
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.drag_indicator),
                              ))
                          : CategoryDot(color: c.color, size: 14),
                      title: Row(children: [
                        if (canEdit) ...[CategoryDot(color: c.color, size: 14), const SizedBox(width: Gap.s)],
                        Flexible(child: Text(c.name, overflow: TextOverflow.ellipsis)),
                      ]),
                      subtitle: Text('Товаров: ${counts[c.id] ?? 0}'),
                      trailing: !canEdit
                          ? null
                          : Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                  tooltip: 'Изменить',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => showCategoryEditDialog(context, category: c)),
                              IconButton(
                                  tooltip: 'Удалить',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _delete(c, list)),
                            ]),
                    );
                  },
                ),
              );
            },
          ),
        ),
        if (canEdit)
          Padding(
            padding: const EdgeInsets.only(top: Gap.s),
            child: Text('Перетащите, чтобы изменить порядок на кассе. '
                'Без категории: ${counts[null] ?? 0} товаров.',
                style: Theme.of(context).textTheme.bodySmall),
          ),
      ]),
    );
  }
}

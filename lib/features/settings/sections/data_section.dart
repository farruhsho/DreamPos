import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../settings_logic.dart';
import '../settings_providers.dart';
import '../settings_widgets.dart';

/// «Данные»: demo mode info and CSV export.
class DataSection extends ConsumerStatefulWidget {
  const DataSection({super.key});

  @override
  ConsumerState<DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends ConsumerState<DataSection> {
  String? _busy;
  File? _lastExport;

  Future<void> _export(String what) async {
    setState(() => _busy = what);
    final svc = ref.read(backupServiceProvider);
    File? f;
    await runGuarded(context, () async {
      f = what == 'products'
          ? await svc.exportProducts(userId: currentUserId(ref))
          : await svc.exportCustomers(userId: currentUserId(ref));
    });
    if (!mounted) return;
    setState(() {
      _busy = null;
      if (f != null) _lastExport = f;
    });
    if (f != null) showSuccess(context, 'Файл сохранён: ${f!.path}');
  }

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(settingProvider(SettingKeys.demoMode)) == '1';
    final dbPath = ref.watch(databasePathProvider).value;
    final t = Theme.of(context);

    Widget exportTile(String what, IconData icon, String title, String subtitle) => ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: OutlinedButton.icon(
            onPressed: _busy != null ? null : () => _export(what),
            icon: _busy == what
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.file_download_outlined),
            label: const Text('CSV'),
          ),
        );

    return SectionView(
      title: 'Данные',
      description: 'Демо-режим и выгрузка справочников в файлы для Excel.',
      children: [
        SectionCard(
          title: 'Режим работы',
          trailing: StatusChip(demo ? 'Демо-режим' : 'Рабочая база',
              color: demo ? AppColors.warning : AppColors.success),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
              demo
                  ? 'Сейчас в базе демонстрационные товары, клиенты и продажи. Они нужны, чтобы '
                      'познакомиться с программой. Не смешивайте их с реальной торговлей.'
                  : 'Программа работает с реальными данными магазина.',
            ),
            if (demo) ...[
              const SizedBox(height: Gap.m),
              const InfoBanner(
                color: AppColors.warning,
                icon: Icons.warning_amber,
                text: 'Удалить демо-данные кнопкой нельзя: это необратимо и затронуло бы отчёты, '
                    'остатки и журнал. Чтобы начать работу с чистой базой:',
              ),
              const SizedBox(height: Gap.s),
              for (final (i, s) in [
                'Создайте резервную копию (раздел «Резервное копирование») — на случай, если демо-данные ещё понадобятся.',
                'Закройте программу.',
                'Удалите файл базы данных${dbPath == null ? '' : ':\n$dbPath'}\n'
                    'и, если есть, файлы рядом с ним с окончаниями «-wal» и «-shm».',
                'Запустите DreamPOS — откроется мастер первоначальной настройки. Не отмечайте «Демо-данные».',
              ].indexed)
                Padding(
                  padding: const EdgeInsets.only(top: Gap.xs),
                  child: Text('${i + 1}. $s'),
                ),
              if (dbPath != null) ...[
                const SizedBox(height: Gap.s),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => copyToClipboard(context, dbPath, message: 'Путь скопирован'),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Копировать путь к базе'),
                  ),
                ),
              ],
            ],
          ]),
        ),
        TileCard(title: 'Экспорт', children: [
          exportTile('products', Icons.inventory_2_outlined, 'Товары',
              'Наименование, штрихкод, цены, остатки'),
          exportTile('customers', Icons.people_outline, 'Клиенты',
              'Контакты, скидки, бонусы и долги'),
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, Gap.l),
            child: Text(
              'Файлы сохраняются в папку «Документы/DreamPOS/exports» в формате CSV '
              '(разделитель «;», кодировка UTF-8) — открываются в Excel и Google Таблицах. '
              'Файл клиентов содержит телефоны и долги — не пересылайте его посторонним.',
              style: t.textTheme.bodySmall,
            ),
          ),
          if (_lastExport != null)
            ListTile(
              leading: const Icon(Icons.check_circle, color: AppColors.success),
              title: const Text('Последний файл'),
              subtitle: SelectableText(_lastExport!.path),
              trailing: IconButton(
                tooltip: 'Копировать путь',
                icon: const Icon(Icons.copy),
                onPressed: () => copyToClipboard(context, _lastExport!.path, message: 'Путь скопирован'),
              ),
            ),
        ]),
      ],
    );
  }
}

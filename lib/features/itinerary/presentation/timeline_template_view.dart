import 'package:flutter/material.dart';

import '../domain/timeline_template.dart';

const _kBigTitle = '京都の旅のしおり';

/// タイムラインテンプレートの見た目（読み取り専用）。
/// エディタ画面のプレビュー・しおり閲覧画面の両方で使う。
class TimelineTemplateView extends StatelessWidget {
  const TimelineTemplateView({super.key, required this.data});

  final TimelineTemplateData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.subtitle.isNotEmpty)
              Text(data.subtitle, style: theme.textTheme.bodyMedium),
            Text(
              _kBigTitle,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.cyan.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < data.days.length; i++) ...[
                  if (i > 0) const SizedBox(width: 16),
                  Expanded(child: _DayColumn(day: data.days[i])),
                ],
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _AccommodationBox(info: data.accommodation)),
                const SizedBox(width: 16),
                Expanded(child: _CheckBox(items: data.checkItems)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({required this.day});

  final TimelineDay day;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.cyan.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            day.label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        for (final item in day.items) _TimelineItemView(item: item),
      ],
    );
  }
}

class _TimelineItemView extends StatelessWidget {
  const _TimelineItemView({required this.item});

  final TimelineItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.cyan.shade200),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(item.time, style: const TextStyle(fontSize: 11)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (item.memo.isNotEmpty)
                  Text(item.memo, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccommodationBox extends StatelessWidget {
  const _AccommodationBox({required this.info});

  final AccommodationInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.cyan.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('今日のお宿', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (info.name.isNotEmpty)
            Text(info.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          if (info.address.isNotEmpty) Text(info.address, style: const TextStyle(fontSize: 11)),
          if (info.tel.isNotEmpty) Text('Tel. ${info.tel}', style: const TextStyle(fontSize: 11)),
          if (info.url.isNotEmpty) Text(info.url, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.items});

  final List<CheckItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.cyan.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Check!', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  if (item.description.isNotEmpty)
                    Text(item.description, style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

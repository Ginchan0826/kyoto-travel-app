import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/itinerary_providers.dart';
import '../domain/spot.dart';
import '../domain/timeline_template.dart';

const _kBigTitle = '京都の旅のしおり';

/// タイムラインテンプレートの編集フォーム。
/// 編集内容は都度 [onChanged] で親に通知し、親側で保存する。
class TimelineTemplateEditor extends ConsumerStatefulWidget {
  const TimelineTemplateEditor({
    super.key,
    required this.itineraryId,
    required this.data,
    required this.onChanged,
  });

  final String itineraryId;
  final TimelineTemplateData data;
  final ValueChanged<TimelineTemplateData> onChanged;

  @override
  ConsumerState<TimelineTemplateEditor> createState() =>
      _TimelineTemplateEditorState();
}

class _TimelineTemplateEditorState extends ConsumerState<TimelineTemplateEditor> {
  late TimelineTemplateData _data;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
  }

  void _update(TimelineTemplateData Function(TimelineTemplateData) updater) {
    setState(() => _data = updater(_data));
    widget.onChanged(_data);
  }

  Future<String?> _pickSpotName() async {
    List<Spot> spots;
    try {
      spots = await ref.read(spotsProvider(widget.itineraryId).future);
    } catch (_) {
      spots = const [];
    }
    if (!mounted) return null;
    if (spots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('エディタータブでスポットを追加してから使えます。')),
      );
      return null;
    }
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final spot in spots)
              ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(spot.name),
                onTap: () => Navigator.of(context).pop(spot.name),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(_kBigTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('大タイトルは固定です', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data.subtitle,
          decoration: const InputDecoration(
            labelText: 'サブタイトル（例：1/1〜2 温泉女子旅）',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _update((d) => d.copyWith(subtitle: value)),
        ),
        const SizedBox(height: 24),
        for (var dayIndex = 0; dayIndex < _data.days.length; dayIndex++)
          _DayEditor(
            day: _data.days[dayIndex],
            onPickSpotName: _pickSpotName,
            onChanged: (updatedDay) {
              _update((d) {
                final days = [...d.days];
                days[dayIndex] = updatedDay;
                return d.copyWith(days: days);
              });
            },
          ),
        const SizedBox(height: 24),
        Text('今日のお宿', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _data.accommodation.name,
          decoration: const InputDecoration(labelText: '宿名', border: OutlineInputBorder()),
          onChanged: (value) => _update(
            (d) => d.copyWith(accommodation: d.accommodation.copyWith(name: value)),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _data.accommodation.address,
          decoration: const InputDecoration(labelText: '住所', border: OutlineInputBorder()),
          onChanged: (value) => _update(
            (d) => d.copyWith(accommodation: d.accommodation.copyWith(address: value)),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _data.accommodation.tel,
          decoration: const InputDecoration(labelText: '電話番号', border: OutlineInputBorder()),
          onChanged: (value) => _update(
            (d) => d.copyWith(accommodation: d.accommodation.copyWith(tel: value)),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _data.accommodation.url,
          decoration: const InputDecoration(labelText: 'HP', border: OutlineInputBorder()),
          onChanged: (value) => _update(
            (d) => d.copyWith(accommodation: d.accommodation.copyWith(url: value)),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text('Check!', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: '項目を追加',
              onPressed: () {
                _update((d) => d.copyWith(
                      checkItems: [
                        ...d.checkItems,
                        const CheckItem(title: '', description: ''),
                      ],
                    ));
              },
            ),
          ],
        ),
        for (var i = 0; i < _data.checkItems.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  TextFormField(
                    initialValue: _data.checkItems[i].title,
                    decoration: const InputDecoration(labelText: 'タイトル'),
                    onChanged: (value) {
                      _update((d) {
                        final items = [...d.checkItems];
                        items[i] = items[i].copyWith(title: value);
                        return d.copyWith(checkItems: items);
                      });
                    },
                  ),
                  TextFormField(
                    initialValue: _data.checkItems[i].description,
                    maxLines: null,
                    decoration: const InputDecoration(labelText: '説明'),
                    onChanged: (value) {
                      _update((d) {
                        final items = [...d.checkItems];
                        items[i] = items[i].copyWith(description: value);
                        return d.copyWith(checkItems: items);
                      });
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        _update((d) {
                          final items = [...d.checkItems]..removeAt(i);
                          return d.copyWith(checkItems: items);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 48),
      ],
    );
  }
}

class _DayEditor extends StatelessWidget {
  const _DayEditor({
    required this.day,
    required this.onPickSpotName,
    required this.onChanged,
  });

  final TimelineDay day;
  final Future<String?> Function() onPickSpotName;
  final ValueChanged<TimelineDay> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(day.label, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: '予定を追加',
              onPressed: () {
                onChanged(
                  day.copyWith(items: [
                    ...day.items,
                    const TimelineItem(time: '', title: '', memo: ''),
                  ]),
                );
              },
            ),
          ],
        ),
        for (var i = 0; i < day.items.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          initialValue: day.items[i].time,
                          decoration: const InputDecoration(labelText: '時刻'),
                          onChanged: (value) {
                            final items = [...day.items];
                            items[i] = items[i].copyWith(time: value);
                            onChanged(day.copyWith(items: items));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: day.items[i].title,
                          decoration: const InputDecoration(labelText: 'タイトル'),
                          onChanged: (value) {
                            final items = [...day.items];
                            items[i] = items[i].copyWith(title: value);
                            onChanged(day.copyWith(items: items));
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.place_outlined),
                        tooltip: '登録スポットから選ぶ',
                        onPressed: () async {
                          final name = await onPickSpotName();
                          if (name == null) return;
                          final items = [...day.items];
                          items[i] = items[i].copyWith(title: name);
                          onChanged(day.copyWith(items: items));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          final items = [...day.items]..removeAt(i);
                          onChanged(day.copyWith(items: items));
                        },
                      ),
                    ],
                  ),
                  TextFormField(
                    initialValue: day.items[i].memo,
                    maxLines: null,
                    decoration: const InputDecoration(labelText: 'メモ'),
                    onChanged: (value) {
                      final items = [...day.items];
                      items[i] = items[i].copyWith(memo: value);
                      onChanged(day.copyWith(items: items));
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

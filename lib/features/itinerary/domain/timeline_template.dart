/// タイムライン形式テンプレート（DAY1/DAY2の時刻付きスケジュール）のデータ。
class TimelineTemplateData {
  const TimelineTemplateData({
    required this.subtitle,
    required this.days,
    required this.accommodation,
    required this.checkItems,
  });

  factory TimelineTemplateData.empty() {
    return TimelineTemplateData(
      subtitle: '',
      days: [
        TimelineDay(label: 'DAY1', items: const []),
        TimelineDay(label: 'DAY2', items: const []),
      ],
      accommodation: const AccommodationInfo(
        name: '',
        address: '',
        tel: '',
        url: '',
      ),
      checkItems: const [],
    );
  }

  final String subtitle;
  final List<TimelineDay> days;
  final AccommodationInfo accommodation;
  final List<CheckItem> checkItems;

  TimelineTemplateData copyWith({
    String? subtitle,
    List<TimelineDay>? days,
    AccommodationInfo? accommodation,
    List<CheckItem>? checkItems,
  }) {
    return TimelineTemplateData(
      subtitle: subtitle ?? this.subtitle,
      days: days ?? this.days,
      accommodation: accommodation ?? this.accommodation,
      checkItems: checkItems ?? this.checkItems,
    );
  }

  factory TimelineTemplateData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return TimelineTemplateData.empty();
    return TimelineTemplateData(
      subtitle: map['subtitle'] as String? ?? '',
      days: (map['days'] as List? ?? const [])
          .map((d) => TimelineDay.fromMap(Map<String, dynamic>.from(d as Map)))
          .toList(),
      accommodation: AccommodationInfo.fromMap(
        map['accommodation'] == null
            ? null
            : Map<String, dynamic>.from(map['accommodation'] as Map),
      ),
      checkItems: (map['checkItems'] as List? ?? const [])
          .map((c) => CheckItem.fromMap(Map<String, dynamic>.from(c as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subtitle': subtitle,
      'days': days.map((d) => d.toMap()).toList(),
      'accommodation': accommodation.toMap(),
      'checkItems': checkItems.map((c) => c.toMap()).toList(),
    };
  }
}

class TimelineDay {
  const TimelineDay({required this.label, required this.items});

  final String label;
  final List<TimelineItem> items;

  TimelineDay copyWith({String? label, List<TimelineItem>? items}) {
    return TimelineDay(label: label ?? this.label, items: items ?? this.items);
  }

  factory TimelineDay.fromMap(Map<String, dynamic> map) {
    return TimelineDay(
      label: map['label'] as String? ?? '',
      items: (map['items'] as List? ?? const [])
          .map((i) => TimelineItem.fromMap(Map<String, dynamic>.from(i as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'items': items.map((i) => i.toMap()).toList(),
    };
  }
}

class TimelineItem {
  const TimelineItem({required this.time, required this.title, required this.memo});

  final String time;
  final String title;
  final String memo;

  TimelineItem copyWith({String? time, String? title, String? memo}) {
    return TimelineItem(
      time: time ?? this.time,
      title: title ?? this.title,
      memo: memo ?? this.memo,
    );
  }

  factory TimelineItem.fromMap(Map<String, dynamic> map) {
    return TimelineItem(
      time: map['time'] as String? ?? '',
      title: map['title'] as String? ?? '',
      memo: map['memo'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'time': time, 'title': title, 'memo': memo};
  }
}

class AccommodationInfo {
  const AccommodationInfo({
    required this.name,
    required this.address,
    required this.tel,
    required this.url,
  });

  final String name;
  final String address;
  final String tel;
  final String url;

  AccommodationInfo copyWith({
    String? name,
    String? address,
    String? tel,
    String? url,
  }) {
    return AccommodationInfo(
      name: name ?? this.name,
      address: address ?? this.address,
      tel: tel ?? this.tel,
      url: url ?? this.url,
    );
  }

  factory AccommodationInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const AccommodationInfo(name: '', address: '', tel: '', url: '');
    }
    return AccommodationInfo(
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      tel: map['tel'] as String? ?? '',
      url: map['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'address': address, 'tel': tel, 'url': url};
  }
}

class CheckItem {
  const CheckItem({required this.title, required this.description});

  final String title;
  final String description;

  CheckItem copyWith({String? title, String? description}) {
    return CheckItem(
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }

  factory CheckItem.fromMap(Map<String, dynamic> map) {
    return CheckItem(
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'description': description};
  }
}

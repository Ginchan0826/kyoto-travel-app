import 'package:cloud_firestore/cloud_firestore.dart';

import 'canvas_element.dart';
import 'timeline_template.dart';

/// しおりの「デザイン編集画面」「しおり画面」を構成する1ページ。
/// 表紙も isCover: true の特別な1ページとして同じ仕組みで扱う。
class DesignPage {
  const DesignPage({
    required this.id,
    required this.order,
    required this.elements,
    required this.isCover,
    required this.backgroundColor,
    required this.useTemplate,
    required this.template,
  });

  final String id;
  final int order;
  final List<CanvasElement> elements;
  final bool isCover;
  final int? backgroundColor;
  final bool useTemplate;
  final TimelineTemplateData template;

  factory DesignPage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return DesignPage(
      id: doc.id,
      order: data['order'] as int? ?? 0,
      elements: (data['elements'] as List? ?? const [])
          .map((e) => CanvasElement.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      isCover: data['isCover'] as bool? ?? false,
      backgroundColor: data['backgroundColor'] as int?,
      useTemplate: data['useTemplate'] as bool? ?? false,
      template: TimelineTemplateData.fromMap(
        data['template'] == null
            ? null
            : Map<String, dynamic>.from(data['template'] as Map),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order': order,
      'elements': elements.map((e) => e.toMap()).toList(),
      'isCover': isCover,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      'useTemplate': useTemplate,
      'template': template.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

/// pages配列を「表紙（先頭で見つかった1件のみ）」と「本文ページ」に分ける。
/// 何らかの原因で isCover: true のページが複数存在していても、
/// 2枚目以降は本文ページとして扱い、表紙が重複して見えないようにする。
class SplitPages {
  const SplitPages({required this.cover, required this.contentPages});

  final DesignPage? cover;
  final List<DesignPage> contentPages;

  factory SplitPages.from(List<DesignPage> pages) {
    DesignPage? cover;
    final contentPages = <DesignPage>[];
    for (final page in pages) {
      if (page.isCover && cover == null) {
        cover = page;
      } else {
        contentPages.add(page);
      }
    }
    return SplitPages(cover: cover, contentPages: contentPages);
  }
}

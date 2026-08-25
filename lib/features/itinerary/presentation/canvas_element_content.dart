import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../domain/canvas_element.dart';

/// 1要素（画像・テキスト）の見た目を描画する部分。
/// デザイン編集画面（操作可能）としおり画面（閲覧のみ）の両方で
/// 全く同じ描画ロジックを使うことで表示のズレをなくす。
class CanvasElementContent extends StatelessWidget {
  const CanvasElementContent({
    super.key,
    required this.element,
    required this.scale,
    this.isSelected = false,
  });

  final CanvasElement element;
  final double scale;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final e = element;
    return SizedBox(
      width: e.width * scale,
      height: e.height * scale,
      child: Container(
        padding: e.type == 'text' ? const EdgeInsets.all(12) : EdgeInsets.zero,
        alignment: e.type == 'text' ? Alignment.center : null,
        decoration: BoxDecoration(
          color: e.type == 'text' ? Colors.white : null,
          border: isSelected
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
              : (e.type == 'text' ? Border.all(color: Colors.black26) : null),
        ),
        child: switch (e.type) {
          'text' => Text(
              e.text ?? '',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          _ => e.imageUrl == null
              ? const ColoredBox(color: Colors.grey)
              : CachedNetworkImage(
                  imageUrl: e.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => ColoredBox(
                    color: Colors.red.shade100,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
        },
      ),
    );
  }
}

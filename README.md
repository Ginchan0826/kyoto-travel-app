# kyoto_travel_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


授業用メモ
中心となるファイル

https://github.com/Ginchan0826/kyoto-travel-app/tree/main/lib/main.dart — 起動処理（Firebase初期化・.env読み込み）
https://github.com/Ginchan0826/kyoto-travel-app/tree/main/lib/features/home/presentation/main_shell_page.dart — 下部タブ（しおり/観光/閲覧/検索）の親画面
しおり機能（最も規模が大きい）

https://github.com/Ginchan0826/kyoto-travel-app/tree/main/lib/features/itinerary/data/itinerary_repository.dart — しおり・ページ・スポットのFirestore操作全般
https://github.com/Ginchan0826/kyoto-travel-app/tree/main/lib/features/itinerary/presentation/itinerary_workspace_page.dart — しおり1件の3タブ構成（エディター/デザイン/しおり）
https://github.com/Ginchan0826/kyoto-travel-app/tree/main/lib/features/itinerary/presentation/page_canvas_editor_page.dart — デザインキャンバス編集（画像配置・手書き・テンプレート）
https://github.com/Ginchan0826/kyoto-travel-app/tree/main/lib/features/itinerary/presentation/timeline_template_editor.dart / timeline_template_view.dart — DAY1/DAY2旅程表テンプレート
https://github.com/Ginchan0826/kyoto-travel-app/tree/main/lib/features/itinerary/presentation/spot_form_page.dart — スポット追加（Google検索連携）
https://github.com/Ginchan0826/kyoto-travel-app/tree/main/lib/features/itinerary/data/places_repository.dart — Google Places API連携
観光タブ（AIチャット）

https://github.com/Ginchan0826/kyoto-travel-app/tree/main/lib/features/touring/data/tour_guide_repository.dart — Gemini APIとのやり取り・プロンプト定義
https://github.com/Ginchan0826/kyoto-travel-app/tree/main/lib/features/touring/presentation/touring_spot_chat_page.dart — チャットUI
https://github.com/Ginchan0826/kyoto-travel-app/tree/main/lib/features/touring/data/spot_chat_history_repository.dart — チャット履歴の保存
検索タブ

[l](https://github.com/Ginchan0826/kyoto-travel-app/tree/main/)ib/features/spots/presentation/nearby_spots_page.dart — 現在地周辺の観光名所
認証

https://github.com/Ginchan0826/kyoto-travel-app/tree/main/lib/features/auth/data/auth_repository.dart — ログイン処理（メール/Google）
設定ファイル

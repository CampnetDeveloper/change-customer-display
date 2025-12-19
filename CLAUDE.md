# Change カスタマーディスプレイ

## プロジェクト概要

| 項目 | 内容 |
|------|------|
| 名前 | Change カスタマーディスプレイ |
| 言語 | Dart |
| フレームワーク | Flutter |
| 対象OS | Android |
| 目的 | iPad POSからのWebSocketコマンドを受信し、お客様向けに金額・商品情報を表示 |

## ディレクトリ構造

```
lib/
├── main.dart                    # アプリエントリーポイント
├── models/
│   ├── display_model.dart       # 表示データモデル
│   └── settings_model.dart      # 設定モデル
├── services/
│   ├── command_parser.dart      # コマンドパーサー
│   ├── settings_service.dart    # 設定保存サービス
│   └── websocket_server.dart    # WebSocketサーバー
├── providers/
│   ├── display_provider.dart    # 表示状態管理
│   └── settings_provider.dart   # 設定状態管理
├── screens/
│   ├── home_screen.dart         # メイン表示画面
│   └── settings_screen.dart     # 設定画面（バージョン情報・アップデート機能含む）
└── widgets/
    ├── display_widget.dart      # 受信内容表示ウィジェット（横向き最適化）
    └── slideshow_widget.dart    # スライドショーウィジェット

assets/
├── icon/
│   ├── app_icon.png             # アプリアイコン
│   └── app_icon_foreground.png  # アダプティブアイコン前景
└── splash/
    └── logo.png                 # スプラッシュ画面ロゴ
```

## 主要ファイル

| ファイル | 役割 |
|----------|------|
| `lib/main.dart` | アプリ起動、Provider設定、画面回転・スリープ制御 |
| `lib/services/websocket_server.dart` | WebSocketサーバー（ポート待受、接続管理） |
| `lib/services/command_parser.dart` | 受信コマンドのパース処理 |
| `lib/providers/display_provider.dart` | 表示状態管理、アイドルタイマー |
| `lib/screens/settings_screen.dart` | 設定画面、プレビュー機能、バージョン表示、アップデート機能 |
| `lib/widgets/display_widget.dart` | 横向き最適化された表示レイアウト |

## 外部連携/依存関係

| パッケージ | 用途 |
|------------|------|
| provider | 状態管理 |
| shared_preferences | 設定の永続化 |
| video_player | 動画再生（スライドショー） |
| file_picker | メディアファイル選択 |
| wakelock_plus | 画面スリープ防止 |
| permission_handler | 権限リクエスト |
| package_info_plus | バージョン情報取得 |
| in_app_update | Google Play アップデート機能 |
| flutter_native_splash | スプラッシュ画面 |
| flutter_launcher_icons | アプリアイコン生成 |

## コマンド仕様

WebSocket経由で受信するコマンドは`/`区切りのテキスト形式：

| コマンド | フォーマット | 例 |
|----------|--------------|-----|
| 1: 小計 | `1/小計/金額/商品名/数量/商品金額` | `1/小計/1,280円/みかんジェラート/640×2ケ/1,240円` |
| 2: 合計 | `2/合計/金額/割引/割引額` | `2/合計/9,120円/割引/200円` |
| 3: お預かり | `3/お預かり/金額/お釣り/釣銭額` | `3/お預かり/10,120円/お釣り/1,000円` |
| 4: 文字列 | `4/伝票番号/POS_UID` | `4/123456789/POS_TEST_001` |
| 9: クリア | `9/任意` | `9/表示クリア` |

## コーディング規約

- **命名規則**: lowerCamelCase（変数・メソッド）、UpperCamelCase（クラス）
- **状態管理**: Provider + ChangeNotifier
- **非同期処理**: async/await
- **エラーハンドリング**: try-catch + developer.log

## ビルド/実行方法

```bash
# 依存関係取得
flutter pub get

# 解析
flutter analyze

# テスト実行
flutter test

# デバッグビルド実行
flutter run

# リリースビルド（APK）
flutter build apk --release

# スプラッシュ画面再生成
dart run flutter_native_splash:create

# アプリアイコン再生成
dart run flutter_launcher_icons
```

## 運用設定

- **WebSocketポート**: デフォルト 8765（設定で変更可能、保存される）
- **アイドルタイムアウト**: デフォルト 60秒
- **画像表示秒数**: デフォルト 5秒
- **動画最大秒数**: デフォルト 30秒

## 画面操作

- **設定画面を開く**: 画面右上の歯車アイコン または 画面ダブルタップ
- **プレビュー**: 設定画面の「表示確認」ボタン
- **アップデート確認**: 設定画面上部の「更新確認」ボタン

## Google Play 公開手順

1. 署名キー作成: `keytool -genkey -v -keystore ~/upload-keystore.jks ...`
2. `android/key.properties` 作成
3. `flutter build appbundle --release`
4. Google Play Console でアプリ作成
5. AABファイルをアップロード
6. 審査に送信（1〜3日）

---

## 変更履歴

### 2025-12-20 初期実装

**指示**: iPad POSからのコマンドを受信し表示するAndroidカスタマーディスプレイアプリを実装

| 作業内容 | 詳細 |
|----------|------|
| 実装内容 | Flutterプロジェクト作成、WebSocketサーバー、コマンドパーサー、表示UI、設定画面、スライドショー、プレビュー機能 |
| 変更ファイル | lib/配下全ファイル新規作成、pubspec.yaml、AndroidManifest.xml、test/widget_test.dart |
| Git | 未コミット |
| 出力物 | ~/Desktop/POS_Display.apk |

### 2025-12-20 UI改善・機能追加

**指示**: 横向きレイアウト最適化、バージョン表示、アップデート機能、スプラッシュ画面、アプリアイコン設定

| 作業内容 | 詳細 |
|----------|------|
| UI改善 | 合計・お預かり画面を横並びレイアウトに変更（割引は赤枠、お釣りは緑枠で目立つ表示） |
| バージョン表示 | 設定画面上部にアプリ名・バージョン番号を表示 |
| アップデート機能 | Google Play In-App Update対応（package_info_plus, in_app_update） |
| スプラッシュ画面 | 会社ロゴ（ロゴ横.png）を使用したスプラッシュ画面 |
| アプリアイコン | 会社ロゴ（ロゴアイコン.png）を使用、全サイズ自動生成 |
| アプリ名変更 | 「Change カスタマーディスプレイ」に変更 |
| 変更ファイル | lib/screens/settings_screen.dart, lib/widgets/display_widget.dart, pubspec.yaml, android/app/build.gradle.kts, assets/ |
| 出力物 | ~/Desktop/POS_Display.apk (23MB) |

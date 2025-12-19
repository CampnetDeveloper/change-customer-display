import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/display_model.dart';
import '../providers/display_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/display_widget.dart';
import '../widgets/slideshow_widget.dart';
import 'settings_screen.dart';

/// ホーム画面（メイン表示画面）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // フルスクリーンモード
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // 横向き固定
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initializeServer();
  }

  Future<void> _initializeServer() async {
    final displayProvider = context.read<DisplayProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    // 設定読み込みを待つ
    if (!settingsProvider.isLoaded) {
      await settingsProvider.load();
    }

    final settings = settingsProvider.settings;
    displayProvider.setIdleTimeout(settings.idleTimeoutSeconds);
    await displayProvider.startServer(settings.websocketPort);
  }

  @override
  Widget build(BuildContext context) {
    final displayProvider = context.watch<DisplayProvider>();
    final displayModel = displayProvider.displayModel;

    return Scaffold(
      body: GestureDetector(
        onDoubleTap: () => _openSettings(),
        child: Stack(
          children: [
            // メインコンテンツ
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: displayModel.mode == DisplayMode.slideshow
                  ? const SlideshowWidget(key: ValueKey('slideshow'))
                  : DisplayWidget(
                      key: ValueKey('display_${displayModel.lastReceivedAt}'),
                      displayModel: displayModel,
                    ),
            ),

            // 設定ボタン（右上に小さく）
            Positioned(
              top: 16,
              right: 16,
              child: Opacity(
                opacity: 0.3,
                child: IconButton(
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: _openSettings,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';
import '../models/settings_model.dart';
import '../providers/display_provider.dart';
import '../providers/settings_provider.dart';
import '../services/websocket_server.dart';

/// 設定画面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _portController = TextEditingController();
  List<String> _ipAddresses = [];
  String _appVersion = '';
  String _buildNumber = '';
  AppUpdateInfo? _updateInfo;
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadIpAddresses();
    _loadAppVersion();
    _checkForUpdate();
    final settings = context.read<SettingsProvider>().settings;
    _portController.text = settings.websocketPort.toString();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  Future<void> _checkForUpdate() async {
    setState(() => _isCheckingUpdate = true);
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      setState(() {
        _updateInfo = updateInfo;
        _isCheckingUpdate = false;
      });
    } catch (e) {
      setState(() => _isCheckingUpdate = false);
    }
  }

  Future<void> _performUpdate() async {
    if (_updateInfo?.updateAvailability == UpdateAvailability.updateAvailable) {
      try {
        await InAppUpdate.performImmediateUpdate();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('アップデートに失敗しました: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _portController.dispose();
    super.dispose();
  }

  Future<void> _loadIpAddresses() async {
    final displayProvider = context.read<DisplayProvider>();
    final addresses = await displayProvider.getLocalIpAddresses();
    setState(() {
      _ipAddresses = addresses;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 設定画面では通常のシステムUIを表示
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // フルスクリーンに戻す
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVersionSection(),
            const Divider(height: 32),
            _buildConnectionSection(),
            const Divider(height: 32),
            _buildDisplaySection(),
            const Divider(height: 32),
            _buildIdleSection(),
            const Divider(height: 32),
            _buildSlideshowSection(),
            const Divider(height: 32),
            _buildPreviewSection(),
          ],
        ),
      ),
    );
  }

  /// バージョン情報セクション
  Widget _buildVersionSection() {
    final hasUpdate = _updateInfo?.updateAvailability == UpdateAvailability.updateAvailable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'アプリ情報',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 20),
            const SizedBox(width: 8),
            Text(
              'Change カスタマーディスプレイ',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'バージョン $_appVersion (ビルド $_buildNumber)',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            if (_isCheckingUpdate)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (hasUpdate)
              ElevatedButton.icon(
                onPressed: _performUpdate,
                icon: const Icon(Icons.system_update, size: 18),
                label: const Text('アップデート'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              )
            else
              TextButton.icon(
                onPressed: _checkForUpdate,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('更新確認'),
              ),
          ],
        ),
        if (hasUpdate) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: const Row(
              children: [
                Icon(Icons.new_releases, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  '新しいバージョンが利用可能です',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 通信設定セクション
  Widget _buildConnectionSection() {
    final displayProvider = context.watch<DisplayProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '通信設定',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 接続状態
        Row(
          children: [
            Icon(
              displayProvider.serverStatus == ServerStatus.running
                  ? Icons.check_circle
                  : Icons.error,
              color: displayProvider.serverStatus == ServerStatus.running
                  ? Colors.green
                  : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              _getStatusText(displayProvider.serverStatus),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 16),
            Text(
              '接続: ${displayProvider.clientCount}台',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // IPアドレス表示
        if (_ipAddresses.isNotEmpty) ...[
          const Text('IPアドレス:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ..._ipAddresses.map((ip) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: SelectableText(
                  'ws://$ip:${settingsProvider.settings.websocketPort}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              )),
          const SizedBox(height: 16),
        ],

        // ポート設定
        Row(
          children: [
            const Text('ポート: '),
            SizedBox(
              width: 100,
              child: TextField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () async {
                final port = int.tryParse(_portController.text) ?? 8765;
                await settingsProvider.updatePort(port);
                await displayProvider.stopServer();
                await displayProvider.startServer(port);
              },
              child: const Text('適用'),
            ),
          ],
        ),

        if (displayProvider.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            displayProvider.errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ],
    );
  }

  String _getStatusText(ServerStatus status) {
    switch (status) {
      case ServerStatus.stopped:
        return '停止中';
      case ServerStatus.starting:
        return '起動中...';
      case ServerStatus.running:
        return '動作中';
      case ServerStatus.error:
        return 'エラー';
    }
  }

  /// 表示設定セクション
  Widget _buildDisplaySection() {
    final settingsProvider = context.watch<SettingsProvider>();
    final settings = settingsProvider.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '表示設定',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // タイトルフォントサイズ
        _buildSliderRow(
          label: 'タイトルサイズ',
          value: settings.titleFontSize,
          min: 24,
          max: 96,
          onChanged: (v) => settingsProvider.updateTitleFontSize(v),
        ),

        // 金額フォントサイズ
        _buildSliderRow(
          label: '金額サイズ',
          value: settings.amountFontSize,
          min: 48,
          max: 200,
          onChanged: (v) => settingsProvider.updateAmountFontSize(v),
        ),

        // 明細フォントサイズ
        _buildSliderRow(
          label: '明細サイズ',
          value: settings.detailFontSize,
          min: 16,
          max: 64,
          onChanged: (v) => settingsProvider.updateDetailFontSize(v),
        ),

        // 太字設定
        SwitchListTile(
          title: const Text('太字'),
          value: settings.boldEnabled,
          onChanged: (v) => settingsProvider.updateBoldEnabled(v),
        ),

        // 文字色設定
        ListTile(
          title: const Text('文字色'),
          trailing: SegmentedButton<TextColorMode>(
            segments: const [
              ButtonSegment(value: TextColorMode.white, label: Text('白')),
              ButtonSegment(value: TextColorMode.black, label: Text('黒')),
            ],
            selected: {settings.textColorMode},
            onSelectionChanged: (v) => settingsProvider.updateTextColorMode(v.first),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(value.toInt().toString()),
          ),
        ],
      ),
    );
  }

  /// アイドル設定セクション
  Widget _buildIdleSection() {
    final settingsProvider = context.watch<SettingsProvider>();
    final displayProvider = context.read<DisplayProvider>();
    final settings = settingsProvider.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '待機復帰設定',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildSliderRow(
          label: 'タイムアウト(秒)',
          value: settings.idleTimeoutSeconds.toDouble(),
          min: 10,
          max: 300,
          onChanged: (v) {
            settingsProvider.updateIdleTimeout(v.toInt());
            displayProvider.setIdleTimeout(v.toInt());
          },
        ),
      ],
    );
  }

  /// スライドショー設定セクション
  Widget _buildSlideshowSection() {
    final settingsProvider = context.watch<SettingsProvider>();
    final settings = settingsProvider.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'スライドショー設定',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 画像表示秒数
        _buildSliderRow(
          label: '画像表示秒数',
          value: settings.imageDurationSeconds.toDouble(),
          min: 1,
          max: 30,
          onChanged: (v) => settingsProvider.updateImageDuration(v.toInt()),
        ),

        // 動画最大秒数
        _buildSliderRow(
          label: '動画最大秒数',
          value: settings.videoMaxSeconds.toDouble(),
          min: 5,
          max: 120,
          onChanged: (v) => settingsProvider.updateVideoMaxSeconds(v.toInt()),
        ),

        const SizedBox(height: 16),

        // メディア追加ボタン
        ElevatedButton.icon(
          onPressed: _pickMedia,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('メディアを追加'),
        ),

        const SizedBox(height: 16),

        // メディアリスト
        if (settings.mediaPaths.isNotEmpty) ...[
          const Text('登録メディア:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ...settings.mediaPaths.asMap().entries.map((entry) {
            final path = entry.value;
            final fileName = path.split('/').last;
            return ListTile(
              leading: _buildMediaThumbnail(path),
              title: Text(fileName, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => settingsProvider.removeMediaPath(path),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildMediaThumbnail(String path) {
    final isVideo = path.toLowerCase().endsWith('.mp4') ||
        path.toLowerCase().endsWith('.mov') ||
        path.toLowerCase().endsWith('.avi') ||
        path.toLowerCase().endsWith('.webm');

    if (isVideo) {
      return const Icon(Icons.video_file, size: 40);
    }

    final file = File(path);
    if (file.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          file,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
        ),
      );
    }

    return const Icon(Icons.image, size: 40);
  }

  Future<void> _pickMedia() async {
    final settingsProvider = context.read<SettingsProvider>();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      allowMultiple: true,
    );

    if (result != null && mounted) {
      for (final file in result.files) {
        if (file.path != null) {
          await settingsProvider.addMediaPath(file.path!);
        }
      }
    }
  }

  /// プレビューセクション（表示確認）
  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '表示確認（プレビュー）',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'レジがなくても表示を確認できます。ボタンを押すとテストコマンドを送信します。',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: () => _sendPreviewCommand(
                '1/小計/1,280円/みかんジェラート/640×2ケ/1,240円',
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('小計 表示確認', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () => _sendPreviewCommand(
                '2/合計/9,120円/割引/200円',
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('合計 表示確認', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () => _sendPreviewCommand(
                '2/合計/58,920円/割引/5,800円',
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('合計(4桁割引)', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () => _sendPreviewCommand(
                '3/お預かり/10,120円/お釣り/1,000円',
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('お預かり 表示確認', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () => _sendPreviewCommand(
                '4/123456789/POS_TEST_001',
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('文字列 表示確認', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () => _sendPreviewCommand('9/表示クリア'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text('表示クリア（スライドへ）', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }

  /// プレビューコマンドを送信（内部処理）
  void _sendPreviewCommand(String command) {
    final displayProvider = context.read<DisplayProvider>();
    displayProvider.processCommand(command);

    // 設定画面を閉じてプレビューを表示
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    Navigator.pop(context);
  }
}

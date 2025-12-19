import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/settings_provider.dart';

/// スライドショーウィジェット（待機中表示）
class SlideshowWidget extends StatefulWidget {
  const SlideshowWidget({super.key});

  @override
  State<SlideshowWidget> createState() => _SlideshowWidgetState();
}

class _SlideshowWidgetState extends State<SlideshowWidget> {
  int _currentIndex = 0;
  Timer? _timer;
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _startSlideshow();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  void _startSlideshow() {
    final settings = context.read<SettingsProvider>().settings;
    final mediaPaths = settings.mediaPaths;

    if (mediaPaths.isEmpty) {
      return;
    }

    _loadCurrentMedia();
  }

  void _loadCurrentMedia() {
    final settings = context.read<SettingsProvider>().settings;
    final mediaPaths = settings.mediaPaths;

    if (mediaPaths.isEmpty) {
      return;
    }

    final path = mediaPaths[_currentIndex % mediaPaths.length];
    final isVideo = _isVideoFile(path);

    if (isVideo) {
      _loadVideo(path);
    } else {
      _loadImage(settings.imageDurationSeconds);
    }
  }

  bool _isVideoFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.webm');
  }

  void _loadImage(int durationSeconds) {
    _isVideoPlaying = false;
    _videoController?.dispose();
    _videoController = null;

    _timer?.cancel();
    _timer = Timer(Duration(seconds: durationSeconds), () {
      _nextSlide();
    });

    if (mounted) {
      setState(() {});
    }
  }

  void _loadVideo(String path) async {
    _timer?.cancel();
    _isVideoPlaying = true;

    // awaitの前にsettingsを取得
    final settings = context.read<SettingsProvider>().settings;

    try {
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(File(path));
      await _videoController!.initialize();

      if (!mounted) return;

      _videoController!.setLooping(false);
      _videoController!.play();

      // 動画終了時に次へ
      _videoController!.addListener(() {
        if (_videoController!.value.position >= _videoController!.value.duration) {
          _nextSlide();
        }
      });

      // 最大秒数でカット
      _timer = Timer(Duration(seconds: settings.videoMaxSeconds), () {
        if (_isVideoPlaying) {
          _nextSlide();
        }
      });

      if (mounted) {
        setState(() {});
      }
    } catch (e, stackTrace) {
      developer.log(
        '動画読み込みエラー',
        error: e,
        stackTrace: stackTrace,
        name: 'SlideshowWidget',
      );
      // エラー時は次のスライドへ
      _nextSlide();
    }
  }

  void _nextSlide() {
    if (!mounted) return;

    final settings = context.read<SettingsProvider>().settings;
    final mediaPaths = settings.mediaPaths;

    if (mediaPaths.isEmpty) {
      return;
    }

    // フェードアウト
    setState(() {
      _opacity = 0.0;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      _currentIndex = (_currentIndex + 1) % mediaPaths.length;
      _loadCurrentMedia();

      // フェードイン
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final mediaPaths = settings.mediaPaths;

    return Container(
      color: Colors.black,
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 300),
        child: mediaPaths.isEmpty
            ? _buildPlaceholder()
            : _buildMedia(mediaPaths[_currentIndex % mediaPaths.length]),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.white30,
          ),
          SizedBox(height: 16),
          Text(
            '設定画面からメディアを追加してください',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedia(String path) {
    if (_isVideoFile(path) && _videoController != null && _videoController!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    // 画像表示
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          developer.log(
            '画像読み込みエラー: $path',
            error: error,
            name: 'SlideshowWidget',
          );
          return _buildErrorWidget();
        },
      );
    }

    return _buildErrorWidget();
  }

  Widget _buildErrorWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 60,
            color: Colors.white30,
          ),
          SizedBox(height: 8),
          Text(
            'メディアを読み込めません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white30,
            ),
          ),
        ],
      ),
    );
  }
}

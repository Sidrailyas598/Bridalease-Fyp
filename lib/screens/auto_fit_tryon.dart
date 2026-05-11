// lib/screens/auto_fit_tryon.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AutoFitTryOn extends StatefulWidget {
  final Map<String, dynamic> dressData;
  final Map<String, dynamic> userMeasurements;
  final String avatarPath;
  final String userId;

  const AutoFitTryOn({
    super.key,
    required this.dressData,
    required this.userMeasurements,
    required this.avatarPath,
    required this.userId,
  });

  @override
  State<AutoFitTryOn> createState() => _AutoFitTryOnState();
}

class _AutoFitTryOnState extends State<AutoFitTryOn> {
  bool _loading = true;
  String? _combinationImagePath;
  String? _combinationVideoPath;
  String? _errorMessage;
  
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _loadCombination();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadCombination() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      String dressName = _getDressFileName(widget.dressData);
      String avatarName = _getAvatarNameFromPath(widget.avatarPath);
      
      String videoPath = 'assets/videos/${avatarName}_${dressName}.mp4';
      String imagePath = 'assets/combinations/${avatarName}_${dressName}.png';
      
      bool videoExists = await _checkAssetExists(videoPath);
      
      if (videoExists) {
        await _copyAndPlayVideo(videoPath);
      } else {
        _combinationImagePath = imagePath;
        setState(() {
          _loading = false;
        });
      }
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load';
        _loading = false;
      });
    }
  }

  Future<bool> _checkAssetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _copyAndPlayVideo(String assetPath) async {
    try {
      ByteData data = await rootBundle.load(assetPath);
      List<int> bytes = data.buffer.asUint8List();
      
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4');
      
      await tempFile.writeAsBytes(bytes);
      
      await _initializeVideoPlayer(tempFile.path);
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not play';
        _loading = false;
      });
    }
  }

  Future<void> _initializeVideoPlayer(String filePath) async {
    _videoController = VideoPlayerController.file(File(filePath));
    
    try {
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.play();
      
      setState(() {
        _isVideoInitialized = true;
        _loading = false;
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not play';
        _loading = false;
      });
    }
  }

  String _getDressFileName(Map<String, dynamic> dress) {
    String name = dress['name'] ?? '';
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
  }

  String _getAvatarNameFromPath(String path) {
    List<String> parts = path.split('/');
    String fileName = parts.last;
    return fileName.replaceAll('.png', '');
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      _transformationController.value = Matrix4.diagonal3Values(2.0, 2.0, 1.0);
    }
  }

  // ✅ Updated Share function
  Future<void> _shareTryOn() async {
    try {
      String text = '''
✨ ${widget.dressData['name'] ?? 'Dress'} - Virtual Try-On on BridalEase!
💰 Price: PKR ${widget.dressData['price'] ?? 0}
📏 Custom fit based on your measurements
👰 Perfect for your bridal look

Try it yourself on BridalEase app!
''';
      
      if (_combinationImagePath != null) {
        ByteData data = await rootBundle.load(_combinationImagePath!);
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(data.buffer.asUint8List());
        await Share.shareXFiles([XFile(tempFile.path)], text: text);
        await tempFile.delete();
      } else {
        await Share.share(text);
      }
      
      _showSnackBar('Shared successfully!', Colors.green, Icons.check_circle);
    } catch (e) {
      _showSnackBar('Could not share', Colors.red, Icons.error_outline);
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.dressData['name'] ?? 'Dress',
          style: const TextStyle(
            color: Color(0xFF660033),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: const Color(0xFF660033)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: const Color(0xFF660033)),
            onPressed: _shareTryOn,
          ),
        ],
      ),
      body: _loading
          ? _buildLoadingWidget()
          : _errorMessage != null
              ? _buildErrorWidget()
              : _isVideoInitialized && _videoController != null
                  ? _buildVideoWidget()
                  : _buildImageWidget(),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF660033).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF660033),
                strokeWidth: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading your virtual try-on...',
            style: TextStyle(
              color: Color(0xFF660033),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoWidget() {
    double videoWidth = _videoController!.value.size.width;
    double videoHeight = _videoController!.value.size.height;
    double aspectRatio = videoWidth / videoHeight;
    
    double containerWidth = MediaQuery.of(context).size.width * 0.9;
    double containerHeight = containerWidth / aspectRatio;
    
    return Column(
      children: [
        Expanded(
          child: Center(
            child: GestureDetector(
              onDoubleTap: _handleDoubleTap,
              child: Container(
                width: containerWidth,
                height: containerHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF660033).withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.8,
                    maxScale: 3.0,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // ✅ Only Share Button - No Add to Cart
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              child: ElevatedButton.icon(
                onPressed: _shareTryOn,
                icon: const Icon(Icons.share, color: Colors.white, size: 22),
                label: const Text(
                  'Share Your Look',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF660033),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF660033).withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 3.0,
                  child: _combinationImagePath != null
                      ? Image.asset(
                          _combinationImagePath!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        
        // ✅ Only Share Button - No Add to Cart
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              child: ElevatedButton.icon(
                onPressed: _shareTryOn,
                icon: const Icon(Icons.share, color: Colors.white, size: 22),
                label: const Text(
                  'Share Your Look',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF660033),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadCombination,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF660033),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
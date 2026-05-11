/// Smart Waste Sorting — Live Scan Screen (Google Lens Style)
/// Kamera live dengan selection rectangle untuk memilih objek spesifik.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/scan_provider.dart';
import 'result_screen.dart';

enum _ScreenState { initializing, preview, captured, analyzing }
enum _DragMode { none, move, topLeft, topRight, bottomLeft, bottomRight }

class LiveScanScreen extends StatefulWidget {
  const LiveScanScreen({super.key});

  @override
  State<LiveScanScreen> createState() => _LiveScanScreenState();
}

class _LiveScanScreenState extends State<LiveScanScreen>
    with WidgetsBindingObserver {
  CameraController? _camCtrl;
  _ScreenState _state = _ScreenState.initializing;
  String? _errorMsg;

  // Captured image
  File? _capturedFile;
  ui.Image? _decodedImage;

  // Selection rect (display coords)
  Rect _selRect = Rect.zero;
  final GlobalKey _imageKey = GlobalKey();
  Size _containerSize = Size.zero;

  // Drag
  _DragMode _dragMode = _DragMode.none;
  Offset _dragStart = Offset.zero;
  Rect _dragStartRect = Rect.zero;

  // Flash
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camCtrl?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _camCtrl?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMsg = 'Tidak ada kamera tersedia.';
          _state = _ScreenState.preview;
        });
        return;
      }
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _camCtrl = CameraController(cam, ResolutionPreset.high,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
      await _camCtrl!.initialize();
      if (!mounted) return;
      setState(() => _state = _ScreenState.preview);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Gagal membuka kamera: $e';
        _state = _ScreenState.preview;
      });
    }
  }

  Future<void> _toggleFlash() async {
    if (_camCtrl == null) return;
    _flashOn = !_flashOn;
    await _camCtrl!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  Future<void> _captureImage() async {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;
    try {
      final xFile = await _camCtrl!.takePicture();
      final file = File(xFile.path);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      // Turn off flash after capture
      if (_flashOn) {
        await _camCtrl!.setFlashMode(FlashMode.off);
        _flashOn = false;
      }

      setState(() {
        _capturedFile = file;
        _decodedImage = frame.image;
        _state = _ScreenState.captured;
      });

      // Set default selection after build
      WidgetsBinding.instance.addPostFrameCallback((_) => _setDefaultRect());
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = 'Gagal mengambil foto: $e');
    }
  }

  void _setDefaultRect() {
    final box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    _containerSize = box.size;
    final cw = _containerSize.width;
    final ch = _containerSize.height;
    final size = math.min(cw, ch) * 0.6;
    setState(() {
      _selRect = Rect.fromCenter(
        center: Offset(cw / 2, ch / 2),
        width: size,
        height: size,
      );
    });
  }

  void _retake() {
    setState(() {
      _capturedFile = null;
      _decodedImage = null;
      _state = _ScreenState.preview;
    });
  }

  // ── Crop & Analyze ──────────────────────────

  Future<void> _analyzeSelection() async {
    if (_capturedFile == null || _decodedImage == null) return;
    setState(() => _state = _ScreenState.analyzing);

    try {
      final cropped = await _cropSelection();
      if (!mounted) return;

      final provider = context.read<ScanProvider>();
      await provider.scanFromFile(cropped);

      if (!mounted) return;
      if (provider.status == ScanStatus.success &&
          provider.currentResult != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ResultScreen()),
        );
      } else {
        setState(() {
          _state = _ScreenState.captured;
          _errorMsg = provider.errorMessage ?? 'Gagal menganalisis.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScreenState.captured;
        _errorMsg = 'Error: $e';
      });
    }
  }

  Future<File> _cropSelection() async {
    final img = _decodedImage!;
    // Calculate fitted image area inside container
    final wR = _containerSize.width / img.width;
    final hR = _containerSize.height / img.height;
    final scale = math.min(wR, hR);
    final fittedW = img.width * scale;
    final fittedH = img.height * scale;
    final offX = (_containerSize.width - fittedW) / 2;
    final offY = (_containerSize.height - fittedH) / 2;

    // Map selection rect to image pixel coords
    final srcL = (((_selRect.left - offX) / fittedW) * img.width).clamp(0.0, img.width.toDouble());
    final srcT = (((_selRect.top - offY) / fittedH) * img.height).clamp(0.0, img.height.toDouble());
    final srcR = (((_selRect.right - offX) / fittedW) * img.width).clamp(0.0, img.width.toDouble());
    final srcB = (((_selRect.bottom - offY) / fittedH) * img.height).clamp(0.0, img.height.toDouble());

    final srcRect = Rect.fromLTRB(srcL, srcT, srcR, srcB);
    final cw = srcRect.width.toInt().clamp(1, img.width);
    final ch = srcRect.height.toInt().clamp(1, img.height);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      img,
      srcRect,
      Rect.fromLTWH(0, 0, cw.toDouble(), ch.toDouble()),
      Paint(),
    );
    final pic = recorder.endRecording();
    final croppedImg = await pic.toImage(cw, ch);
    final byteData = await croppedImg.toByteData(format: ui.ImageByteFormat.png);

    final dir = await getApplicationDocumentsDirectory();
    final scanDir = Directory('${dir.path}/scan_images');
    if (!await scanDir.exists()) await scanDir.create(recursive: true);
    final file = File(
        '${scanDir.path}/crop_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List());
    return file;
  }

  // ── Drag Handling ───────────────────────────

  static const double _handleSize = 24;

  _DragMode _hitTest(Offset pos) {
    bool near(double a, double b) => (a - b).abs() < _handleSize;
    if (near(pos.dx, _selRect.left) && near(pos.dy, _selRect.top)) {
      return _DragMode.topLeft;
    }
    if (near(pos.dx, _selRect.right) && near(pos.dy, _selRect.top)) {
      return _DragMode.topRight;
    }
    if (near(pos.dx, _selRect.left) && near(pos.dy, _selRect.bottom)) {
      return _DragMode.bottomLeft;
    }
    if (near(pos.dx, _selRect.right) && near(pos.dy, _selRect.bottom)) {
      return _DragMode.bottomRight;
    }
    if (_selRect.contains(pos)) return _DragMode.move;
    return _DragMode.none;
  }

  void _onPanStart(DragStartDetails d) {
    _dragMode = _hitTest(d.localPosition);
    _dragStart = d.localPosition;
    _dragStartRect = _selRect;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_dragMode == _DragMode.none) return;
    final delta = d.localPosition - _dragStart;
    const minSz = 60.0;
    Rect r = _dragStartRect;

    switch (_dragMode) {
      case _DragMode.move:
        var dx = delta.dx;
        var dy = delta.dy;
        if (r.left + dx < 0) dx = -r.left;
        if (r.top + dy < 0) dy = -r.top;
        if (r.right + dx > _containerSize.width) dx = _containerSize.width - r.right;
        if (r.bottom + dy > _containerSize.height) dy = _containerSize.height - r.bottom;
        r = r.shift(Offset(dx, dy));
        break;
      case _DragMode.topLeft:
        r = Rect.fromLTRB(
          (r.left + delta.dx).clamp(0, r.right - minSz),
          (r.top + delta.dy).clamp(0, r.bottom - minSz),
          r.right, r.bottom,
        );
        break;
      case _DragMode.topRight:
        r = Rect.fromLTRB(
          r.left,
          (r.top + delta.dy).clamp(0, r.bottom - minSz),
          (r.right + delta.dx).clamp(r.left + minSz, _containerSize.width),
          r.bottom,
        );
        break;
      case _DragMode.bottomLeft:
        r = Rect.fromLTRB(
          (r.left + delta.dx).clamp(0, r.right - minSz),
          r.top,
          r.right,
          (r.bottom + delta.dy).clamp(r.top + minSz, _containerSize.height),
        );
        break;
      case _DragMode.bottomRight:
        r = Rect.fromLTRB(
          r.left, r.top,
          (r.right + delta.dx).clamp(r.left + minSz, _containerSize.width),
          (r.bottom + delta.dy).clamp(r.top + minSz, _containerSize.height),
        );
        break;
      case _DragMode.none:
        break;
    }
    setState(() => _selRect = r);
  }

  void _onPanEnd(DragEndDetails _) => _dragMode = _DragMode.none;

  // ── Build ───────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Main content
          if (_state == _ScreenState.initializing) _buildLoading(),
          if (_state == _ScreenState.preview) _buildPreview(),
          if (_state == _ScreenState.captured ||
              _state == _ScreenState.analyzing)
            _buildCaptured(),

          // Top bar
          _buildTopBar(),

          // Bottom controls
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _buildBottomControls(),
          ),

          // Error snackbar
          if (_errorMsg != null) _buildError(),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryGreen),
          SizedBox(height: 16),
          Text('Memuat kamera...', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) {
      return Center(
        child: Text(
          _errorMsg ?? 'Kamera tidak tersedia',
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }
    return Center(
      child: CameraPreview(_camCtrl!),
    );
  }

  Widget _buildCaptured() {
    return GestureDetector(
      onPanStart: _state == _ScreenState.captured ? _onPanStart : null,
      onPanUpdate: _state == _ScreenState.captured ? _onPanUpdate : null,
      onPanEnd: _state == _ScreenState.captured ? _onPanEnd : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          Container(
            key: _imageKey,
            child: Image.file(_capturedFile!, fit: BoxFit.contain),
          ),
          // Selection overlay
          if (_selRect != Rect.zero)
            CustomPaint(
              painter: _SelectionPainter(
                selRect: _selRect,
                isAnalyzing: _state == _ScreenState.analyzing,
              ),
            ),
          // Analyzing overlay
          if (_state == _ScreenState.analyzing) _buildAnalyzingOverlay(),
        ],
      ),
    );
  }

  Widget _buildAnalyzingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(48),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56, height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primaryGreen),
                  backgroundColor: AppTheme.textTertiary.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Menganalisis area...',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AI sedang mengidentifikasi jenis sampah',
                style: TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8, right: 8, bottom: 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 22),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const Spacer(),
            if (_state == _ScreenState.preview && _camCtrl != null)
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _flashOn ? AppTheme.primaryGreen.withValues(alpha: 0.3) : Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: _flashOn ? AppTheme.primaryGreen : Colors.white,
                    size: 22,
                  ),
                ),
                onPressed: _toggleFlash,
              ),
            if (_state == _ScreenState.captured)
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 22),
                ),
                onPressed: _retake,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 24, right: 24, top: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: _state == _ScreenState.preview
          ? _buildCaptureButton()
          : _state == _ScreenState.captured
              ? _buildAnalyzeButton()
              : const SizedBox.shrink(),
    );
  }

  Widget _buildCaptureButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Arahkan kamera ke sampah',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _captureImage,
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Seret kotak ke objek yang ingin dideteksi',
          style: TextStyle(color: Colors.white70, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _retake,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Ulang'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _analyzeSelection,
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: const Text(
                  'Analisis Area Ini',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: AppTheme.scaffoldDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 64,
      left: 16, right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.error.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_errorMsg!,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
              GestureDetector(
                onTap: () => setState(() => _errorMsg = null),
                child: const Icon(Icons.close, color: Colors.white70, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Selection Rectangle Painter
// ═══════════════════════════════════════════════

class _SelectionPainter extends CustomPainter {
  final Rect selRect;
  final bool isAnalyzing;

  _SelectionPainter({required this.selRect, this.isAnalyzing = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark overlay outside selection
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: isAnalyzing ? 0.7 : 0.5);
    // Top
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, selRect.top), overlayPaint);
    // Bottom
    canvas.drawRect(
        Rect.fromLTRB(0, selRect.bottom, size.width, size.height), overlayPaint);
    // Left
    canvas.drawRect(
        Rect.fromLTRB(0, selRect.top, selRect.left, selRect.bottom), overlayPaint);
    // Right
    canvas.drawRect(Rect.fromLTRB(
        selRect.right, selRect.top, size.width, selRect.bottom), overlayPaint);

    // Selection border
    final borderPaint = Paint()
      ..color = isAnalyzing
          ? const Color(0xFF00E676)
          : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(selRect, borderPaint);

    if (isAnalyzing) return;

    // Corner handles
    const hl = 20.0; // handle length
    const hw = 3.5;  // handle width
    final hPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.stroke
      ..strokeWidth = hw
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(selRect.topLeft, selRect.topLeft + const Offset(hl, 0), hPaint);
    canvas.drawLine(selRect.topLeft, selRect.topLeft + const Offset(0, hl), hPaint);
    // Top-right
    canvas.drawLine(selRect.topRight, selRect.topRight + const Offset(-hl, 0), hPaint);
    canvas.drawLine(selRect.topRight, selRect.topRight + const Offset(0, hl), hPaint);
    // Bottom-left
    canvas.drawLine(selRect.bottomLeft, selRect.bottomLeft + const Offset(hl, 0), hPaint);
    canvas.drawLine(selRect.bottomLeft, selRect.bottomLeft + const Offset(0, -hl), hPaint);
    // Bottom-right
    canvas.drawLine(selRect.bottomRight, selRect.bottomRight + const Offset(-hl, 0), hPaint);
    canvas.drawLine(selRect.bottomRight, selRect.bottomRight + const Offset(0, -hl), hPaint);

    // Center crosshair
    final cx = selRect.center.dx;
    final cy = selRect.center.dy;
    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(cx - 12, cy), Offset(cx + 12, cy), crossPaint);
    canvas.drawLine(Offset(cx, cy - 12), Offset(cx, cy + 12), crossPaint);
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter old) =>
      old.selRect != selRect || old.isAnalyzing != isAnalyzing;
}

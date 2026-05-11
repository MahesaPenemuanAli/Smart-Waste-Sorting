/// Smart Waste Sorting — Live Scan Screen (Google Lens Style)
/// Kamera live dengan MULTI selection boxes untuk memilih objek spesifik.
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

  File? _capturedFile;
  ui.Image? _decodedImage;

  // Multi-box selection
  final List<Rect> _boxes = [];
  int _activeIdx = 0;
  final GlobalKey _imageKey = GlobalKey();
  Size _containerSize = Size.zero;

  // Drag state
  _DragMode _dragMode = _DragMode.none;
  Offset _dragStart = Offset.zero;
  Rect _dragStartRect = Rect.zero;

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
        setState(() { _errorMsg = 'Tidak ada kamera tersedia.'; _state = _ScreenState.preview; });
        return;
      }
      final cam = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);
      _camCtrl = CameraController(cam, ResolutionPreset.high, enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
      await _camCtrl!.initialize();
      if (!mounted) return;
      setState(() => _state = _ScreenState.preview);
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorMsg = 'Gagal membuka kamera: $e'; _state = _ScreenState.preview; });
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
      if (_flashOn) { await _camCtrl!.setFlashMode(FlashMode.off); _flashOn = false; }
      setState(() { _capturedFile = file; _decodedImage = frame.image; _state = _ScreenState.captured; _boxes.clear(); });
      WidgetsBinding.instance.addPostFrameCallback((_) => _addFirstBox());
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = 'Gagal mengambil foto: $e');
    }
  }

  void _addFirstBox() {
    final box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    _containerSize = box.size;
    final sz = math.min(_containerSize.width, _containerSize.height) * 0.5;
    setState(() {
      _boxes.add(Rect.fromCenter(center: Offset(_containerSize.width / 2, _containerSize.height / 2), width: sz, height: sz));
      _activeIdx = 0;
    });
  }

  void _addBox() {
    if (_boxes.length >= 10) return; // max 10 boxes
    final sz = math.min(_containerSize.width, _containerSize.height) * 0.3;
    // Offset each new box slightly
    final offset = (_boxes.length * 30.0) % (_containerSize.width * 0.3);
    final cx = (_containerSize.width * 0.3 + offset).clamp(sz / 2, _containerSize.width - sz / 2);
    final cy = (_containerSize.height * 0.3 + offset).clamp(sz / 2, _containerSize.height - sz / 2);
    setState(() {
      _boxes.add(Rect.fromCenter(center: Offset(cx, cy), width: sz, height: sz));
      _activeIdx = _boxes.length - 1;
    });
  }

  void _removeActiveBox() {
    if (_boxes.length <= 1) return; // keep at least 1
    setState(() {
      _boxes.removeAt(_activeIdx);
      _activeIdx = _activeIdx.clamp(0, _boxes.length - 1);
    });
  }

  void _retake() {
    setState(() { _capturedFile = null; _decodedImage = null; _boxes.clear(); _state = _ScreenState.preview; });
  }

  // ── Crop & Analyze ──────────────────────────

  Future<void> _analyzeActiveBox() async {
    if (_capturedFile == null || _decodedImage == null || _boxes.isEmpty) return;
    setState(() => _state = _ScreenState.analyzing);
    try {
      final cropped = await _cropRect(_boxes[_activeIdx]);
      if (!mounted) return;
      final provider = context.read<ScanProvider>();
      await provider.scanFromFile(cropped);
      if (!mounted) return;
      if (provider.status == ScanStatus.success && provider.currentResult != null) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ResultScreen()));
      } else {
        setState(() { _state = _ScreenState.captured; _errorMsg = provider.errorMessage ?? 'Gagal menganalisis.'; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _state = _ScreenState.captured; _errorMsg = 'Error: $e'; });
    }
  }

  Future<File> _cropRect(Rect selRect) async {
    final img = _decodedImage!;
    final wR = _containerSize.width / img.width;
    final hR = _containerSize.height / img.height;
    final scale = math.min(wR, hR);
    final fittedW = img.width * scale, fittedH = img.height * scale;
    final offX = (_containerSize.width - fittedW) / 2, offY = (_containerSize.height - fittedH) / 2;

    final srcL = (((selRect.left - offX) / fittedW) * img.width).clamp(0.0, img.width.toDouble());
    final srcT = (((selRect.top - offY) / fittedH) * img.height).clamp(0.0, img.height.toDouble());
    final srcR = (((selRect.right - offX) / fittedW) * img.width).clamp(0.0, img.width.toDouble());
    final srcB = (((selRect.bottom - offY) / fittedH) * img.height).clamp(0.0, img.height.toDouble());

    final srcRect = Rect.fromLTRB(srcL, srcT, srcR, srcB);
    final cw = srcRect.width.toInt().clamp(1, img.width);
    final ch = srcRect.height.toInt().clamp(1, img.height);

    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(img, srcRect, Rect.fromLTWH(0, 0, cw.toDouble(), ch.toDouble()), Paint());
    final croppedImg = await recorder.endRecording().toImage(cw, ch);
    final byteData = await croppedImg.toByteData(format: ui.ImageByteFormat.png);

    final dir = await getApplicationDocumentsDirectory();
    final scanDir = Directory('${dir.path}/scan_images');
    if (!await scanDir.exists()) await scanDir.create(recursive: true);
    final file = File('${scanDir.path}/crop_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List());
    return file;
  }

  // ── Drag Handling ───────────────────────────

  static const double _hs = 24;

  _DragMode _hitTestBox(Offset pos, Rect r) {
    bool near(double a, double b) => (a - b).abs() < _hs;
    if (near(pos.dx, r.left) && near(pos.dy, r.top)) return _DragMode.topLeft;
    if (near(pos.dx, r.right) && near(pos.dy, r.top)) return _DragMode.topRight;
    if (near(pos.dx, r.left) && near(pos.dy, r.bottom)) return _DragMode.bottomLeft;
    if (near(pos.dx, r.right) && near(pos.dy, r.bottom)) return _DragMode.bottomRight;
    if (r.contains(pos)) return _DragMode.move;
    return _DragMode.none;
  }

  void _onPanStart(DragStartDetails d) {
    final pos = d.localPosition;
    // First check active box
    final activeMode = _hitTestBox(pos, _boxes[_activeIdx]);
    if (activeMode != _DragMode.none) {
      _dragMode = activeMode;
      _dragStart = pos;
      _dragStartRect = _boxes[_activeIdx];
      return;
    }
    // Then check other boxes (tap to select)
    for (int i = 0; i < _boxes.length; i++) {
      if (i == _activeIdx) continue;
      if (_boxes[i].contains(pos)) {
        setState(() => _activeIdx = i);
        _dragMode = _DragMode.move;
        _dragStart = pos;
        _dragStartRect = _boxes[i];
        return;
      }
    }
    _dragMode = _DragMode.none;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_dragMode == _DragMode.none || _boxes.isEmpty) return;
    final delta = d.localPosition - _dragStart;
    const minSz = 50.0;
    Rect r = _dragStartRect;
    final mw = _containerSize.width, mh = _containerSize.height;

    switch (_dragMode) {
      case _DragMode.move:
        var dx = delta.dx, dy = delta.dy;
        if (r.left + dx < 0) dx = -r.left;
        if (r.top + dy < 0) dy = -r.top;
        if (r.right + dx > mw) dx = mw - r.right;
        if (r.bottom + dy > mh) dy = mh - r.bottom;
        r = r.shift(Offset(dx, dy));
        break;
      case _DragMode.topLeft:
        r = Rect.fromLTRB((r.left + delta.dx).clamp(0, r.right - minSz), (r.top + delta.dy).clamp(0, r.bottom - minSz), r.right, r.bottom);
        break;
      case _DragMode.topRight:
        r = Rect.fromLTRB(r.left, (r.top + delta.dy).clamp(0, r.bottom - minSz), (r.right + delta.dx).clamp(r.left + minSz, mw), r.bottom);
        break;
      case _DragMode.bottomLeft:
        r = Rect.fromLTRB((r.left + delta.dx).clamp(0, r.right - minSz), r.top, r.right, (r.bottom + delta.dy).clamp(r.top + minSz, mh));
        break;
      case _DragMode.bottomRight:
        r = Rect.fromLTRB(r.left, r.top, (r.right + delta.dx).clamp(r.left + minSz, mw), (r.bottom + delta.dy).clamp(r.top + minSz, mh));
        break;
      case _DragMode.none:
        break;
    }
    setState(() => _boxes[_activeIdx] = r);
  }

  void _onPanEnd(DragEndDetails _) => _dragMode = _DragMode.none;

  // ── Build ───────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        if (_state == _ScreenState.initializing) _buildLoading(),
        if (_state == _ScreenState.preview) _buildPreview(),
        if (_state == _ScreenState.captured || _state == _ScreenState.analyzing) _buildCaptured(),
        _buildTopBar(),
        Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomControls()),
        if (_errorMsg != null) _buildError(),
      ]),
    );
  }

  Widget _buildLoading() => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircularProgressIndicator(color: AppTheme.primaryGreen),
      SizedBox(height: 16),
      Text('Memuat kamera...', style: TextStyle(color: Colors.white70)),
    ]),
  );

  Widget _buildPreview() {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) {
      return Center(child: Text(_errorMsg ?? 'Kamera tidak tersedia', style: const TextStyle(color: Colors.white70)));
    }
    return Center(child: CameraPreview(_camCtrl!));
  }

  Widget _buildCaptured() {
    return GestureDetector(
      onPanStart: _state == _ScreenState.captured ? _onPanStart : null,
      onPanUpdate: _state == _ScreenState.captured ? _onPanUpdate : null,
      onPanEnd: _state == _ScreenState.captured ? _onPanEnd : null,
      child: Stack(fit: StackFit.expand, children: [
        Container(key: _imageKey, child: Image.file(_capturedFile!, fit: BoxFit.contain)),
        if (_boxes.isNotEmpty)
          CustomPaint(painter: _MultiBoxPainter(
            boxes: _boxes,
            activeIdx: _activeIdx,
            isAnalyzing: _state == _ScreenState.analyzing,
          )),
        if (_state == _ScreenState.analyzing) _buildAnalyzingOverlay(),
      ]),
    );
  }

  Widget _buildAnalyzingOverlay() => Container(
    color: Colors.black54,
    child: Center(child: Container(
      margin: const EdgeInsets.all(48), padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 56, height: 56, child: CircularProgressIndicator(
          strokeWidth: 3, valueColor: const AlwaysStoppedAnimation(AppTheme.primaryGreen),
          backgroundColor: AppTheme.textTertiary.withValues(alpha: 0.15),
        )),
        const SizedBox(height: 20),
        Text('Menganalisis Kotak ${_activeIdx + 1}...', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('AI sedang mengidentifikasi jenis sampah', style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
      ]),
    )),
  );

  Widget _buildTopBar() {
    return Positioned(top: 0, left: 0, right: 0, child: Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 8, right: 8, bottom: 12),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent])),
      child: Row(children: [
        IconButton(icon: _circleBtn(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
        const Spacer(),
        // Box counter badge
        if (_state == _ScreenState.captured && _boxes.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
            child: Text('Kotak ${_activeIdx + 1}/${_boxes.length}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        const Spacer(),
        if (_state == _ScreenState.preview && _camCtrl != null)
          IconButton(icon: _circleBtn(_flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded, active: _flashOn), onPressed: _toggleFlash),
        if (_state == _ScreenState.captured) ...[
          if (_boxes.length > 1)
            IconButton(icon: _circleBtn(Icons.delete_outline_rounded, color: AppTheme.error), onPressed: _removeActiveBox),
          IconButton(icon: _circleBtn(Icons.refresh_rounded), onPressed: _retake),
        ],
      ]),
    ));
  }

  Widget _circleBtn(IconData icon, {bool active = false, Color? color}) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: active ? AppTheme.primaryGreen.withValues(alpha: 0.3) : Colors.black38, shape: BoxShape.circle),
    child: Icon(icon, color: color ?? (active ? AppTheme.primaryGreen : Colors.white), size: 22),
  );

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16, left: 24, right: 24, top: 16),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent])),
      child: _state == _ScreenState.preview ? _buildCaptureButton()
           : _state == _ScreenState.captured ? _buildAnalyzeButtons()
           : const SizedBox.shrink(),
    );
  }

  Widget _buildCaptureButton() => Column(mainAxisSize: MainAxisSize.min, children: [
    const Text('Arahkan kamera ke sampah', style: TextStyle(color: Colors.white70, fontSize: 14)),
    const SizedBox(height: 16),
    GestureDetector(
      onTap: _captureImage,
      child: Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
        child: Container(margin: const EdgeInsets.all(4), decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
      ),
    ),
  ]);

  Widget _buildAnalyzeButtons() => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(
      _boxes.length == 1
        ? 'Seret kotak ke objek · Tap + untuk tambah kotak'
        : 'Tap kotak untuk pilih · ${_boxes.length} area dipilih',
      style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center,
    ),
    const SizedBox(height: 12),
    Row(children: [
      // Retake
      OutlinedButton.icon(
        onPressed: _retake,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Ulang'),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
      const SizedBox(width: 8),
      // Add box
      Container(
        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
        child: IconButton(
          onPressed: _boxes.length < 10 ? _addBox : null,
          icon: Icon(Icons.add_rounded, color: _boxes.length < 10 ? AppTheme.primaryGreen : Colors.white24, size: 24),
          tooltip: 'Tambah Kotak',
        ),
      ),
      const SizedBox(width: 8),
      // Analyze
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _analyzeActiveBox,
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: Text('Analisis Kotak ${_activeIdx + 1}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: AppTheme.scaffoldDark, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ),
    ]),
  ]);

  Widget _buildError() => Positioned(
    top: MediaQuery.of(context).padding.top + 64, left: 16, right: 16,
    child: Material(color: Colors.transparent, child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(_errorMsg!, style: const TextStyle(color: Colors.white, fontSize: 13))),
        GestureDetector(onTap: () => setState(() => _errorMsg = null), child: const Icon(Icons.close, color: Colors.white70, size: 18)),
      ]),
    )),
  );
}

// ═══════════════════════════════════════════════
// Multi-Box Selection Painter
// ═══════════════════════════════════════════════

class _MultiBoxPainter extends CustomPainter {
  final List<Rect> boxes;
  final int activeIdx;
  final bool isAnalyzing;

  _MultiBoxPainter({required this.boxes, required this.activeIdx, this.isAnalyzing = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent overlay
    final oPaint = Paint()..color = Colors.black.withValues(alpha: 0.35);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), oPaint);

    // Clear each box area (punch through overlay)
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), oPaint);
    for (final box in boxes) {
      canvas.drawRect(box, clearPaint);
    }
    canvas.restore();

    // Draw each box
    for (int i = 0; i < boxes.length; i++) {
      final r = boxes[i];
      final isActive = i == activeIdx;
      final color = isActive ? const Color(0xFF00E676) : Colors.white.withValues(alpha: 0.6);

      // Border
      final bPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = isActive ? 2.5 : 1.5;
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), bPaint);

      // Corner handles (active only)
      if (isActive && !isAnalyzing) {
        const hl = 20.0;
        final hPaint = Paint()..color = const Color(0xFF00E676)..style = PaintingStyle.stroke..strokeWidth = 3.5..strokeCap = StrokeCap.round;
        canvas.drawLine(r.topLeft, r.topLeft + const Offset(hl, 0), hPaint);
        canvas.drawLine(r.topLeft, r.topLeft + const Offset(0, hl), hPaint);
        canvas.drawLine(r.topRight, r.topRight + const Offset(-hl, 0), hPaint);
        canvas.drawLine(r.topRight, r.topRight + const Offset(0, hl), hPaint);
        canvas.drawLine(r.bottomLeft, r.bottomLeft + const Offset(hl, 0), hPaint);
        canvas.drawLine(r.bottomLeft, r.bottomLeft + const Offset(0, -hl), hPaint);
        canvas.drawLine(r.bottomRight, r.bottomRight + const Offset(-hl, 0), hPaint);
        canvas.drawLine(r.bottomRight, r.bottomRight + const Offset(0, -hl), hPaint);
      }

      // Number label
      final textPainter = TextPainter(
        text: TextSpan(text: '${i + 1}', style: TextStyle(color: isActive ? Colors.black : Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelW = textPainter.width + 12;
      final labelH = textPainter.height + 6;
      final labelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left + 4, r.top + 4, labelW, labelH),
        const Radius.circular(6),
      );
      canvas.drawRRect(labelRect, Paint()..color = isActive ? const Color(0xFF00E676) : Colors.black54);
      textPainter.paint(canvas, Offset(r.left + 10, r.top + 7));
    }
  }

  @override
  bool shouldRepaint(covariant _MultiBoxPainter old) => true;
}

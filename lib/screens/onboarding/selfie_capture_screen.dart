import 'dart:async';
import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../models/selfie_guide.dart';
import '../../theme/app_colors.dart';

/// Guided verification selfie: front camera, an oval to fit your face in,
/// live coaching (closer / back / center / more light), then a slow head
/// turn each way. Records the whole clip and returns it as `video:<path>`
/// (null if cancelled). Face detection runs on the phone (ML Kit); on the
/// web, where it isn't available, the same steps run on a gentle timer.
class SelfieCaptureScreen extends StatefulWidget {
  const SelfieCaptureScreen({super.key});

  @override
  State<SelfieCaptureScreen> createState() => _SelfieCaptureScreenState();
}

class _SelfieCaptureScreenState extends State<SelfieCaptureScreen> {
  CameraController? _cam;
  FaceDetector? _detector;
  final _session = SelfieSession();
  FaceReading? _last;
  String? _error;
  bool _busy = false;
  bool _finishing = false;
  Timer? _webSteps;
  final _started = DateTime.now();

  bool get _canDetect => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final cams = await availableCameras();
      final front = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cams.first);
      final cam = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );
      await cam.initialize();
      if (!mounted) {
        await cam.dispose();
        return;
      }
      _cam = cam;
      if (_canDetect) {
        _detector = FaceDetector(options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast));
        await cam.startVideoRecording(onAvailable: _onFrame);
      } else {
        await cam.startVideoRecording();
        // No on-device detection here: walk the same steps on a timer.
        _webSteps = Timer.periodic(const Duration(milliseconds: 2500), (_) {
          final s = _session.step;
          final fake = FaceReading(
            box: const Rect.fromLTWH(0.275, 0.2, 0.45, 0.6),
            yaw: s == SelfieStep.left ? 25 : (s == SelfieStep.right ? -25 : 0),
          );
          setState(() => _session.feed(fake));
          if (_session.step == SelfieStep.done) _finish();
        });
      }
      setState(() {});
    } catch (e) {
      setState(() => _error = 'We couldn’t open your camera. Allow camera access in your phone settings, then try again.');
    }
  }

  Future<void> _onFrame(CameraImage img) async {
    if (_busy || _finishing || _detector == null) return;
    _busy = true;
    try {
      final input = _toInput(img);
      if (input == null) return;
      final faces = await _detector!.processImage(input);
      final reading = faces.isEmpty ? null : _read(faces.first, img);
      if (!mounted) return;
      setState(() {
        _last = faces.length > 1 ? null : reading; // one face only
        _session.feed(_last);
      });
      if (_session.step == SelfieStep.done) _finish();
    } catch (_) {
      // a dropped frame is fine; the next one arrives in ~100 ms
    } finally {
      _busy = false;
    }
  }

  InputImage? _toInput(CameraImage img) {
    final rotation = InputImageRotationValue.fromRawValue(_cam!.description.sensorOrientation);
    final format = InputImageFormatValue.fromRawValue(img.format.raw);
    if (rotation == null || format == null || img.planes.length != 1) return null;
    return InputImage.fromBytes(
      bytes: img.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(img.width.toDouble(), img.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: img.planes.first.bytesPerRow,
      ),
    );
  }

  FaceReading _read(Face f, CameraImage img) {
    // The detector reports in the upright image, so 90/270 swap width and height.
    final sideways = _cam!.description.sensorOrientation % 180 != 0;
    final w = (sideways ? img.height : img.width).toDouble();
    final h = (sideways ? img.width : img.height).toDouble();
    final b = f.boundingBox;
    return FaceReading(
      box: Rect.fromLTWH(b.left / w, b.top / h, b.width / w, b.height / h),
      yaw: f.headEulerAngleY ?? 0,
      light: _brightness(img),
    );
  }

  /// Rough scene brightness 0..1 from a sample of pixels.
  double _brightness(CameraImage img) {
    final bytes = img.planes.first.bytes;
    final bgra = img.format.group == ImageFormatGroup.bgra8888;
    var sum = 0, n = 0;
    for (var i = 0; i < bytes.length; i += 397) {
      if (bgra && i % 4 == 3) continue; // skip alpha
      sum += bytes[i];
      n++;
    }
    return n == 0 ? 1 : sum / n / 255;
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    _webSteps?.cancel();
    final file = await _cam?.stopVideoRecording();
    if (mounted) Navigator.of(context).pop(file == null ? null : 'video:${file.path}');
  }

  @override
  void dispose() {
    _webSteps?.cancel();
    _detector?.close();
    _cam?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cam = _cam;
    final g = guide(_canDetect ? _last : const FaceReading(box: Rect.fromLTWH(0.275, 0.2, 0.45, 0.6), yaw: 0), _session.step);
    final struggling = DateTime.now().difference(_started).inSeconds > 25 && _session.step == SelfieStep.center;
    final stepIndex = _session.step.index; // 0..3
    return Scaffold(
      backgroundColor: AppColors.midnight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Your selfie'),
        leading: IconButton(icon: const Icon(Icons.close), tooltip: 'Cancel', onPressed: () => Navigator.pop(context)),
      ),
      body: _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
          : cam == null || !cam.value.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Stack(fit: StackFit.expand, children: [
                  Center(child: CameraPreview(cam)),
                  CustomPaint(painter: _OvalMask(color: g.ok ? const Color(0xFF34C759) : AppColors.warmIvory)),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 48,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        for (var i = 0; i < 3; i++)
                          Container(
                            margin: const EdgeInsets.all(4),
                            width: 36,
                            height: 5,
                            decoration: BoxDecoration(
                              color: i < stepIndex ? AppColors.emberCrimson : AppColors.warmIvory.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ]),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(18)),
                        child: Text(g.text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.warmIvory, fontSize: 18, fontWeight: FontWeight.w600)),
                      ),
                      if (struggling)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text('Tip: face a window or lamp, hold the phone at eye level, and remove sunglasses or a mask.',
                              textAlign: TextAlign.center, style: TextStyle(color: AppColors.softRose)),
                        ),
                    ]),
                  ),
                ]),
    );
  }
}

/// Darkens everything outside a face-shaped oval; the outline turns green
/// when the face is framed well.
class _OvalMask extends CustomPainter {
  _OvalMask({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final oval = Rect.fromCenter(center: size.center(Offset.zero), width: size.width * 0.68, height: size.width * 0.9);
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addOval(oval)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.55));
    canvas.drawOval(oval, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4);
  }

  @override
  bool shouldRepaint(_OvalMask old) => old.color != color;
}

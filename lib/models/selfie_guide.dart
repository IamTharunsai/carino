import 'dart:ui';

/// Guided selfie for verification: keep the face framed, well lit, then a
/// slow head turn left and right (proves a live 3D face, not a photo).
/// Pure rules — the camera screen feeds in what face detection sees.
enum SelfieStep { center, left, right, done }

/// [box] is the face in 0..1 frame coordinates (as the person sees it,
/// mirrored); [yaw] degrees (+ = turned to their left); [light] 0..1.
class FaceReading {
  const FaceReading({required this.box, required this.yaw, this.light = 1});
  final Rect box;
  final double yaw;
  final double light;
}

typedef Guide = ({String text, bool ok});

Guide _framing(FaceReading? f) {
  if (f == null) return (text: 'Put your face inside the oval', ok: false);
  if (f.light < 0.25) return (text: 'Find a little more light 💡', ok: false);
  if (f.box.width < 0.3) return (text: 'Move a little closer', ok: false);
  if (f.box.width > 0.75) return (text: 'Move back a little', ok: false);
  final c = f.box.center;
  if ((c.dx - 0.5).abs() > 0.12 || (c.dy - 0.5).abs() > 0.15) {
    return (text: 'Center your face in the oval', ok: false);
  }
  return (text: 'Perfect — hold still', ok: true);
}

Guide guide(FaceReading? f, SelfieStep step) {
  final frame = _framing(f);
  if (!frame.ok) return frame;
  return switch (step) {
    SelfieStep.center => frame,
    SelfieStep.left => (text: 'Slowly turn your head to one side ↔️', ok: true),
    SelfieStep.right => (text: 'Now slowly to the other side', ok: true),
    SelfieStep.done => (text: 'All done — you look great ✨', ok: true),
  };
}

const turnDegrees = 18.0;

/// One capture session. The first turn may go either way (front cameras
/// mirror differently on each phone); the second must go the other way.
class SelfieSession {
  SelfieStep step = SelfieStep.center;
  int _firstTurn = 0; // -1 or +1

  void feed(FaceReading? f) {
    if (f == null) return;
    final side = f.yaw >= turnDegrees ? 1 : (f.yaw <= -turnDegrees ? -1 : 0);
    switch (step) {
      case SelfieStep.center:
        // Turning moves the face box, so only the straight-on step needs framing.
        if (_framing(f).ok) step = SelfieStep.left;
      case SelfieStep.left:
        if (side != 0) {
          _firstTurn = side;
          step = SelfieStep.right;
        }
      case SelfieStep.right:
        if (side == -_firstTurn) step = SelfieStep.done;
      case SelfieStep.done:
        break;
    }
  }
}

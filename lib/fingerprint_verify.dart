import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════
// PALETTE — HITAM + PUTIH GLOW
// ═══════════════════════════════════════════════════════════════════
class _FPC {
  static const bg            = Color(0xFF000000);
  static const surface       = Color(0xFF121212);
  static const card          = Color(0xFF1A1A1A);
  static const cardAlt       = Color(0xFF222222);

  static const border        = Color(0xFFFFFFFF);
  static const borderLit     = Color(0xFFE0E0E0);
  static const primary       = Color(0xFFFFFFFF);
  static const primaryMid    = Color(0xFFE0E0E0);
  static const primaryLight  = Color(0xFFFFFFFF);
  static const accent        = Color(0xFFFFFFFF);

  static const text          = Color(0xFFFFFFFF);
  static const textSub       = Color(0xFFB0B0B0);
  static const textDim       = Color(0xFF808080);

  static const luxeGrad = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const softGrad = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF0A0A0A), Color(0xFF000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const textGrad = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ═══════════════════════════════════════════════════════════════════
// HALAMAN VERIFIKASI SIDIK JARI
// ═══════════════════════════════════════════════════════════════════
class FingerprintVerifyPage extends StatefulWidget {
  final VoidCallback onVerified;
  final VoidCallback? onCancel;
  final Duration duration;
  final String title;
  final String subtitle;

  const FingerprintVerifyPage({
    super.key,
    required this.onVerified,
    this.onCancel,
    this.duration = const Duration(milliseconds: 1800),
    this.title = 'VERIFIKASI SIDIK JARI',
    this.subtitle = 'Tekan & tahan sampai 100%',
  });

  @override
  State<FingerprintVerifyPage> createState() => _FingerprintVerifyPageState();
}

class _FingerprintVerifyPageState extends State<FingerprintVerifyPage>
    with TickerProviderStateMixin {
  double _progress = 0.0;
  bool _pressing = false;
  bool _verified = false;
  Timer? _timer;
  DateTime? _pressStartTime;
  int _lastPercent = 0;

  late AnimationController _glowController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startPress() {
    if (_verified || _pressing) return;

    HapticFeedback.mediumImpact();

    _pressStartTime = DateTime.now();

    setState(() {
      _pressing = true;
      _progress = 0.0;
      _lastPercent = 0;
    });

    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }

    _timer?.cancel();

    _timer = Timer.periodic(const Duration(milliseconds: 16), (t) {
      if (!mounted || !_pressing || _verified) {
        t.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(_pressStartTime!);
      final totalMs = widget.duration.inMilliseconds;
      final newProgress = (elapsed.inMilliseconds / totalMs).clamp(0.0, 1.0);

      final currentPercent = (newProgress * 100).toInt();
      if (currentPercent ~/ 10 > _lastPercent ~/ 10) {
        HapticFeedback.selectionClick();
      }
      _lastPercent = currentPercent;

      setState(() {
        _progress = newProgress;
      });

      if (newProgress >= 1.0) {
        t.cancel();
        _onComplete();
      }
    });
  }

  void _endPress() {
    if (_verified) return;

    _timer?.cancel();
    _pressStartTime = null;

    if (_progress >= 1.0) {
      return;
    }

    if (_progress > 0.0) {
      HapticFeedback.lightImpact();
      _animateReset();
    }

    if (mounted) {
      setState(() => _pressing = false);
    }
    _pulseController.stop();
    _pulseController.reset();
  }

  void _animateReset() {
    final start = _progress;
    const resetDurationMs = 200;
    final startTime = DateTime.now();

    Timer.periodic(const Duration(milliseconds: 16), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final factor = (1.0 - (elapsed / resetDurationMs)).clamp(0.0, 1.0);
      setState(() {
        _progress = start * factor;
      });
      if (elapsed >= resetDurationMs) {
        t.cancel();
        if (mounted) setState(() => _progress = 0.0);
      }
    });
  }

  void _onComplete() {
    if (_verified) return;

    _verified = true;
    _pressing = false;
    HapticFeedback.heavyImpact();
    _pulseController.stop();

    setState(() {
      _progress = 1.0;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) widget.onVerified();
    });
  }

  void _cancel() {
    _timer?.cancel();
    _pulseController.stop();
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const size = 240.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: _FPC.bg,
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(gradient: _FPC.softGrad),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _FpGridPainter()),
            ),

            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _cancel,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _FPC.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _FPC.border, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: _FPC.primary.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: _FPC.primary,
                              size: 20,
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),

                  const Spacer(),

                  AnimatedBuilder(
                    animation: _rotateController,
                    builder: (context, _) {
                      return ShaderMask(
                        shaderCallback: (b) => LinearGradient(
                          begin: Alignment(
                              -1.0 + _rotateController.value * 2, 0.0),
                          end: Alignment(
                              1.0 + _rotateController.value * 2, 0.0),
                          colors: const [
                            Color(0xFF808080),
                            Color(0xFFFFFFFF),
                            Color(0xFFFFFFFF),
                            Color(0xFFFFFFFF),
                            Color(0xFF808080),
                          ],
                          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                        ).createShader(b),
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Orbitron',
                            letterSpacing: 3,
                            shadows: [
                              Shadow(
                                color: Colors.white,
                                blurRadius: 15,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      color: _FPC.textSub,
                      fontSize: 13,
                      fontFamily: 'Aktura',
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 60),

                  Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) => _startPress(),
                    onPointerUp: (_) => _endPress(),
                    onPointerCancel: (_) => _endPress(),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _glowController,
                        _rotateController,
                        _pulseController,
                      ]),
                      builder: (context, _) {
                        final glow = _glowController.value;
                        final rotate = _rotateController.value;
                        final pulse = _pressing
                            ? (0.9 + _pulseController.value * 0.15)
                            : 1.0;

                        return Transform.scale(
                          scale: pulse,
                          child: SizedBox(
                            width: size,
                            height: size,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: size,
                                  height: size,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _FPC.primary.withOpacity(
                                          0.25 + glow * 0.35 + _progress * 0.4,
                                        ),
                                        blurRadius:
                                            30 + glow * 20 + _progress * 30,
                                        spreadRadius: 2 + _progress * 4,
                                      ),
                                    ],
                                  ),
                                ),

                                CustomPaint(
                                  size: const Size(size, size),
                                  painter: _FingerprintRingPainter(
                                    rotation: rotate * 2 * math.pi,
                                    progress: _progress,
                                  ),
                                ),

                                Container(
                                  width: size - 20,
                                  height: size - 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _FPC.card,
                                    border: Border.all(
                                      color: _FPC.border.withOpacity(
                                        0.5 + glow * 0.4 + _progress * 0.5,
                                      ),
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _FPC.primary.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                ),

                                Icon(
                                  _verified
                                      ? Icons.check_rounded
                                      : Icons.fingerprint_rounded,
                                  size: size * 0.4,
                                  color: _FPC.primary,
                                  shadows: [
                                    Shadow(
                                      color: _FPC.primary.withOpacity(
                                        0.7 + glow * 0.3 + _progress * 0.3,
                                      ),
                                      blurRadius: 20 + _progress * 20,
                                    ),
                                  ],
                                ),

                                Positioned(
                                  bottom: size * 0.10,
                                  child: Text(
                                    '${(_progress * 100).toInt()}%',
                                    style: const TextStyle(
                                      color: _FPC.primary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Orbitron',
                                      letterSpacing: 1,
                                      shadows: [
                                        Shadow(
                                          color: Colors.white,
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  AnimatedOpacity(
                    opacity: _verified ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _FPC.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _FPC.border,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _FPC.primary.withOpacity(0.25),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Text(
                        _pressing && _progress < 1.0
                            ? 'TAHAN TERUS... ${(_progress * 100).toInt()}%'
                            : (_progress > 0 && _progress < 1.0)
                                ? 'JANGAN DILEPAS! ${(_progress * 100).toInt()}%'
                                : 'TEKAN & TAHAN',
                        style: const TextStyle(
                          color: _FPC.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Orbitron',
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.white,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  GestureDetector(
                    onTap: _cancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      decoration: BoxDecoration(
                        color: _FPC.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _FPC.border, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _FPC.primary.withOpacity(0.25),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close_rounded,
                              color: _FPC.primary, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'BATAL',
                            style: TextStyle(
                              color: _FPC.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Orbitron',
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PAINTER: RING PUTIH BERPUTAR + PROGRESS ARC
// ═══════════════════════════════════════════════════════════════════
class _FingerprintRingPainter extends CustomPainter {
  final double rotation;
  final double progress;

  _FingerprintRingPainter({
    required this.rotation,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // ═══ 1. RING PUTIH BERPUTAR ═══
    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        transform: GradientRotation(rotation),
        colors: const [
          Colors.transparent,
          Color(0xFFFFFFFF),
          Color(0xFFE0E0E0),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);

    // ═══ 2. GLOW RING ═══
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        transform: GradientRotation(rotation),
        colors: [
          Colors.transparent,
          const Color(0xFFFFFFFF).withOpacity(0.7),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(center, radius, glowPaint);

    // ═══ 3. TRACK BACKGROUND ═══
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = const Color(0xFFFFFFFF).withOpacity(0.15);
    canvas.drawCircle(center, radius - 10, trackPaint);

    // ═══ 4. PROGRESS ARC ═══
    if (progress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFFFFF);

      final rect = Rect.fromCircle(center: center, radius: radius - 10);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        progress * 2 * math.pi,
        false,
        progressPaint,
      );

      // ═══ 5. GLOW PROGRESS ═══
      final glowProgress = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFFFFF).withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        rect,
        -math.pi / 2,
        progress * 2 * math.pi,
        false,
        glowProgress,
      );

      // ═══ 6. TITIK DI UJUNG PROGRESS ═══
      final endAngle = -math.pi / 2 + progress * 2 * math.pi;
      final dotX = center.dx + (radius - 10) * math.cos(endAngle);
      final dotY = center.dy + (radius - 10) * math.sin(endAngle);

      canvas.drawCircle(
        Offset(dotX, dotY),
        8,
        Paint()
          ..color = const Color(0xFFFFFFFF).withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      canvas.drawCircle(
        Offset(dotX, dotY),
        4,
        Paint()..color = const Color(0xFFFFFFFF),
      );

      canvas.drawCircle(
        Offset(dotX, dotY),
        2,
        Paint()..color = Colors.black,
      );
    }

    // ═══ 7. PARTIKEL TITIK BERPUTAR ═══
    if (progress > 0.1) {
      final dotPaint = Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.9);
      final dots = (progress * 12).round();
      for (int i = 0; i < dots; i++) {
        final angle = (i / dots) * 2 * math.pi + rotation;
        final pos = Offset(
          center.dx + (radius + 8) * math.cos(angle),
          center.dy + (radius + 8) * math.sin(angle),
        );
        canvas.drawCircle(pos, 2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_FingerprintRingPainter old) =>
      old.rotation != rotation || old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════
// PAINTER: GRID PUTIH
// ═══════════════════════════════════════════════════════════════════
class _FpGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = _FPC.border.withOpacity(0.10)
      ..strokeWidth = 0.5;
    const step = 45.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════
// WIDGET: FINGERPRINT VERIFY WIDGET
// ═══════════════════════════════════════════════════════════════════
class FingerprintVerifyWidget extends StatefulWidget {
  final VoidCallback onVerified;
  final double size;
  final Duration duration;

  const FingerprintVerifyWidget({
    super.key,
    required this.onVerified,
    this.size = 220,
    this.duration = const Duration(milliseconds: 1800),
  });

  @override
  State<FingerprintVerifyWidget> createState() =>
      _FingerprintVerifyWidgetState();
}

class _FingerprintVerifyWidgetState extends State<FingerprintVerifyWidget>
    with TickerProviderStateMixin {
  double _progress = 0.0;
  bool _pressing = false;
  bool _verified = false;
  Timer? _timer;
  DateTime? _pressStartTime;
  int _lastPercent = 0;

  late AnimationController _glowController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startPress() {
    if (_verified || _pressing) return;

    HapticFeedback.mediumImpact();
    _pressStartTime = DateTime.now();

    setState(() {
      _pressing = true;
      _progress = 0.0;
      _lastPercent = 0;
    });

    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (t) {
      if (!mounted || !_pressing || _verified) {
        t.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(_pressStartTime!);
      final totalMs = widget.duration.inMilliseconds;
      final newProgress = (elapsed.inMilliseconds / totalMs).clamp(0.0, 1.0);

      final currentPercent = (newProgress * 100).toInt();
      if (currentPercent ~/ 10 > _lastPercent ~/ 10) {
        HapticFeedback.selectionClick();
      }
      _lastPercent = currentPercent;

      setState(() {
        _progress = newProgress;
      });

      if (newProgress >= 1.0) {
        t.cancel();
        _onComplete();
      }
    });
  }

  void _endPress() {
    if (_verified) return;

    _timer?.cancel();
    _pressStartTime = null;

    if (_progress >= 1.0) return;

    if (_progress > 0.0) {
      HapticFeedback.lightImpact();
      final start = _progress;
      const resetDurationMs = 200;
      final startTime = DateTime.now();

      Timer.periodic(const Duration(milliseconds: 16), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        final factor = (1.0 - (elapsed / resetDurationMs)).clamp(0.0, 1.0);
        setState(() {
          _progress = start * factor;
        });
        if (elapsed >= resetDurationMs) {
          t.cancel();
          if (mounted) setState(() => _progress = 0.0);
        }
      });
    }

    if (mounted) setState(() => _pressing = false);
    _pulseController.stop();
    _pulseController.reset();
  }

  void _onComplete() {
    if (_verified) return;

    _verified = true;
    _pressing = false;
    HapticFeedback.heavyImpact();
    _pulseController.stop();

    setState(() => _progress = 1.0);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) widget.onVerified();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _startPress(),
      onPointerUp: (_) => _endPress(),
      onPointerCancel: (_) => _endPress(),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _glowController,
          _rotateController,
          _pulseController,
        ]),
        builder: (context, _) {
          final glow = _glowController.value;
          final rotate = _rotateController.value;
          final pulse =
              _pressing ? (0.9 + _pulseController.value * 0.15) : 1.0;

          return Transform.scale(
            scale: pulse,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _FPC.primary.withOpacity(
                            0.25 + glow * 0.35 + _progress * 0.4,
                          ),
                          blurRadius: 30 + glow * 20 + _progress * 30,
                          spreadRadius: 2 + _progress * 4,
                        ),
                      ],
                    ),
                  ),

                  CustomPaint(
                    size: Size(size, size),
                    painter: _FingerprintRingPainter(
                      rotation: rotate * 2 * math.pi,
                      progress: _progress,
                    ),
                  ),

                  Container(
                    width: size - 20,
                    height: size - 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _FPC.card,
                      border: Border.all(
                        color: _FPC.border.withOpacity(
                          0.5 + glow * 0.4 + _progress * 0.5,
                        ),
                        width: 2.5,
                      ),
                    ),
                  ),

                  Icon(
                    _verified
                        ? Icons.check_rounded
                        : Icons.fingerprint_rounded,
                    size: size * 0.4,
                    color: _FPC.primary,
                  ),

                  Positioned(
                    bottom: size * 0.12,
                    child: Text(
                      '${(_progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: _FPC.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Orbitron',
                        letterSpacing: 1,
                        shadows: [
                          Shadow(color: Colors.white, blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
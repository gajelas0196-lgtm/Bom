import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dashboard_page.dart';

// ─── Palette: Dark Neo-Blue with Glassmorphism ──────────────────────────────
class _C {
  static const bg        = Color(0xFF060B14);
  static const surface    = Color(0xFF0A1424);
  static const steel     = Color(0xFF1A4F8A);
  static const blueMid   = Color(0xFF2370BE);
  static const blueLight = Color(0xFF4A94E8);
  static const chrome    = Color(0xFF7AB4E8);
  static const frost     = Color(0xFFADD4F5);
  static const text      = Color(0xFFE8F2FC);
  static const textSub   = Color(0xFF6A92B8);
  static const border    = Color(0xFF1A2D4A);
  static const accent    = Color(0xFF5BA0F0);
  static const glow      = Color(0xFF3A7BD5);
}

class SplashScreen extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listBugGroup;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;
  final List<dynamic> jjVideos;
  final List<dynamic> thanksTo;

  const SplashScreen({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
    required this.listBug,
    required this.listBugGroup,
    required this.listDoos,
    required this.news,
    required this.jjVideos,
    required this.thanksTo,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoCtrl;
  bool _videoReady = false;
  bool _fadeOutStarted = false;
  bool _isSkipped = false;

  // ─── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _fadeOutCtrl;
  late AnimationController _uiCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _progressCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _skipBtnCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;

  late Animation<double> _uiFade;
  late Animation<Offset>  _uiSlide;
  late Animation<double>  _glowAnim;
  late Animation<double>  _fadeOut;
  late Animation<double>  _skipBtnOpacity;
  late Animation<Offset>  _skipBtnSlide;
  late Animation<double>  _pulseScale;
  late Animation<double>  _waveOffset;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initVideo();
  }

  void _initAnimations() {
    _fadeOutCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeOut = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _fadeOutCtrl, curve: Curves.easeInCubic));

    _uiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _uiFade  = CurvedAnimation(
        parent: _uiCtrl, curve: const Interval(0.2, 1.0, curve: Curves.easeOut));
    _uiSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _uiCtrl, curve: Curves.easeOutCubic));

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.2, end: 1.0)
        .animate(CurvedAnimation(
            parent: _glowCtrl, curve: Curves.easeInOutSine));

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 7))
      ..repeat();

    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 5));

    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat();

    _skipBtnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _skipBtnOpacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(
            parent: _skipBtnCtrl, curve: Curves.easeOut));
    _skipBtnSlide = Tween<Offset>(begin: const Offset(0, -0.6), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _skipBtnCtrl, curve: Curves.easeOutBack));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(
            parent: _pulseCtrl, curve: Curves.easeInOutQuad));

    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _waveOffset = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(
            parent: _waveCtrl, curve: Curves.linear));

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _skipBtnCtrl.forward();
    });
  }

  void _initVideo() {
    _videoCtrl = VideoPlayerController.asset('assets/videos/splash.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _videoReady = true);
        _videoCtrl.setLooping(false);
        _videoCtrl.play();

        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            _uiCtrl.forward();
            _progressCtrl.forward();
          }
        });

        _videoCtrl.addListener(_onVideoProgress);
      }).catchError((_) {
        if (mounted) {
          setState(() => _videoReady = false);
          _uiCtrl.forward();
          _progressCtrl.forward();
          Future.delayed(const Duration(seconds: 4), _navigate);
        }
      });
  }

  void _onVideoProgress() {
    if (!mounted || _isSkipped) return;
    final pos = _videoCtrl.value.position;
    final dur = _videoCtrl.value.duration;
    if (dur == Duration.zero) return;

    if (pos >= dur - const Duration(seconds: 1) && !_fadeOutStarted) {
      _fadeOutStarted = true;
      _fadeOutCtrl.forward();
    }

    if (pos >= dur) _navigate();
  }

  void _skip() {
    if (_isSkipped) return;
    _isSkipped = true;
    _videoCtrl.pause();
    _videoCtrl.removeListener(_onVideoProgress);
    _fadeOutStarted = true;
    _fadeOutCtrl.forward().then((_) {
      if (mounted) _navigate();
    });
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => DashboardPage(
          username:    widget.username,
          password:    widget.password,
          role:        widget.role,
          expiredDate: widget.expiredDate,
          sessionKey:  widget.sessionKey,
          listBug:     widget.listBug,
          listBugGroup:     widget.listBugGroup,
          listDoos:    widget.listDoos,
          news:        widget.news,
          jjVideos:    widget.jjVideos,
          thanksTo: widget.thanksTo,
        ),
        transitionDuration: const Duration(milliseconds: 700),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(
              parent: anim, curve: Curves.easeOutCubic),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoCtrl.removeListener(_onVideoProgress);
    _videoCtrl.dispose();
    _fadeOutCtrl.dispose();
    _uiCtrl.dispose();
    _glowCtrl.dispose();
    _ringCtrl.dispose();
    _progressCtrl.dispose();
    _particleCtrl.dispose();
    _skipBtnCtrl.dispose();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Animated Background ──────────────────────────────────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(_particleCtrl.value),
              size: size,
            ),
          ),

          // ── Wave Gradient Overlay ──────────────────────────────────────
          AnimatedBuilder(
            animation: _waveOffset,
            builder: (_, __) => Positioned.fill(
              child: CustomPaint(
                painter: _WavePainter(_waveOffset.value),
                size: size,
              ),
            ),
          ),

          // ── Video ────────────────────────────────────────────────────────
          if (_videoReady && !_isSkipped)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width:  _videoCtrl.value.size.width,
                  height: _videoCtrl.value.size.height,
                  child: VideoPlayer(_videoCtrl),
                ),
              ),
            ),

          // ── Glass Overlay ──────────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(_videoReady && !_isSkipped ? 0.15 : 0.0),
                    Colors.black.withOpacity(_videoReady && !_isSkipped ? 0.75 : 0.0),
                    _C.bg.withOpacity(_videoReady && !_isSkipped ? 0.3 : 0.0),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // ── Skip Button ──────────────────────────────────────────────────
          Positioned(
            top: 20,
            right: 20,
            child: FadeTransition(
              opacity: _skipBtnOpacity,
              child: SlideTransition(
                position: _skipBtnSlide,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _skip,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _C.border.withOpacity(0.85),
                            _C.surface.withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _C.blueMid.withOpacity(0.4),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _C.blueMid.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.skip_next_rounded,
                            size: 18,
                            color: _C.blueLight,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Skip',
                            style: TextStyle(
                              color: _C.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Center Content ──────────────────────────────────────────────
          Positioned.fill(
            child: FadeTransition(
              opacity: _uiFade,
              child: SlideTransition(
                position: _uiSlide,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogoRing(),
                    const SizedBox(height: 40),
                    _buildTitle(),
                    const SizedBox(height: 12),
                    _buildSubtitle(),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom Section ──────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: FadeTransition(
              opacity: _uiFade,
              child: _buildBottomBar(),
            ),
          ),

          // ── Fade Out ─────────────────────────────────────────────────────
          if (_fadeOutStarted)
            FadeTransition(
              opacity: _fadeOut,
              child: Container(color: _C.bg),
            ),
        ],
      ),
    );
  }

  // ─── Logo Ring ────────────────────────────────────────────────────────────
  Widget _buildLogoRing() {
    return AnimatedBuilder(
      animation: Listenable.merge([_ringCtrl, _glowCtrl, _pulseCtrl]),
      builder: (_, __) => Transform.scale(
        scale: _pulseScale.value,
        child: SizedBox(
          width: 180, height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width: 178, height: 178,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _C.blueMid.withOpacity(_glowAnim.value * 0.08),
                      Colors.transparent,
                    ],
                    radius: 0.7,
                  ),
                  border: Border.all(
                    color: _C.blueMid.withOpacity(_glowAnim.value * 0.12),
                    width: 1.2,
                  ),
                ),
              ),
              // Rotating ring
              Transform.rotate(
                angle: _ringCtrl.value * math.pi * 2,
                child: Container(
                  width: 158, height: 158,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        _C.chrome.withOpacity(_glowAnim.value * 0.6),
                        _C.blueLight.withOpacity(_glowAnim.value * 0.3),
                        Colors.transparent,
                        _C.blueMid.withOpacity(_glowAnim.value * 0.4),
                        Colors.transparent,
                        _C.frost.withOpacity(_glowAnim.value * 0.2),
                      ],
                      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
              // Counter ring
              Transform.rotate(
                angle: -_ringCtrl.value * math.pi * 2 * 0.5,
                child: Container(
                  width: 132, height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _C.steel.withOpacity(_glowAnim.value * 0.6),
                      width: 1.8,
                    ),
                  ),
                ),
              ),
              // Glow ring
              Container(
                width: 108, height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _C.blueMid.withOpacity(_glowAnim.value * 0.4),
                      _C.bg,
                    ],
                    radius: 0.5,
                  ),
                ),
              ),
              // Core
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _C.bg,
                  boxShadow: [
                    BoxShadow(
                      color: _C.blueMid.withOpacity(_glowAnim.value * 0.5),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                    BoxShadow(
                      color: _C.chrome.withOpacity(_glowAnim.value * 0.15),
                      blurRadius: 80,
                      spreadRadius: 20,
                    ),
                  ],
                  border: Border.all(
                    color: _C.blueLight.withOpacity(_glowAnim.value * 0.4),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(Icons.water_rounded,
                          color: _C.blueLight.withOpacity(_glowAnim.value),
                          size: 48),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Title ────────────────────────────────────────────────────────────────
  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ShaderMask(
        shaderCallback: (b) => LinearGradient(
          colors: [
            _C.frost,
            _C.chrome,
            _C.blueLight,
            _C.frost,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.3, 0.7, 1.0],
        ).createShader(b),
        child: Text(
          'OneCrash project',
          style: TextStyle(
            fontSize: 38,
            fontFamily: "Qaxer",
            color: Colors.white,
            letterSpacing: 2.0,
            shadows: [
              Shadow(
                color: _C.blueMid.withOpacity(_glowAnim.value * 0.7),
                blurRadius: 30,
              ),
              Shadow(
                color: _C.chrome.withOpacity(_glowAnim.value * 0.3),
                blurRadius: 60,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _C.border.withOpacity(0.3),
              _C.border.withOpacity(0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _C.blueMid.withOpacity(_glowAnim.value * 0.2),
            width: 0.5,
          ),
        ),
        child: Text(
          '✦  Powered By @By_Zii  ✦',
          style: TextStyle(
            color: _C.textSub.withOpacity(0.6 + _glowAnim.value * 0.4),
            fontSize: 12,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }

  // ─── Bottom Bar ───────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 56),
      child: Column(
        children: [
          _LoadingDots(),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _progressCtrl,
            builder: (_, __) => Column(children: [
              // Progress bar with glow
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 4,
                      width: double.infinity,
                      color: _C.border.withOpacity(0.4),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 4,
                      width: (MediaQuery.of(context).size.width - 64) *
                          _progressCtrl.value,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _C.steel,
                            _C.blueMid,
                            _C.blueLight,
                            _C.chrome,
                          ],
                          stops: const [0.0, 0.3, 0.7, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _C.blueMid.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(_progressCtrl.value * 100).toInt()}%',
                    style: const TextStyle(
                      color: _C.textSub,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '•',
                    style: TextStyle(
                      color: _C.textSub,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _progressCtrl.value < 0.33 ? 'Initializing...' :
                    _progressCtrl.value < 0.66 ? 'Loading assets...' :
                    'Ready...',
                    style: const TextStyle(
                      color: _C.textSub,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Loading Dots ─────────────────────────────────────────────────────────────
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final t = ((_c.value - i / 3) % 1.0).clamp(0.0, 1.0);
          final s = math.sin(t * math.pi);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Transform.scale(
              scale: 0.3 + s * 0.7,
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _C.blueLight.withOpacity(0.2 + s * 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: _C.blueMid.withOpacity(s * 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Wave Painter ─────────────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final double offset;
  _WavePainter(this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final paint = Paint()
      ..color = _C.blueMid.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;

    path.moveTo(0, height);
    for (double x = 0; x <= width; x += 1) {
      final y = height * 0.1 +
          math.sin((x / width) * 2 * math.pi + offset * 2 * math.pi) *
              height * 0.03 +
          math.sin((x / width) * 4 * math.pi + offset * 3 * math.pi) *
              height * 0.02;
      path.lineTo(x, y);
    }
    path.lineTo(width, height);
    path.close();
    canvas.drawPath(path, paint);

    // Second wave
    final path2 = Path();
    final paint2 = Paint()
      ..color = _C.blueLight.withOpacity(0.025)
      ..style = PaintingStyle.fill;

    path2.moveTo(0, height);
    for (double x = 0; x <= width; x += 1) {
      final y = height * 0.15 +
          math.sin((x / width) * 3 * math.pi + offset * 1.5 * math.pi + 1) *
              height * 0.025 +
          math.sin((x / width) * 5 * math.pi + offset * 4 * math.pi) *
              height * 0.015;
      path2.lineTo(x, y);
    }
    path2.lineTo(width, height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.offset != offset;
}

// ─── Particle Painter ─────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double t;
  _ParticlePainter(this.t);

  static final _rand = math.Random(42);
  static final _particles = List.generate(35, (i) => _Particle(
    x: _rand.nextDouble(),
    y: _rand.nextDouble(),
    size: 0.8 + _rand.nextDouble() * 2.5,
    speed: 0.03 + _rand.nextDouble() * 0.12,
    phase: _rand.nextDouble(),
    opacity: 0.1 + _rand.nextDouble() * 0.4,
    driftAmount: 0.5 + _rand.nextDouble() * 2.0,
  ));

  @override
  void paint(Canvas canvas, Size size) {
    // Grid
    final grid = Paint()
      ..color = const Color(0xFF1A2D4A).withOpacity(0.2)
      ..strokeWidth = 0.3;
    const step = 50.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Central glow
    final center = Offset(size.width / 2, size.height * 0.35);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          _C.blueMid.withOpacity(0.12 + math.sin(t * math.pi * 2) * 0.05),
          _C.steel.withOpacity(0.05),
          Colors.transparent,
        ],
        radius: 0.7,
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(
          center: center, radius: size.width * 0.8));
    canvas.drawCircle(center, size.width * 0.8, glow);

    // Particles
    for (final p in _particles) {
      final px = p.x * size.width;
      final rawY = p.y + (t * p.speed) % 1.0;
      final py = (rawY % 1.0) * size.height;
      final driftX = math.sin((t + p.phase) * math.pi * 2) * p.driftAmount;
      final driftY = math.cos((t * 0.7 + p.phase) * math.pi * 2) * p.driftAmount * 0.6;
      final osc = math.sin((t * 2 + p.phase) * math.pi);
      final opacity = p.opacity * (0.4 + osc * 0.6);

      // Glow
      canvas.drawCircle(
        Offset(px + driftX, py + driftY),
        p.size * 3,
        Paint()..color = _C.blueMid.withOpacity(opacity * 0.15),
      );

      // Core
      canvas.drawCircle(
        Offset(px + driftX, py + driftY),
        p.size,
        Paint()..color = _C.blueLight.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}

class _Particle {
  final double x, y, size, speed, phase, opacity, driftAmount;
  const _Particle({
    required this.x, required this.y, required this.size,
    required this.speed, required this.phase, required this.opacity,
    required this.driftAmount,
  });
}
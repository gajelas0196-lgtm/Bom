import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'fingerprint_verify.dart';

// ─── Palette: HITAM + PUTIH GLOW ────────────────────────────────────────────
class _C {
  static const bg         = Color(0xFF000000);
  static const surface    = Color(0xFF121212);
  static const card       = Color(0xFF1A1A1A);
  static const cardAlt    = Color(0xFF222222);

  static const border     = Color(0xFFFFFFFF);
  static const borderLit  = Color(0xFFE0E0E0);

  static const primary      = Color(0xFFFFFFFF);
  static const primaryMid   = Color(0xFFE0E0E0);
  static const primaryLight = Color(0xFFFFFFFF);
  static const primaryFrost = Color(0xFFB0B0B0);

  static const accent     = Color(0xFFFFFFFF);
  static const gold       = Color(0xFFFFCC00);
  static const silver     = Color(0xFFB0B0B0);

  static const text       = Color(0xFFFFFFFF);
  static const textSub    = Color(0xFFB0B0B0);
  static const textDim    = Color(0xFF808080);

  static const luxeGrad = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
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
// LANDING PAGE dengan Fingerprint Gate
// ═══════════════════════════════════════════════════════════════════
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  bool _fingerprintVerified = false;

  late AnimationController _bgCtrl;
  late AnimationController _entranceCtrl;
  late AnimationController _logoCtrl;
  late AnimationController _btnCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _fade;
  late Animation<Offset>  _slide;
  late Animation<double>  _logoPulse;
  late Animation<double>  _logoGlow;
  late Animation<double>  _btnGlow;
  late Animation<double>  _particleFade;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 30))
      ..repeat();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _fade  = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutQuad);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceCtrl, curve: Curves.easeOutCubic));

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);
    _logoPulse = Tween<double>(begin: 0.92, end: 1.02)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeInOutSine));
    _logoGlow = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeInOutSine));

    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _btnGlow = Tween<double>(begin: 0.3, end: 0.7)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOutSine));

    _orbCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 16))
      ..repeat();

    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _particleFade = Tween<double>(begin: 0.0, end: 0.6)
        .animate(CurvedAnimation(parent: _particleCtrl, curve: Curves.easeInOutQuad));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _entranceCtrl.dispose();
    _logoCtrl.dispose();
    _btnCtrl.dispose();
    _orbCtrl.dispose();
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_fingerprintVerified) {
      return FingerprintVerifyPage(
        title: 'VERIFIKASI SIDIK JARI',
        subtitle: 'Tekan & tahan sampai 100% untuk lanjut',
        onVerified: () {
          if (mounted) {
            setState(() => _fingerprintVerified = true);
          }
        },
        onCancel: () {},
      );
    }

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: _AnimatedBg(
              bgCtrl: _bgCtrl,
              orbCtrl: _orbCtrl,
              particleFade: _particleFade,
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      _buildHeroSection(),
                      const SizedBox(height: 28),
                      _buildBanner(),
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildFeatureList(),
                            const SizedBox(height: 28),
                            _buildSignInButton(),
                            const SizedBox(height: 12),
                            _buildBuyButton(),
                            const SizedBox(height: 30),
                            _buildDivider(),
                            const SizedBox(height: 22),
                            Row(children: [
                              Expanded(child: _ContactBtn(
                                icon: FaIcon(FontAwesomeIcons.telegram,
                                label: 'Telegram',
                                color: const Color(0xFFFFFFFF),
                                colorDim: const Color(0xFF1A1A1A),
                                onTap: () => _openUrl('https://t.me/By_Zii16'),
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _ContactBtn(
                                icon: FaIcon(FontAwesomeIcons.whatsapp,
                                label: 'WhatsApp',
                                color: const Color(0xFFFFFFFF),
                                colorDim: const Color(0xFF1A1A1A),
                                onTap: () => _openUrl('https://wa.me/6285199553068'),
                              )),
                            ]),
                            const SizedBox(height: 36),
                            _buildFooter(),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero Section ─────────────────────────────────────────────────────────
  Widget _buildHeroSection() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Column(children: [
        AnimatedBuilder(
          animation: _logoCtrl,
          builder: (_, __) => Transform.scale(
            scale: _logoPulse.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _C.primaryMid.withOpacity(_logoGlow.value * 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _C.primary.withOpacity(_logoGlow.value * 0.25),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _C.primaryLight.withOpacity(_logoGlow.value * 0.4),
                      width: 2,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _orbCtrl.value * math.pi * 2,
                  child: Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          _C.primary.withOpacity(_logoGlow.value * 0.5),
                          _C.accent.withOpacity(_logoGlow.value * 0.3),
                          _C.primaryLight.withOpacity(_logoGlow.value * 0.4),
                          Colors.transparent,
                          _C.primary.withOpacity(_logoGlow.value * 0.5),
                        ],
                        stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 92, height: 92,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: _C.primaryLight.withOpacity(_logoGlow.value * 0.7),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _C.primary.withOpacity(_logoGlow.value * 0.5),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: _C.accent.withOpacity(_logoGlow.value * 0.2),
                        blurRadius: 60,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/reze.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: _C.luxeGrad,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.black, size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 92, height: 92,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                        Colors.white.withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        ShaderMask(
          shaderCallback: (b) => _C.textGrad.createShader(b),
          child: const Text(
            'OneCrash project',
            style: TextStyle(
              fontSize: 36,
              fontFamily: "Qaxer",
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 6,
              height: 1,
              shadows: [
                Shadow(color: Colors.white, blurRadius: 20),
              ],
            ),
          ),
        ),

        const SizedBox(height: 6),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _C.card.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.border.withOpacity(0.7)),
            boxShadow: [
              BoxShadow(
                color: _C.primary.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _C.primaryLight,
                  boxShadow: [
                    BoxShadow(
                      color: _C.primaryLight.withOpacity(0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Version 17 • POWERED BY @By_Zii16',
                style: TextStyle(
                  color: _C.textSub,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Ready',
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  // ─── Landing Banner ──────────────────────────────────────────────────────
  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: _C.softGrad,
          border: Border.all(color: _C.border, width: 2),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: _C.accent.withOpacity(0.15),
              blurRadius: 40,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/landing.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: _C.surface,
                  child: Icon(Icons.broken_image, color: _C.textDim, size: 50),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _C.bg.withOpacity(0.5),
                      Colors.transparent,
                      _C.bg.withOpacity(0.4),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.transparent,
                      Colors.white.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _C.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _C.primary, width: 1.5),
                          ),
                          child: Icon(Icons.bolt_rounded, color: _C.primaryLight, size: 14),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Version 17',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            fontFamily: 'Ready',
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _C.accent.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _C.primaryLight, width: 1.5),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              fontFamily: 'Aktura',
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OneCrash project',
                          style: TextStyle(
                            color: _C.primaryLight,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Qaxer',
                            height: 1,
                            shadows: [
                            Shadow(color: Colors.black54, blurRadius: 8),
                            Shadow(color: _C.primary.withOpacity(0.8), blurRadius: 15),
                          ],
                        ),
                      ),
                      Text(
                        'Powered By @By_Zii',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Qaxer',
                          height: 1,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── Feature List ────────────────────────────────────────────────────────
Widget _buildFeatureList() {
  return Column(
    children: [
      _FeatureItem(
        icon: Icons.flash_on_rounded,
        title: 'ULTRA FAST',
        desc: 'Lightning speed performance & low latency execution.',
        color: _C.primaryLight,
      ),
      const SizedBox(height: 12),
      _FeatureItem(
        icon: Icons.shield_rounded,
        title: 'SECURE',
        desc: 'End-to-end encryption & anti-tamper APK security.',
        color: _C.accent,
      ),
      const SizedBox(height: 12),
      _FeatureItem(
        icon: Icons.track_changes_rounded,
        title: 'POWERFUL',
        desc: 'Advanced tools & remote access features built-in.',
        color: _C.gold,
      ),
    ],
  );
}

// ─── Sign In Button ───────────────────────────────────────────────────────
Widget _buildSignInButton() {
  return AnimatedBuilder(
    animation: _btnCtrl,
    builder: (_, __) => _PressableBtn(
      onTap: () => Navigator.pushNamed(context, '/login'),
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: _C.luxeGrad,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.accent, width: 2),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withOpacity(_btnGlow.value * 0.6),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: _C.accent.withOpacity(_btnGlow.value * 0.3),
              blurRadius: 40,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.2),
                border: Border.all(color: Colors.black.withOpacity(0.4), width: 1.5),
              ),
              child: const Icon(Icons.login_rounded,
                  color: Colors.black, size: 18),
            ),
            const SizedBox(width: 14),
            const Text(
              'ENTER LOGIN',
              style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontFamily: "Aktura",
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded,
                color: Colors.black.withOpacity(0.9), size: 16),
          ],
        ),
      ),
    ),
  );
}
  // ─── Buy Access Button ────────────────────────────────────────────────────
  Widget _buildBuyButton() {
    return _PressableBtn(
      onTap: () => _openUrl('https://t.me/By_Zii16'),
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.border, width: 2),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_C.gold.withOpacity(0.2), _C.gold.withOpacity(0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: _C.gold.withOpacity(0.5), width: 1.5),
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  color: _C.gold, size: 17),
            ),
            const SizedBox(width: 14),
            const Text(
              'BUY ACCESS',
              style: TextStyle(
                color: _C.text,
                fontSize: 17,
                fontFamily: "Aktura",
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.gold.withOpacity(0.18), _C.gold.withOpacity(0.06)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _C.gold.withOpacity(0.4), width: 1),
              ),
              child: const Text('VIA TG',
                  style: TextStyle(color: _C.gold, fontSize: 10,
                      fontWeight: FontWeight.w900, letterSpacing: 0.8, fontFamily: 'Aktura')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(children: [
      Expanded(
        child: Container(
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, _C.border, Colors.transparent],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _C.primary.withOpacity(0.2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_rounded, color: _C.primary, size: 12),
              const SizedBox(width: 6),
              const Text('JOIN OneCrash COMMUNITY',
                  style: TextStyle(color: _C.textSub, fontSize: 10, fontFamily: "Qaxer",
                      fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            ],
          ),
        ),
      ),
      Expanded(
        child: Container(
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, _C.border, Colors.transparent],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildFooter() {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 40, height: 2,
          decoration: BoxDecoration(
            gradient: _C.luxeGrad,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _C.border.withOpacity(0.7), width: 1.2),
          ),
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: _C.textDim, fontSize: 11, letterSpacing: 0.8, fontWeight: FontWeight.w700),
              children: const [
                TextSpan(text: '© ', style: TextStyle(fontFamily: 'Qaxer')),
                TextSpan(text: '2026', style: TextStyle(fontFamily: 'Ready')),
                TextSpan(text: 'OneCrash project', style: TextStyle(fontFamily: 'Qaxer')),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Container(
          width: 40, height: 2,
          decoration: BoxDecoration(
            gradient: _C.luxeGrad,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ]),
    ]);
  }
}

// ─── Feature Item ─────────────────────────────────────────────────────────────
class _FeatureItem extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String desc;
  final Color color;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _C.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Aktura',
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: _C.textSub,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.6), blurRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Contact Button ───────────────────────────────────────────────────────────
class _ContactBtn extends StatefulWidget {
  final dynamic icon;
  final String label;
  final Color color;
  final Color colorDim;
  final VoidCallback onTap;

  const _ContactBtn({
    required this.icon, required this.label,
    required this.color, required this.colorDim,
    required this.onTap,
  });

  @override
  State<_ContactBtn> createState() => _ContactBtnState();
}

class _ContactBtnState extends State<_ContactBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          decoration: BoxDecoration(
            color: _pressed
                ? widget.color.withOpacity(0.1)
                : _C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.color,
              width: 2,
            ),
            boxShadow: _pressed
                ? [BoxShadow(color: widget.color.withOpacity(0.3),
                    blurRadius: 16, offset: const Offset(0, 6))]
                : [
                    BoxShadow(color: widget.color.withOpacity(0.2),
                        blurRadius: 12, offset: const Offset(0, 4)),
                  ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.colorDim,
                border: Border.all(color: widget.color, width: 1.5),
              ),
              child: Center(
                child: FaIcon(widget.icon, color: widget.color, size: 14),
              ),
            ),
            const SizedBox(width: 10),
            Text(widget.label,
                style: const TextStyle(color: _C.text, fontSize: 14,
                    fontWeight: FontWeight.w800, fontFamily: 'Aktura',
                    letterSpacing: 0.5)),
          ]),
        ),
      ),
    );
  }
}

// ─── Pressable Button ─────────────────────────────────────────────────────────
class _PressableBtn extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableBtn({required this.child, required this.onTap});

  @override
  State<_PressableBtn> createState() => _PressableBtnState();
}

class _PressableBtnState extends State<_PressableBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) { setState(() => _down = false); widget.onTap(); },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: AnimatedOpacity(
          opacity: _down ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: widget.child,
        ),
      ),
    );
  }
}

// ─── Animated Background ──────────────────────────────────────────────────────
class _AnimatedBg extends StatelessWidget {
  final AnimationController bgCtrl;
  final AnimationController orbCtrl;
  final Animation<double> particleFade;
  const _AnimatedBg({
    required this.bgCtrl,
    required this.orbCtrl,
    required this.particleFade,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([bgCtrl, orbCtrl, particleFade]),
      builder: (_, __) => CustomPaint(
        painter: _BgPainter(bgCtrl.value, orbCtrl.value, particleFade.value),
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  final double t;
  final double o;
  final double p;

  _BgPainter(this.t, this.o, this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = _C.softGrad.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final grid = Paint()
      ..color = _C.border.withOpacity(0.10)
      ..strokeWidth = 0.5;
    const step = 45.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final glow1 = Paint()
      ..shader = RadialGradient(
        colors: [
          _C.primary.withOpacity(0.08 + math.sin(t * math.pi * 2) * 0.03),
          _C.accent.withOpacity(0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.8],
        radius: 0.8,
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 0.3),
        radius: size.width * 0.8,
      ));
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.3),
      size.width * 0.8,
      glow1,
    );

    final glow2 = Paint()
      ..shader = RadialGradient(
        colors: [
          _C.accent.withOpacity(0.06 + math.sin(t * math.pi * 2 + 1) * 0.03),
          Colors.transparent,
        ],
        radius: 0.6,
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.25, size.height * 0.6),
        radius: size.width * 0.5,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.6),
      size.width * 0.5,
      glow2,
    );

    final angle = o * math.pi * 2;
    final orbX = size.width / 2 + math.cos(angle) * size.width * 0.32;
    final orbY = size.height * 0.25 + math.sin(angle * 0.7) * 80;

    final orbGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          _C.primaryLight.withOpacity(0.15 * p),
          _C.primaryLight.withOpacity(0.05 * p),
          Colors.transparent,
        ],
        radius: 0.5,
      ).createShader(Rect.fromCircle(center: Offset(orbX, orbY), radius: 100));
    canvas.drawCircle(Offset(orbX, orbY), 100, orbGlow);

    for (int i = 0; i < 3; i++) {
      final a = angle + (i * 2.094);
      final dx = size.width / 2 + math.cos(a) * size.width * 0.25;
      final dy = size.height * 0.35 + math.sin(a) * 120;
      final dot = Paint()
        ..color = _C.primaryLight.withOpacity(0.15 * p)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dx, dy), 4 + math.sin(t * 4 + i) * 2, dot);
    }

    final fade = Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, _C.bg],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(
          Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5),
      fade,
    );
  }

  @override
  bool shouldRepaint(_BgPainter old) =>
      old.t != t || old.o != o || old.p != p;
}
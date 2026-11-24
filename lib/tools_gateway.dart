import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'manage_server.dart';
import 'wifi_internal.dart';
import 'wifi_external.dart';
import 'ddos_panel.dart';
import 'nik_check.dart';
import 'tiktok_page.dart';
import 'instagram_page.dart';
import 'qr_gen.dart';
import 'domain_page.dart';
import 'spam_ngl.dart';
import 'cek_ban_wa.dart';

// ======================== CUSTOM CLIPPER ========================
class _ClippedCornerClipper extends CustomClipper<Path> {
  final double cut;
  const _ClippedCornerClipper({this.cut = 14});

  @override
  Path getClip(Size size) {
    final p = Path();
    final c = cut;
    p.moveTo(c, 0);
    p.lineTo(size.width - c, 0);
    p.lineTo(size.width, c);
    p.lineTo(size.width, size.height - c);
    p.lineTo(size.width - c, size.height);
    p.lineTo(c, size.height);
    p.lineTo(0, size.height - c);
    p.lineTo(0, c);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(_ClippedCornerClipper old) => cut != old.cut;
}

// ======================== CUSTOM PAINTERS ========================
class _DotGridPainter extends CustomPainter {
  final Color color;
  _DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => color != old.color;
}

class _ScanLinePainter extends CustomPainter {
  final double position;
  final Color color;
  _ScanLinePainter({required this.position, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = position * (size.height + 80) - 40;
    final rect = Rect.fromLTWH(0, y - 35, size.width, 70);
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        color.withOpacity(0.06),
        color.withOpacity(0.10),
        color.withOpacity(0.06),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => position != old.position;
}

class _RadarPainter extends CustomPainter {
  final double angle;
  final Color color;
  _RadarPainter({required this.angle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 2;

    final circlePaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, r * i / 3, circlePaint);
    }

    final linePaint = Paint()
      ..color = color.withOpacity(0.15)
      ..strokeWidth = 0.5;
    canvas.drawLine(
        Offset(center.dx - r, center.dy), Offset(center.dx + r, center.dy), linePaint);
    canvas.drawLine(
        Offset(center.dx, center.dy - r), Offset(center.dx, center.dy + r), linePaint);

    final sweepShader = SweepGradient(
      startAngle: angle - 0.6,
      endAngle: angle,
      colors: [color.withOpacity(0.0), color.withOpacity(0.35)],
    ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, Paint()..shader = sweepShader);

    final endPt = Offset(
        center.dx + math.cos(angle) * r, center.dy + math.sin(angle) * r);
    canvas.drawLine(center, endPt, Paint()..color = color.withOpacity(0.8)..strokeWidth = 1.5);

    canvas.drawCircle(center, 2.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RadarPainter old) => angle != old.angle;
}

class _DiagonalStripePainter extends CustomPainter {
  final Color color;
  _DiagonalStripePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (double i = -size.height; i < size.width + size.height; i += 18) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_DiagonalStripePainter old) => color != old.color;
}

// ======================== TOOL ITEM MODEL ========================
class _ToolItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool locked;
  const _ToolItem(
      {required this.icon, required this.label, required this.onTap, this.locked = false});
}

// ======================== MAIN WIDGET ========================
class ToolsPage extends StatefulWidget {
  final String sessionKey;
  final String userRole;
  final List<Map<String, dynamic>> listDoos;

  const ToolsPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
    required this.listDoos,
  });

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> with TickerProviderStateMixin {
  // ═══════════════════════════════════════════════════════════════
  // PALETTE — HITAM + PUTIH GLOW
  // ═══════════════════════════════════════════════════════════════
  final Color primaryDark   = const Color(0xFF000000); // hitam total
  final Color primaryRed    = const Color(0xFFFFFFFF); // putih (accent)
  final Color accentRed     = const Color(0xFFE0E0E0); // putih pudar
  final Color lightRed      = const Color(0xFFFFFFFF); // putih
  final Color primaryWhite  = const Color(0xFFFFFFFF); // teks putih
  final Color accentGrey    = const Color(0xFFB0B0B0); // abu terang
  final Color cardDark      = const Color(0xFF1A1A1A); // abu gelap (kartu)
  final Color borderDark    = const Color(0xFFFFFFFF); // border putih

  late AnimationController _scanCtrl;
  late AnimationController _radarCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _tickerCtrl;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _radarCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
          ..repeat(reverse: true);
    _tickerCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat();
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _radarCtrl.dispose();
    _pulseCtrl.dispose();
    _tickerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DotGridPainter(color: primaryRed.withOpacity(0.08)),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _scanCtrl,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ScanLinePainter(position: _scanCtrl.value, color: lightRed),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildDataTicker()),
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildStatusBar()),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(child: _animateEntry(0, _buildHeroCard())),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: _animateEntry(
                      1,
                      Row(
                        children: [
                          Expanded(child: _buildNetworkCard()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildOsintCard()),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: _animateEntry(
                      2,
                      Row(
                        children: [
                          Expanded(flex: 3, child: _buildDownloaderCard()),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: _buildUtilityCard()),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(child: _animateEntry(3, _buildQuickAccess())),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTicker() {
    final text =
        "SYS.ONLINE  //  TOOLS:7  //  NODE:ACTIVE  //  ENCRYPTED:AES-256  //  LATENCY:12ms  //  UPTIME:99.9%  //  ";
    final textStyle = TextStyle(
      color: lightRed.withOpacity(0.6),
      fontSize: 10,
      fontFamily: 'ShareTechMono',
      letterSpacing: 1.5,
    );

    return SizedBox(
      height: 22,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _tickerCtrl,
          builder: (context, _) {
            return Transform.translate(
              offset: Offset(-_tickerCtrl.value * 600, 0),
              child: Row(
                children: [
                  Text(text, style: textStyle),
                  Text(text, style: textStyle),
                  Text(text, style: textStyle),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: AnimatedBuilder(
              animation: _radarCtrl,
              builder: (context, _) {
                return CustomPaint(
                  painter: _RadarPainter(
                    angle: _radarCtrl.value * 2 * math.pi,
                    color: primaryRed,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TOOLS DASHBOARD",
                  style: TextStyle(
                    color: primaryWhite,
                    fontSize: 22,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(color: primaryRed.withOpacity(0.6), blurRadius: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Advanced Security & OSINT Suite",
                  style: TextStyle(
                    color: accentGrey.withOpacity(0.7),
                    fontSize: 11,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, _) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryRed.withOpacity(0.5 + _pulseCtrl.value * 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: primaryRed.withOpacity(0.3 + _pulseCtrl.value * 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                "ONLINE",
                style: TextStyle(
                  color: primaryRed,
                  fontSize: 8,
                  fontFamily: 'ShareTechMono',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          _buildStatusChip(Icons.widgets, "7 TOOLS", primaryRed),
          const SizedBox(width: 8),
          _buildStatusChip(Icons.bolt, "PRIORITY", primaryWhite),
          const SizedBox(width: 8),
          _buildStatusChip(Icons.shield, "SECURED", accentGrey),
        ],
      ),
    );
  }

  Widget _buildStatusChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderDark, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryRed.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontFamily: 'ShareTechMono',
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CekBanWaPage(sessionKey: widget.sessionKey),
                ),
              );
            },
            child: ClipPath(
              clipper: const _ClippedCornerClipper(cut: 18),
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cardDark,
                      primaryRed.withOpacity(0.15),
                      cardDark,
                    ],
                  ),
                  border: Border.all(color: primaryRed, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: primaryRed.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DiagonalStripePainter(
                            color: lightRed.withOpacity(0.06)),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, _) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: primaryRed.withOpacity(
                                  0.3 + _pulseCtrl.value * 0.5),
                              width: 1.5,
                            ),
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryRed, accentRed],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: primaryRed.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryRed.withOpacity(0.5),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: Colors.black,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "CEK BAN WA",
                                      style: TextStyle(
                                        color: primaryWhite,
                                        fontSize: 17,
                                        fontFamily: 'Orbitron',
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                        shadows: [
                                          Shadow(color: primaryRed.withOpacity(0.6), blurRadius: 8),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: primaryRed.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: primaryRed, width: 1.5),
                                      ),
                                      child: const Text(
                                        "REAL",
                                        style: TextStyle(
                                         color: Color(0xFFFFFFFF),
                          fontSize: 9,
                          fontFamily: 'ShareTechMono',
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Deteksi nomor WhatsApp aman / kena ban",
                  style: TextStyle(
                    color: accentGrey.withOpacity(0.7),
                    fontSize: 11,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryRed,
                        boxShadow: [
                          BoxShadow(
                              color: primaryRed,
                              blurRadius: 4,
                              spreadRadius: 1),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "CEK SEKARANG",
                      style: TextStyle(
                        color: primaryRed,
                        fontSize: 9,
                        fontFamily: 'ShareTechMono',
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              color: accentGrey.withOpacity(0.4), size: 28),
        ],
      ),
    ),
    _buildCornerMarks(color: primaryRed, size: 18),
  ],
),
),
),
),
const SizedBox(height: 12),

// ═══ CARD DDoS (HERO LAMA) ═══
GestureDetector(
  onTap: () => _showDDoSTools(context),
  child: ClipPath(
    clipper: const _ClippedCornerClipper(cut: 18),
    child: Container(
      height: 110,
      decoration: BoxDecoration(
        color: cardDark,
        border: Border.all(color: primaryRed, width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryRed.withOpacity(0.2),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: primaryRed, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: primaryRed.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(Icons.flash_on,
                      color: primaryRed, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "DDoS TOOLS",
                        style: TextStyle(
                          color: primaryWhite,
                          fontSize: 15,
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Attack Panel & Server Management",
                        style: TextStyle(
                          color: accentGrey.withOpacity(0.6),
                          fontSize: 10,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: accentGrey.withOpacity(0.3), size: 26),
              ],
            ),
          ),
          _buildCornerMarks(color: primaryRed, size: 18),
        ],
      ),
    ),
  ),
),
],
),
);
}

// ═══ NETWORK CARD ═══
Widget _buildNetworkCard() {
  final toolCount = (widget.userRole == "vip" || widget.userRole == "owner") ? 4 : 3;
  return _buildClippedCard(
    icon: Icons.wifi,
    title: "NETWORK",
    subtitle: "WiFi & Spam",
    toolCount: toolCount,
    accentColor: primaryRed,
    onTap: () => _showNetworkTools(context),
    cut: 14,
  );
}

// ═══ OSINT CARD ═══
Widget _buildOsintCard() {
  return _buildClippedCard(
    icon: Icons.search,
    title: "OSINT",
    subtitle: "Investigation",
    toolCount: 4,
    accentColor: primaryRed,
    onTap: () => _showOSINTTools(context),
    cut: 14,
  );
}

// ═══ DOWNLOADER CARD ═══
Widget _buildDownloaderCard() {
  return Padding(
    padding: const EdgeInsets.only(left: 20),
    child: GestureDetector(
      onTap: () => _showDownloaderTools(context),
      child: ClipPath(
        clipper: const _ClippedCornerClipper(cut: 14),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: cardDark,
            border: Border.all(color: primaryRed, width: 1.8),
            boxShadow: [
              BoxShadow(color: primaryRed.withOpacity(0.15), blurRadius: 12),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primaryRed.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryRed, width: 1.5),
                      ),
                      child: Icon(Icons.download, color: primaryRed, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "DOWNLOADER",
                            style: TextStyle(
                              color: primaryWhite,
                              fontSize: 13,
                              fontFamily: 'Orbitron',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "Social Media",
                            style: TextStyle(
                              color: accentGrey.withOpacity(0.6),
                              fontSize: 10,
                              fontFamily: 'ShareTechMono',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildPlatformBadge("TT", const Color(0xFFFFFFFF)),
                              const SizedBox(width: 6),
                              _buildPlatformBadge("IG", const Color(0xFFE0E0E0)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: accentGrey.withOpacity(0.4), size: 24),
                  ],
                ),
              ),
              _buildCornerMarks(color: primaryRed, size: 14),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildPlatformBadge(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withOpacity(0.5), width: 1),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 9,
        fontFamily: 'Orbitron',
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
  );
}

// ═══ UTILITY CARD ═══
Widget _buildUtilityCard() {
  return Padding(
    padding: const EdgeInsets.only(right: 20),
    child: GestureDetector(
      onTap: () => _showUtilityTools(context),
      child: ClipPath(
        clipper: const _ClippedCornerClipper(cut: 14),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: cardDark,
            border: Border.all(color: primaryRed, width: 1.8),
            boxShadow: [
              BoxShadow(color: primaryRed.withOpacity(0.15), blurRadius: 12),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primaryRed.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryRed, width: 1.5),
                      ),
                      child: Icon(Icons.build, color: primaryRed, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "UTILS",
                      style: TextStyle(
                        color: primaryWhite,
                        fontSize: 12,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "3 Tools",
                      style: TextStyle(
                        color: accentGrey.withOpacity(0.6),
                        fontSize: 9,
                        fontFamily: 'ShareTechMono',
                      ),
                    ),
                  ],
                ),
              ),
              _buildCornerMarks(color: primaryRed, size: 14),
            ],
          ),
        ),
      ),
    ),
  );
}
  // ═══ QUICK ACCESS ═══
  Widget _buildQuickAccess() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              "QUICK ACCESS",
              style: TextStyle(
                color: accentGrey.withOpacity(0.6),
                fontSize: 9,
                fontFamily: 'ShareTechMono',
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildQuickPill(Icons.verified_user, "Cek Ban WA", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CekBanWaPage(sessionKey: widget.sessionKey),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                _buildQuickPill(Icons.flash_on, "DDoS",
                    () => _showDDoSTools(context)),
                const SizedBox(width: 8),
                _buildQuickPill(Icons.wifi, "Network",
                    () => _showNetworkTools(context)),
                const SizedBox(width: 8),
                _buildQuickPill(Icons.search, "OSINT",
                    () => _showOSINTTools(context)),
                const SizedBox(width: 8),
                _buildQuickPill(Icons.download, "Download",
                    () => _showDownloaderTools(context)),
                const SizedBox(width: 8),
                _buildQuickPill(Icons.build, "Utils",
                    () => _showUtilityTools(context)),
                const SizedBox(width: 8),
                _buildQuickPill(Icons.qr_code, "QR Gen", () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const QrGeneratorPage()));
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPill(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: primaryRed, width: 1.2),
          boxShadow: [
            BoxShadow(color: primaryRed.withOpacity(0.2), blurRadius: 8),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primaryRed, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: primaryWhite,
                fontSize: 10,
                fontFamily: 'ShareTechMono',
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══ GENERIC CLIPPED CARD ═══
  Widget _buildClippedCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int toolCount,
    required Color accentColor,
    required VoidCallback onTap,
    required double cut,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: ClipPath(
          clipper: _ClippedCornerClipper(cut: cut),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: cardDark,
              border: Border.all(color: primaryRed, width: 1.8),
              boxShadow: [
                BoxShadow(color: primaryRed.withOpacity(0.15), blurRadius: 12),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: primaryRed.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryRed, width: 1.5),
                        ),
                        child: Icon(icon, color: accentColor, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: TextStyle(
                          color: primaryWhite,
                          fontSize: 13,
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: accentGrey.withOpacity(0.7),
                              fontSize: 10,
                              fontFamily: 'ShareTechMono',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "$toolCount",
                            style: TextStyle(
                              color: primaryRed,
                              fontSize: 9,
                              fontFamily: 'ShareTechMono',
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Icon(Icons.chevron_right,
                        color: accentGrey.withOpacity(0.4), size: 22),
                  ),
                ),
                _buildCornerMarks(color: primaryRed, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCornerMarks({required Color color, required double size}) {
    final markSize = size * 0.4;
    final linePaint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    return CustomPaint(
      size: Size(double.infinity, double.infinity),
      painter: _CornerMarkPainter(
        markSize: markSize,
        linePaint: linePaint,
      ),
    );
  }

  Widget _animateEntry(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + index * 120),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // ═══ CATEGORY SHEET ═══
  void _showCategorySheet(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<_ToolItem> tools,
  }) {
    final sheetHeight = tools.length <= 2
        ? 0.38
        : tools.length == 3
            ? 0.5
            : 0.6;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * sheetHeight,
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
          border: Border.all(color: primaryRed, width: 2),
          boxShadow: [
            BoxShadow(
              color: primaryRed.withOpacity(0.3),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: ClipPath(
          clipper: const _ClippedCornerClipper(cut: 20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: primaryRed.withOpacity(0.12),
                  border: Border(
                    bottom: BorderSide(color: primaryRed, width: 1.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: primaryRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: primaryRed, width: 1.5),
                      ),
                      child: Icon(icon, color: primaryRed, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          color: primaryWhite,
                          fontSize: 15,
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(color: primaryRed.withOpacity(0.6), blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryRed.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: primaryRed, width: 1.5),
                        ),
                        child: Icon(Icons.close, color: primaryRed, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                color: primaryRed.withOpacity(0.05),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, _) {
                        return Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryRed
                                .withOpacity(0.5 + _pulseCtrl.value * 0.5),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "SECURE CONNECTION ESTABLISHED",
                      style: TextStyle(
                        color: accentGrey.withOpacity(0.5),
                        fontSize: 8,
                        fontFamily: 'ShareTechMono',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${tools.length} MODULES",
                      style: TextStyle(
                        color: accentGrey.withOpacity(0.5),
                        fontSize: 8,
                        fontFamily: 'ShareTechMono',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: tools.length <= 2 ? 2.5 : 1.6,
                    physics: const NeverScrollableScrollPhysics(),
                    children: tools.map((t) => _buildSheetButton(t)).toList(),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: primaryRed, width: 1.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    "SYS.CLOSE",
                    style: TextStyle(
                      color: accentGrey.withOpacity(0.4),
                      fontSize: 8,
                      fontFamily: 'ShareTechMono',
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
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

  Widget _buildSheetButton(_ToolItem item) {
    return GestureDetector(
      onTap: item.locked ? () => _showComingSoon(context) : item.onTap,
      child: ClipPath(
        clipper: const _ClippedCornerClipper(cut: 10),
        child: Container(
          decoration: BoxDecoration(
            color: item.locked ? primaryRed.withOpacity(0.05) : cardDark,
            border: Border.all(
              color: item.locked ? primaryRed.withOpacity(0.3) : primaryRed,
              width: 1.8,
            ),
            boxShadow: item.locked
                ? null
                : [
                    BoxShadow(
                      color: primaryRed.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: item.locked
                            ? primaryRed.withOpacity(0.08)
                            : primaryRed.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: item.locked
                              ? primaryRed.withOpacity(0.3)
                              : primaryRed,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        item.locked ? Icons.lock_outline : item.icon,
                        color: item.locked
                            ? accentGrey.withOpacity(0.4)
                            : primaryRed,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: item.locked
                            ? accentGrey.withOpacity(0.4)
                            : primaryWhite,
                        fontSize: 10,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        height: 1.3,
                      ),
                    ),
                    if (item.locked) ...[
                      const SizedBox(height: 4),
                      Text(
                        "SOON",
                        style: TextStyle(
                          color: accentGrey.withOpacity(0.4),
                          fontSize: 7,
                          fontFamily: 'ShareTechMono',
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!item.locked) _buildCornerMarks(color: primaryRed, size: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ═══ CATEGORY METHODS ═══
  void _showDDoSTools(BuildContext context) {
    _showCategorySheet(
      context,
      title: "DDoS Tools",
      icon: Icons.flash_on,
      tools: [
        _ToolItem(
          icon: Icons.flash_on,
          label: "Attack\nPanel",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AttackPanel(
                  sessionKey: widget.sessionKey,
                  listDoos: widget.listDoos,
                ),
              ),
            );
          },
        ),
        _ToolItem(
          icon: Icons.dns,
          label: "Manage\nServer",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ManageServerPage(keyToken: widget.sessionKey),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showNetworkTools(BuildContext context) {
    final tools = <_ToolItem>[
      _ToolItem(
        icon: Icons.verified_user_rounded,
        label: "Cek Ban\nWhatsApp",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CekBanWaPage(sessionKey: widget.sessionKey),
            ),
          );
        },
      ),
      _ToolItem(
        icon: Icons.newspaper_outlined,
        label: "Spam\nNGL",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const NglPage()));
        },
      ),
      _ToolItem(
        icon: Icons.wifi_off,
        label: "WiFi Killer\n(Internal)",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const WifiKillerPage()));
        },
      ),
      if (widget.userRole == "vip" || widget.userRole == "owner")
        _ToolItem(
          icon: Icons.router,
          label: "WiFi Killer\n(External)",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WifiInternalPage(sessionKey: widget.sessionKey),
              ),
            );
          },
        ),
    ];
    _showCategorySheet(
      context,
      title: "Network Tools",
      icon: Icons.wifi,
      tools: tools,
    );
  }

  
  void _showOSINTTools(BuildContext context) {
    _showCategorySheet(
      context,
      title: "OSINT Tools",
      icon: Icons.search,
      tools: [
        _ToolItem(
          icon: Icons.badge,
          label: "NIK\nDetail",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NikCheckerPage()));
          },
        ),
        _ToolItem(
          icon: Icons.domain,
          label: "Domain\nOSINT",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DomainOsintPage()));
          },
        ),
        _ToolItem(
          icon: Icons.person_search,
          label: "Phone\nLookup",
          locked: true,
          onTap: () {},
        ),
        _ToolItem(
          icon: Icons.email,
          label: "Email\nOSINT",
          locked: true,
          onTap: () {},
        ),
      ],
    );
  }

  void _showDownloaderTools(BuildContext context) {
    _showCategorySheet(
      context,
      title: "Media Downloader",
      icon: Icons.download,
      tools: [
        _ToolItem(
          icon: Icons.video_library,
          label: "TikTok\nDownloader",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TiktokDownloaderPage()));
          },
        ),
        _ToolItem(
          icon: Icons.camera_alt,
          label: "Instagram\nDownloader",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const InstagramDownloaderPage()));
          },
        ),
      ],
    );
  }

  void _showUtilityTools(BuildContext context) {
    _showCategorySheet(
      context,
      title: "Utility Tools",
      icon: Icons.build,
      tools: [
        _ToolItem(
          icon: Icons.qr_code,
          label: "QR\nGenerator",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const QrGeneratorPage()));
          },
        ),
        _ToolItem(
          icon: Icons.security,
          label: "IP\nScanner",
          locked: true,
          onTap: () {},
        ),
        _ToolItem(
          icon: Icons.network_check,
          label: "Port\nScanner",
          locked: true,
          onTap: () {},
        ),
      ],
    );
  }

  void _showQuickAccess(BuildContext context) {
    _showComingSoon(context);
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.hourglass_top, color: primaryRed),
            const SizedBox(width: 8),
            Text(
              'Feature Coming Soon!',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
                color: primaryWhite,
              ),
            ),
          ],
        ),
        backgroundColor: cardDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: primaryRed, width: 1.5),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ═══ CORNER MARK PAINTER ═══
class _CornerMarkPainter extends CustomPainter {
  final double markSize;
  final Paint linePaint;

  _CornerMarkPainter({
    required this.markSize,
    required this.linePaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = markSize;

    canvas.drawLine(const Offset(2, 2), Offset(2 + s, 2), linePaint);
    canvas.drawLine(const Offset(2, 2), Offset(2, 2 + s), linePaint);

    canvas.drawLine(
      Offset(size.width - 2 - s, 2),
      Offset(size.width - 2, 2),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width - 2, 2),
      Offset(size.width - 2, 2 + s),
      linePaint,
    );

    canvas.drawLine(
      Offset(2, size.height - 2),
      Offset(2 + s, size.height - 2),
      linePaint,
    );
    canvas.drawLine(
      Offset(2, size.height - 2 - s),
      Offset(2, size.height - 2),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width - 2 - s, size.height - 2),
      Offset(size.width - 2, size.height - 2),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width - 2, size.height - 2 - s),
      Offset(size.width - 2, size.height - 2),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerMarkPainter oldDelegate) {
    return markSize != oldDelegate.markSize ||
        linePaint.color != oldDelegate.linePaint.color ||
        linePaint.strokeWidth != oldDelegate.linePaint.strokeWidth;
  }
}
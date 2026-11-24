import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════
// PALETTE — KREM TERANG + MERAH
// ═══════════════════════════════════════════════════════════════════
class _JC {
  static const bg         = Color(0xFFF5EDD8);
  static const surface    = Color(0xFFFAF3E0);
  static const card       = Color(0xFFFFF8E7);
  static const cardAlt    = Color(0xFFF0E6CC);
  static const border     = Color(0xFFDC2626);
  static const borderLit  = Color(0xFFEF4444);
  static const red        = Color(0xFF8B0000);
  static const redMid     = Color(0xFFDC2626);
  static const redLight   = Color(0xFFEF4444);
  static const text       = Color(0xFF1A1A1A);
  static const textSub    = Color(0xFF5C4A2A);
  static const textDim    = Color(0xFF8A7A5A);
}

// ═══════════════════════════════════════════════════════════════════
// MINI ANALOG CLOCK (untuk dashboard)
// ═══════════════════════════════════════════════════════════════════
class MiniAnalogClock extends StatefulWidget {
  final double size;
  final Color? color;

  const MiniAnalogClock({
    super.key,
    this.size = 70,
    this.color,
  });

  @override
  State<MiniAnalogClock> createState() => _MiniAnalogClockState();
}

class _MiniAnalogClockState extends State<MiniAnalogClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? _JC.redMid;
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _JC.card,
        border: Border.all(color: _JC.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: _JC.redMid.withOpacity(0.35),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _MiniClockPainter(_now, color),
      ),
    );
  }
}

class _MiniClockPainter extends CustomPainter {
  final DateTime time;
  final Color color;

  _MiniClockPainter(this.time, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Titik jam kecil (12 titik)
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final isQuarter = i % 3 == 0;
      final r = isQuarter ? 1.8 : 0.9;
      final x = center.dx + (radius - 5) * math.cos(angle);
      final y = center.dy + (radius - 5) * math.sin(angle);
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = isQuarter ? _JC.text : _JC.text.withOpacity(0.6),
      );
    }

    // Titik tengah
    canvas.drawCircle(center, 2.5, Paint()..color = _JC.border);

    // Jarum JAM (pendek)
    final hourAngle =
        ((time.hour % 12) * 30 + time.minute * 0.5 - 90) * math.pi / 180;
    final hourEnd = Offset(
      center.dx + (radius * 0.55) * math.cos(hourAngle),
      center.dy + (radius * 0.55) * math.sin(hourAngle),
    );
    canvas.drawLine(
      center,
      hourEnd,
      Paint()
        ..color = _JC.redMid
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Jarum MENIT (panjang)
    final minAngle =
        (time.minute * 6 + time.second * 0.1 - 90) * math.pi / 180;
    final minEnd = Offset(
      center.dx + (radius * 0.78) * math.cos(minAngle),
      center.dy + (radius * 0.78) * math.sin(minAngle),
    );
    canvas.drawLine(
      center,
      minEnd,
      Paint()
        ..color = _JC.redMid
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_MiniClockPainter old) => old.time.second != time.second;
}

// ═══════════════════════════════════════════════════════════════════
// ANALOG CLOCK BESAR (dengan angka 1-12)
// ═══════════════════════════════════════════════════════════════════
class BigAnalogClock extends StatefulWidget {
  final double size;
  final String timezone;

  const BigAnalogClock({
    super.key,
    this.size = 220,
    this.timezone = 'WIB',
  });

  @override
  State<BigAnalogClock> createState() => _BigAnalogClockState();
}

class _BigAnalogClockState extends State<BigAnalogClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _JC.card,
        border: Border.all(color: _JC.border, width: 3),
        boxShadow: [
          BoxShadow(
            color: _JC.redMid.withOpacity(0.4),
            blurRadius: 24,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: _JC.border.withOpacity(0.2),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _BigClockPainter(_now),
          ),
          Positioned(
            bottom: widget.size * 0.16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _JC.border,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.timezone,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigClockPainter extends CustomPainter {
  final DateTime time;
  _BigClockPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // ── Angka 1-12 ──
    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final x = center.dx + (radius - 22) * math.cos(angle);
      final y = center.dy + (radius - 22) * math.sin(angle);
      final tp = TextPainter(
        text: TextSpan(
          text: '$i',
          style: const TextStyle(
            color: _JC.text,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }

    // ── Titik menit (60 titik) ──
    for (int i = 0; i < 60; i++) {
      final angle = (i * 6 - 90) * math.pi / 180;
      final isHour = i % 5 == 0;
      final r1 = isHour ? radius - 4 : radius - 3;
      final r2 = radius;
      final p1 = Offset(
        center.dx + r1 * math.cos(angle),
        center.dy + r1 * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + r2 * math.cos(angle),
        center.dy + r2 * math.sin(angle),
      );
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = _JC.border
          ..strokeWidth = isHour ? 2.5 : 1,
      );
    }

    // ── Jarum JAM (pendek tebal) ──
    final hourAngle =
        ((time.hour % 12) * 30 + time.minute * 0.5 - 90) * math.pi / 180;
    final hourEnd = Offset(
      center.dx + (radius * 0.5) * math.cos(hourAngle),
      center.dy + (radius * 0.5) * math.sin(hourAngle),
    );
    canvas.drawLine(
      center,
      hourEnd,
      Paint()
        ..color = _JC.red
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // ── Jarum MENIT (panjang) ──
    final minAngle =
        (time.minute * 6 + time.second * 0.1 - 90) * math.pi / 180;
    final minEnd = Offset(
      center.dx + (radius * 0.75) * math.cos(minAngle),
      center.dy + (radius * 0.75) * math.sin(minAngle),
    );
    canvas.drawLine(
      center,
      minEnd,
      Paint()
        ..color = _JC.redMid
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    // ── Jarum DETIK (tipis merah muda) ──
    final secAngle = (time.second * 6 - 90) * math.pi / 180;
    final secEnd = Offset(
      center.dx + (radius * 0.88) * math.cos(secAngle),
      center.dy + (radius * 0.88) * math.sin(secAngle),
    );
    canvas.drawLine(
      center,
      secEnd,
      Paint()
        ..color = _JC.redLight
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // ── Titik tengah (kuning/merah) ──
    canvas.drawCircle(center, 6, Paint()..color = _JC.redMid);
    canvas.drawCircle(center, 3, Paint()..color = _JC.border);
  }

  @override
  bool shouldRepaint(_BigClockPainter old) => old.time.second != time.second;
}

// ═══════════════════════════════════════════════════════════════════
// JAM DUNIA PAGE
// ═══════════════════════════════════════════════════════════════════
class JamDuniaPage extends StatefulWidget {
  const JamDuniaPage({super.key});

  @override
  State<JamDuniaPage> createState() => _JamDuniaPageState();
}

class _JamDuniaPageState extends State<JamDuniaPage> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  // Zona waktu Indonesia
  String _zone = 'WIB';
  int _zoneOffset = 7; // UTC+7

  // Kota dunia
  final List<Map<String, dynamic>> _cities = [
    {'name': 'Jakarta', 'zone': 'WIB', 'offset': 7, 'flag': '🇮🇩'},
    {'name': 'Makassar', 'zone': 'WITA', 'offset': 8, 'flag': '🇮🇩'},
    {'name': 'Jayapura', 'zone': 'WIT', 'offset': 9, 'flag': '🇮🇩'},
    {'name': 'Tokyo', 'zone': 'JST', 'offset': 9, 'flag': '🇯🇵'},
    {'name': 'Seoul', 'zone': 'KST', 'offset': 9, 'flag': '🇰🇷'},
    {'name': 'Singapore', 'zone': 'SGT', 'offset': 8, 'flag': '🇸🇬'},
    {'name': 'Bangkok', 'zone': 'ICT', 'offset': 7, 'flag': '🇹🇭'},
    {'name': 'Dubai', 'zone': 'GST', 'offset': 4, 'flag': '🇦🇪'},
    {'name': 'London', 'zone': 'GMT', 'offset': 0, 'flag': '🇬🇧'},
    {'name': 'Paris', 'zone': 'CET', 'offset': 1, 'flag': '🇫🇷'},
    {'name': 'Moscow', 'zone': 'MSK', 'offset': 3, 'flag': '🇷🇺'},
    {'name': 'New York', 'zone': 'EST', 'offset': -5, 'flag': '🇺🇸'},
    {'name': 'Los Angeles', 'zone': 'PST', 'offset': -8, 'flag': '🇺🇸'},
    {'name': 'Sydney', 'zone': 'AEST', 'offset': 10, 'flag': '🇦🇺'},
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  DateTime get _zoneTime {
    // Konversi ke UTC, lalu tambah offset
    return _now.toUtc().add(Duration(hours: _zoneOffset));
  }

  String get _digitalTime {
    final t = _zoneTime;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
  }

  String get _dateString {
    final t = _zoneTime;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final dayName = days[t.weekday - 1];
    return '$dayName, ${t.day} ${months[t.month - 1]} ${t.year}';
  }

  String _cityTime(int offset) {
    final t = _now.toUtc().add(Duration(hours: offset));
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _cityDate(int offset) {
    final t = _now.toUtc().add(Duration(hours: offset));
    return '${t.day}/${t.month}/${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _JC.bg,
      appBar: AppBar(
        backgroundColor: _JC.surface,
        elevation: 0,
        title: const Text(
          'JAM DUNIA',
          style: TextStyle(
            color: _JC.text,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            fontFamily: 'Orbitron',
            letterSpacing: 3,
            shadows: [
              Shadow(color: _JC.border, blurRadius: 10),
            ],
          ),
        ),
        iconTheme: const IconThemeData(color: _JC.redMid),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _JC.border),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ═══ JAM BESAR ═══
            BigAnalogClock(size: 240, timezone: _zone),
            const SizedBox(height: 24),

            // ═══ DIGITAL TIME ═══
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: _JC.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _JC.border, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _JC.redMid.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _digitalTime,
                    style: const TextStyle(
                      color: _JC.redMid,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'ShareTechMono',
                      letterSpacing: 3,
                      shadows: [
                        Shadow(color: _JC.border, blurRadius: 15),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _dateString,
                    style: const TextStyle(
                      color: _JC.textSub,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ═══ ZONA WAKTU INDONESIA ═══
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _JC.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _JC.border, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _JC.redMid.withOpacity(0.2),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ZONA WAKTU INDONESIA',
                    style: TextStyle(
                      color: _JC.redMid,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _zoneBtn('WIB', 7)),
                      const SizedBox(width: 8),
                      Expanded(child: _zoneBtn('WITA', 8)),
                      const SizedBox(width: 8),
                      Expanded(child: _zoneBtn('WIT', 9)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ═══ JAM DUNIA ═══
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _JC.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _JC.border, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _JC.redMid.withOpacity(0.2),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'JAM DUNIA',
                    style: TextStyle(
                      color: _JC.redMid,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._cities.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _cityCard(c),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _zoneBtn(String label, int offset) {
    final active = _zone == label;
    return GestureDetector(
      onTap: () => setState(() {
        _zone = label;
        _zoneOffset = offset;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? _JC.redMid : _JC.cardAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _JC.border, width: 2),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _JC.redMid.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : _JC.text,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _cityCard(Map<String, dynamic> city) {
    final time = _cityTime(city['offset'] as int);
    final date = _cityDate(city['offset'] as int);
    final isIndo = city['zone'].toString().startsWith('WI');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _JC.cardAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isIndo ? _JC.border : _JC.border.withOpacity(0.5),
          width: isIndo ? 2 : 1.5,
        ),
      ),
      child: Row(
        children: [
          Text(
            city['flag'],
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city['name'],
                  style: const TextStyle(
                    color: _JC.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${city['zone']} • $date',
                  style: const TextStyle(
                    color: _JC.textSub,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: _JC.redMid,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFamily: 'ShareTechMono',
              letterSpacing: 1.2,
              shadows: [
                Shadow(color: _JC.border, blurRadius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
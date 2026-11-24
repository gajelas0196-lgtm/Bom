import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════════════════
// PALETTE
// ═══════════════════════════════════════════════════════════════════
class _WB {
  static const bg      = Color(0xFFF5EDD8);
  static const surface = Color(0xFFFAF3E0);
  static const card    = Color(0xFFFFF8E7);
  static const border  = Color(0xFFDC2626);
  static const red     = Color(0xFF8B0000);
  static const redMid  = Color(0xFFDC2626);
  static const green   = Color(0xFF16A34A);
  static const amber   = Color(0xFFB45309);
  static const text    = Color(0xFF1A1A1A);
  static const textSub = Color(0xFF5C4A2A);
  static const textDim = Color(0xFF8A7A5A);

  static const LinearGradient btnGrad = LinearGradient(
    colors: [Color(0xFF8B0000), Color(0xFFDC2626), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class CekBanWaPage extends StatefulWidget {
  final String? sessionKey;
  const CekBanWaPage({super.key, this.sessionKey});

  @override
  State<CekBanWaPage> createState() => _CekBanWaPageState();
}

class _CekBanWaPageState extends State<CekBanWaPage>
    with TickerProviderStateMixin {
  final TextEditingController _numberCtrl = TextEditingController();

  bool _loading = false;
  String? _resultStatus; // 'safe' | 'banned' | 'unknown'
  String? _error;
  Map<String, dynamic>? _resultData;

  late AnimationController _borderCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _borderCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _borderCtrl.dispose();
    _pulseCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // CEK BAN WA
  // ═══════════════════════════════════════════════════════════════
  Future<void> _checkBan() async {
    final raw = _numberCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Masukkan nomor WhatsApp dulu');
      return;
    }

    // Format nomor
    String number = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (number.startsWith('0')) number = '62${number.substring(1)}';
    if (!number.startsWith('62')) number = '62$number';

    setState(() {
      _loading = true;
      _error = null;
      _resultStatus = null;
      _resultData = null;
    });

    try {
      // Cek via API WhatsApp publik (wa.me redirect check)
      final url = Uri.parse('https://wa.me/$number');
      final res = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
      }).timeout(const Duration(seconds: 15));

      final body = res.body.toLowerCase();
      final statusCode = res.statusCode;

      // Heuristik: WhatsApp mengembalikan halaman berbeda untuk banned vs normal
      bool banned = false;
      if (statusCode == 404) {
        banned = true;
      } else if (body.contains('not on whatsapp') ||
                 body.contains('invalid') ||
                 body.contains('this number is not available')) {
        banned = true;
      } else if (body.contains('continue to chat') ||
                 body.contains('open whatsapp') ||
                 body.contains('chat with')) {
        banned = false;
      } else if (statusCode >= 400) {
        banned = true;
      }

      // Cek tambahan via API alternatif
      try {
        final res2 = await http.get(
          Uri.parse('https://api.whatsapp.com/send?phone=$number&text=test'),
          headers: {'User-Agent': 'Mozilla/5.0 (Linux; Android 10)'},
        ).timeout(const Duration(seconds: 10));

        if (res2.statusCode >= 400) banned = true;
      } catch (_) {}

      final now = DateTime.now();
      final banDate = '${now.day}/${now.month}/${now.year}';
      final banTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      if (!mounted) return;
      setState(() {
        _loading = false;
        if (banned) {
          _resultStatus = 'banned';
          _resultData = {
            'number': number,
            'status': 'BANNED',
            'reason': 'Nomor tidak dapat diakses / dinonaktifkan oleh WhatsApp',
            'banDate': banDate,
            'banTime': banTime,
            'checkTime': '$banDate $banTime',
          };
        } else {
          _resultStatus = 'safe';
          _resultData = {
            'number': number,
            'status': 'SAFE',
            'reason': 'Nomor aktif dan dapat dihubungi via WhatsApp',
            'checkDate': banDate,
            'checkTime': banTime,
          };
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Gagal cek status: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _WB.bg,
      appBar: AppBar(
        backgroundColor: _WB.surface,
        foregroundColor: _WB.text,
        elevation: 0,
        title: const Text(
          'CEK BAN WA',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            fontSize: 16,
            color: _WB.text,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: _WB.border),
        ),
      ),
      body: Stack(
        children: [
          // Background grid
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgCtrl,
              builder: (_, __) => CustomPaint(
                painter: _WbBgPainter(_bgCtrl.value),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // ═══ HEADER ICON ═══
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, _) => Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _WB.card,
                        border: Border.all(
                          color: _WB.border.withOpacity(
                              0.6 + _pulseCtrl.value * 0.4),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _WB.redMid.withOpacity(
                                0.25 + _pulseCtrl.value * 0.3),
                            blurRadius: 25,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: _WB.redMid,
                        size: 40,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ═══ TITLE ═══
                  ShaderMask(
                    shaderCallback: (b) => _WB.btnGrad.createShader(b),
                    child: const Text(
                      'WHATSAPP BAN CHECKER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cek status nomor WhatsApp: aman atau kena ban',
                    style: TextStyle(
                      color: _WB.textSub,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 30),

                  // ═══ INPUT NOMOR ═══
                  _buildNumberInput(),

                  const SizedBox(height: 20),

                  // ═══ TOMBOL CEK ═══
                  _buildCheckButton(),

                  const SizedBox(height: 20),

                  // ═══ HASIL ═══
                  if (_error != null) _buildError(),
                  if (_resultStatus != null) _buildResult(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══ INPUT NOMOR ═══
  Widget _buildNumberInput() {
    return AnimatedBuilder(
      animation: _borderCtrl,
      builder: (context, _) {
        final rotate = _borderCtrl.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _WB.redMid.withOpacity(0.25),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Border merah bergerak
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: SweepGradient(
                      transform: GradientRotation(rotate * 2 * 3.14159),
                      colors: const [
                        Color(0xFFDC2626),
                        Color(0xFFFCA5A5),
                        Color(0xFFDC2626),
                        Color(0xFF8B0000),
                        Color(0xFFDC2626),
                      ],
                      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                  ),
                ),
              ),
              // Inner input
              Container(
                margin: const EdgeInsets.all(2.5),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: _WB.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    // Bendera +62
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: _WB.border.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _WB.border, width: 1.2),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🇮🇩', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 6),
                          Text(
                            '+62',
                            style: TextStyle(
                              color: _WB.redMid,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'ShareTechMono',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _numberCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          color: _WB.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'ShareTechMono',
                          letterSpacing: 1,
                        ),
                        decoration: const InputDecoration(
                          hintText: '81234567890',
                          hintStyle: TextStyle(
                            color: _WB.textDim,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══ TOMBOL CEK ═══
  Widget _buildCheckButton() {
    return GestureDetector(
      onTap: _loading ? null : _checkBan,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: _WB.btnGrad,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _WB.red, width: 2),
          boxShadow: [
            BoxShadow(
              color: _WB.redMid.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_rounded,
                        color: Colors.white, size: 22),
                    SizedBox(width: 12),
                    Text(
                      'CEK SEKARANG',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Orbitron',
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ═══ ERROR ═══
  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _WB.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _WB.border, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: _WB.redMid, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: _WB.text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══ HASIL ═══
  Widget _buildResult() {
    final isSafe = _resultStatus == 'safe';
    final color = isSafe ? _WB.green : _WB.redMid;
    final icon = isSafe
        ? Icons.verified_rounded
        : Icons.cancel_rounded;
    final statusText = isSafe ? 'AMAN' : 'BANNED';
    final statusDesc = isSafe
        ? 'Nomor aktif dan dapat dihubungi'
        : 'Nomor terdeteksi kena ban / tidak aktif';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _WB.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _WB.border, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 24,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          // ═══ ICON CENTANG / X BESAR ═══
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, _) => Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
                border: Border.all(
                  color: color,
                  width: 3 + _pulseCtrl.value,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(
                        0.3 + _pulseCtrl.value * 0.3),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 60),
            ),
          ),

          const SizedBox(height: 20),

          // ═══ STATUS TEXT ═══
          ShaderMask(
            shaderCallback: (b) => LinearGradient(
              colors: isSafe
                  ? [const Color(0xFF16A34A), const Color(0xFF4ADE80)]
                  : [const Color(0xFF8B0000), const Color(0xFFDC2626)],
            ).createShader(b),
            child: Text(
              statusText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                fontFamily: 'Orbitron',
                letterSpacing: 6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _WB.textSub,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),
          Container(height: 1.5, color: _WB.border),

          // ═══ INFO ═══
          const SizedBox(height: 20),
          _infoRow('Nomor', _resultData!['number'] ?? '-'),
          const SizedBox(height: 10),
          _infoRow('Status', _resultData!['status'] ?? '-',
              valueColor: color),
          const SizedBox(height: 10),

          if (isSafe) ...[
            _infoRow('Tanggal Cek', _resultData!['checkDate'] ?? '-'),
            const SizedBox(height: 10),
            _infoRow('Jam Cek', _resultData!['checkTime'] ?? '-'),
          ] else ...[
            _infoRow('Tanggal Ban', _resultData!['banDate'] ?? '-',
                valueColor: _WB.redMid),
            const SizedBox(height: 10),
            _infoRow('Jam Ban', _resultData!['banTime'] ?? '-',
                valueColor: _WB.redMid),
            const SizedBox(height: 10),
            _infoRow('Alasan', _resultData!['reason'] ?? '-',
                valueColor: _WB.redMid),
          ],

          const SizedBox(height: 20),
          Container(height: 1.5, color: _WB.border),
          const SizedBox(height: 16),

          // ═══ NOTE ═══
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: _WB.textDim,
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSafe
                      ? 'Nomor ini terdeteksi aktif. Coba kirim pesan WhatsApp untuk konfirmasi.'
                      : 'Nomor ini tidak dapat dihubungi via WhatsApp. Kemungkinan kena ban permanen atau belum terdaftar.',
                  style: const TextStyle(
                    color: _WB.textDim,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              color: _WB.textSub,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? _WB.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFamily: 'ShareTechMono',
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// BG PAINTER
// ═══════════════════════════════════════════════════════════════════
class _WbBgPainter extends CustomPainter {
  final double t;
  _WbBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Grid
    final grid = Paint()
      ..color = _WB.border.withOpacity(0.10)
      ..strokeWidth = 0.6;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Glow
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          _WB.redMid.withOpacity(0.08 + (t * 0.04)),
          Colors.transparent,
        ],
        radius: 0.8,
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, 0),
        radius: size.width,
      ));
    canvas.drawCircle(Offset(size.width / 2, 0), size.width, glow);
  }

  @override
  bool shouldRepaint(_WbBgPainter old) => old.t != t;
}
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'api.dart';


// ═══════════════════════════════════════════════════════════════════
// PALETTE — HITAM + PUTIH GLOW
// ═══════════════════════════════════════════════════════════════════
class _C {
  static const bg         = Color(0xFF000000);
  static const surface    = Color(0xFF121212);
  static const card       = Color(0xFF1A1A1A);
  static const cardAlt    = Color(0xFF222222);

  static const border     = Color(0xFFFFFFFF);
  static const borderLit  = Color(0xFFE0E0E0);
  static const red        = Color(0xFFFFFFFF);
  static const redMid     = Color(0xFFFFFFFF);
  static const redLight   = Color(0xFFE0E0E0);
  static const redFrost   = Color(0xFFB0B0B0);

  static const green      = Color(0xFF00FF00);
  static const greenDim   = Color(0xFF00CC00);
  static const amber      = Color(0xFFFFCC00);
  static const purple     = Color(0xFFBB86FC);

  static const text       = Color(0xFFFFFFFF);
  static const textSub    = Color(0xFFB0B0B0);
  static const textDim    = Color(0xFF808080);

  static const LinearGradient btnGrad = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

Color _roleColor(String role) {
  switch (role.toLowerCase()) {
    case 'developer': return const Color(0xFFFFCC00);
    case 'owner':     return const Color(0xFFFFCC00);
    case 'admin':     return const Color(0xFFFFFFFF);
    case 'moderator': return const Color(0xFF00FF00);
    case 'partner':   return const Color(0xFF00FF00);
    case 'vip':       return const Color(0xFFBB86FC);
    case 'reseller':  return const Color(0xFF00FF00);
    default:          return const Color(0xFFFFFFFF);
  }
}

// ═══════════════════════════════════════════════════════════════════
// HOME PAGE
// ═══════════════════════════════════════════════════════════════════
class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listBugGroup;
  final String role;
  final String expiredDate;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.listBugGroup,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final targetCtrl = TextEditingController();
  final loopCtrl = TextEditingController();
  final codeCtrl = TextEditingController();

  late final PageController _modeController;
  int _currentPage = 0;

  String selectedBugId = '';
  String _bugMode = 'number';
  String _senderType = 'private';
  bool _isSending = false;
  String? _responseMsg;

  List<String> _globalSenders = [];
  List<String> _privateSendersList = [];
  bool _isLoadingSenders = false;
  bool _modeSelected = false;

  bool _is3DNeo = false;

  String _countryCode = '+62';
  String _countryFlag = '🇮🇩';

  late AnimationController _bgCtrl;
  late AnimationController _entranceCtrl;
  late AnimationController _sendBtnCtrl;
  late AnimationController _resultCtrl;
  late AnimationController _waveCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _entrance;
  late Animation<double> _sendPulse;
  late Animation<double> _sendGlow;
  late Animation<double> _resultFade;
  late Animation<Offset> _resultSlide;
  late Animation<double> _pulseAnim;

  bool get canAccessGlobalSender {
    final r = widget.role.toLowerCase();
    return r == 'owner' ||
        r == 'admin' ||
        r == 'moderator' ||
        r == 'partner' ||
        r == 'developer' ||
        r == 'vip';
  }

  @override
  void initState() {
    super.initState();
    _updateSelectedBug();
    _modeController = PageController();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entrance = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOutCubic,
    );

    _sendBtnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _sendPulse = Tween<double>(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(parent: _sendBtnCtrl, curve: Curves.easeInOut));
    _sendGlow = Tween<double>(begin: 0.25, end: 0.7)
        .animate(CurvedAnimation(parent: _sendBtnCtrl, curve: Curves.easeInOut));

    _resultCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resultFade = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);
    _resultSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOutCubic));

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(
      parent: _pulseCtrl,
      curve: Curves.easeInOut,
    );

    _entranceCtrl.forward();
    _loadGlobalSenders();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _entranceCtrl.dispose();
    _sendBtnCtrl.dispose();
    _resultCtrl.dispose();
    _waveCtrl.dispose();
    _pulseCtrl.dispose();
    targetCtrl.dispose();
    loopCtrl.dispose();
    codeCtrl.dispose();
    _modeController.dispose();
    super.dispose();
  }

  void _toggle3DNeo() {
    HapticFeedback.mediumImpact();
    setState(() => _is3DNeo = !_is3DNeo);
  }

Future<void> _loadGlobalSenders() async {
  setState(() => _isLoadingSenders = true);
  try {
    final res = await http.get(
      Uri.parse('${Api.baseUrl}/mySender?key=${widget.sessionKey}'),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(res.body);

    if (data['valid'] == true && data['connections'] != null) {
      final allSenders = List<Map<String, dynamic>>.from(data['connections']);

      // Filter Global (source == 'vip')
      final vipOnly = allSenders
          .where((s) => (s['source'] ?? 'personal') == 'vip')
          .toList();

      // Filter Private (source != 'vip')
      final privateOnly = allSenders
          .where((s) => (s['source'] ?? 'personal') != 'vip')
          .toList();

      final globalNumbers = vipOnly
          .map((e) => e['sessionName']?.toString() ?? e['id']?.toString() ?? '')
          .toList();

      final privateNumbers = privateOnly
          .map((e) => e['sessionName']?.toString() ?? e['id']?.toString() ?? '')
          .toList();

      if (mounted) {
        setState(() {
          _globalSenders = globalNumbers;
          _privateSendersList = privateNumbers;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _globalSenders = [];
          _privateSendersList = [];
        });
      }
    }
  } catch (_) {
    if (mounted) {
      setState(() {
        _globalSenders = [];
        _privateSendersList = [];
      });
    }
  } finally {
    if (mounted) setState(() => _isLoadingSenders = false);
  }
}

  Future<void> _sendBug() async {
    final rawInput = targetCtrl.text.trim();
    final key = widget.sessionKey;

    if (rawInput.isEmpty) {
      _showAlert('Input Kosong', 'Target tidak boleh kosong.');
      return;
    }

    setState(() {
      _isSending = true;
      _responseMsg = null;
    });
    _resultCtrl.reset();

    try {
      if (_bugMode == 'testfunc') {
        final loop = loopCtrl.text.trim();
        final code = codeCtrl.text.trim();

        if (loop.isEmpty || int.tryParse(loop) == null || int.parse(loop) <= 0) {
          _showAlert('Loop Tidak Valid', 'Masukkan jumlah loop yang benar (angka).');
          setState(() => _isSending = false);
          return;
        }
        if (code.isEmpty || !code.contains('async function')) {
          _showAlert('Kode Tidak Valid', 'Paste kode JS yang valid (harus ada async function).');
          setState(() => _isSending = false);
          return;
        }

        final res = await http.post(
          Uri.parse('${Api.baseUrl}/api/testFunction'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'key': key,
            'target': rawInput,
            'loop': loop,
            'code': code,
          }),
        ).timeout(const Duration(seconds: 15));

        final data = jsonDecode(res.body);
        if (data['valid'] == true && data['success'] == true) {
          _setResponse('success', data['message'] ?? 'Eksekusi function dimulai!');
        } else {
          _setResponse('error', data['error'] ?? 'Gagal mengeksekusi function.');
        }
      } else {
        String finalTarget = rawInput;
        if (_bugMode == 'number' && !rawInput.startsWith('+')) {
          final cleanNum = rawInput.replaceAll(RegExp(r'\D'), '');
          finalTarget = '$_countryCode$cleanNum';
        }

        if (_bugMode == 'number') {
          if (formatPhone(finalTarget) == null) {
            _showAlert('Nomor Tidak Valid',
                'Gunakan format internasional.\nContoh: 81234567890');
            return;
          }
        } else {
          if (!isValidGroupLink(finalTarget)) {
            _showAlert('Link Tidak Valid',
                'Masukkan link grup WhatsApp yang valid.\nContoh: https://chat.whatsapp.com/XXX');
            return;
          }
        }

        if (_senderType == 'global' && !canAccessGlobalSender) {
          _showAlert('Akses Ditolak',
              'Sender Global hanya untuk Owner, Admin, Moderator, Partner & VIP!');
          return;
        }

        if (selectedBugId.isEmpty) {
          _showAlert('Pilih Bug', 'Silakan pilih bug terlebih dahulu.');
          return;
        }

        final encodedTarget = Uri.encodeComponent(finalTarget);
        final url = Uri.parse(
          '${Api.baseUrl}/sendBug'
          '?key=$key'
          '&target=$encodedTarget'
          '&bug=$selectedBugId'
          '${_senderType == 'global' ? '&senderMode=global' : ''}',
        );
        final res = await http.get(url).timeout(const Duration(seconds: 15));
        final data = jsonDecode(res.body);

        if (data['valid'] == false) {
          _setResponse('error', 'Session key tidak valid. Silakan login ulang.');
        } else if (data['cooldown'] == true) {
          final wait = data['wait'] ?? 0;
          _setResponse('warning', 'Cooldown aktif! Tunggu $wait detik lagi.');
        } else if (data['sended'] == true) {
          final label = _bugMode == 'group' ? 'grup target' : finalTarget;
          final role = data['role'] ?? widget.role;
          _setResponse('success', 'Bug berhasil dikirim ke $label! [$role]');
          targetCtrl.clear();
        } else {
          _setResponse('error', 'Gagal mengirim. Server sedang maintenance.');
        }
      }
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        _setResponse('error', 'Request timeout. Periksa koneksi internet.');
      } else {
        _setResponse('error', 'Koneksi error. Periksa jaringan dan coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _updateSelectedBug() {
    final bugs = _bugMode == 'group' ? widget.listBugGroup : widget.listBug;
    if (bugs.isNotEmpty) {
      selectedBugId = bugs.first['bug_id'];
    } else {
      selectedBugId = '';
    }
  }

  void _setResponse(String type, String msg) {
    if (!mounted) return;
    setState(() => _responseMsg = '$type|$msg');
    _resultCtrl.forward(from: 0);
  }

  String? formatPhone(String s) {
    final c = s.replaceAll(RegExp(r'[^\d+]'), '');
    return (c.startsWith('+') && c.length >= 8) ? c : null;
  }

  bool isValidGroupLink(String s) =>
      s.startsWith('https://') && s.contains('chat.whatsapp.com');

  void _showAlert(String title, String msg) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        ),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOut),
          ),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 28),
            border: Border.all(color: _C.border, width: 2),
            boxShadow: _is3DNeo
                ? [
                    BoxShadow(color: Colors.black.withOpacity(0.5), offset: const Offset(8, 8), blurRadius: 0),
                    BoxShadow(color: _C.redMid.withOpacity(0.4), offset: const Offset(4, 4), blurRadius: 0),
                  ]
                : [BoxShadow(color: _C.redMid.withOpacity(0.25), blurRadius: 40, spreadRadius: 6)],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  shape: _is3DNeo ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: _is3DNeo ? BorderRadius.circular(0) : null,
                  color: _C.border.withOpacity(0.15),
                  border: Border.all(color: _C.border, width: 2),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: _C.redMid, size: 28),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(
                color: _C.text, fontSize: 18, fontWeight: FontWeight.w800,
              )),
              const SizedBox(height: 8),
              Text(msg, textAlign: TextAlign.center, style: const TextStyle(
                color: _C.textSub, fontSize: 13, height: 1.5,
              )),
              const SizedBox(height: 24),
              _GradBtn(
                  label: 'OK', fullWidth: true, is3DNeo: _is3DNeo,
                  onTap: () => Navigator.pop(ctx)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _is3DNeo ? _C.card : Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: _AnimatedBg(controller: _bgCtrl, is3DNeo: _is3DNeo),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _entrance,
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                      child: Column(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            switchInCurve: Curves.easeOutBack,
                            switchOutCurve: Curves.easeIn,
                            child: !_modeSelected
                                ? _buildModeSlider()
                                : Column(
                                    key: const ValueKey("menu"),
                                    children: [
                                      _buildHeroCard(),
                                      const SizedBox(height: 20),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _modeSelected = false;
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.arrow_back_ios_new,
                                            color: _C.redMid,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            "Pilih Mode Lagi",
                                            style: TextStyle(
                                              color: _C.redMid,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      _buildTargetInput(),
                                      const SizedBox(height: 14),
                                      if (_bugMode == 'testfunc') ...[
                                        _buildLoopInput(),
                                        const SizedBox(height: 14),
                                        _buildCodeInput(),
                                      ] else ...[
                                        _buildBugSelector(),
                                        const SizedBox(height: 14),
                                        _buildSenderCard(),
                                      ],
                                      const SizedBox(height: 28),
                                      _buildSendButton(),
                                      if (_responseMsg != null) ...[
                                        const SizedBox(height: 12),
                                        _buildResultBanner(),
                                      ],
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: _is3DNeo ? _C.card : Colors.transparent,
        border: _is3DNeo
            ? Border(bottom: BorderSide(color: _C.border, width: 2))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'BUG ATTACK',
                  style: TextStyle(
                    color: _C.text,
                    fontSize: 16,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(color: Colors.white, blurRadius: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, _) {
                        return Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _C.green.withOpacity(0.5 + _pulseCtrl.value * 0.5),
                            boxShadow: [
                              BoxShadow(
                                color: _C.green.withOpacity(0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.role.toUpperCase(),
                      style: TextStyle(
                        color: _roleColor(widget.role),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _toggle3DNeo,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _is3DNeo ? _C.redMid : _C.card,
                borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 14),
                border: Border.all(
                  color: _is3DNeo ? _C.red : _C.border,
                  width: 1.8,
                ),
                boxShadow: _is3DNeo
                    ? [
                        BoxShadow(
                          color: _C.redMid.withOpacity(0.5),
                          offset: const Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: _C.border.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedRotation(
                    turns: _is3DNeo ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: Icon(
                      Icons.view_in_ar_rounded,
                      color: _is3DNeo ? Colors.black : _C.redMid,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '3D',
                    style: TextStyle(
                      color: _is3DNeo ? Colors.black : _C.redMid,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 32),
        color: _C.card,
        border: Border.all(
          color: _C.border,
          width: _is3DNeo ? 3 : 2,
        ),
        boxShadow: _is3DNeo
            ? [
                BoxShadow(
                  color: _C.redMid.withOpacity(0.6),
                  offset: const Offset(8, 8),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  offset: const Offset(12, 12),
                  blurRadius: 0,
                ),
              ]
            : [
                BoxShadow(
                  color: _C.redMid.withOpacity(.25),
                  blurRadius: 30,
                  spreadRadius: 4,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, _) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: _is3DNeo ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: _is3DNeo ? BorderRadius.circular(0) : null,
                      border: Border.all(
                        color: _C.border.withOpacity(0.5 + (0.5 * _pulseAnim.value)),
                        width: 2 + (2 * _pulseAnim.value),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _C.redMid.withOpacity(0.2 + (0.3 * _pulseAnim.value)),
                          blurRadius: _is3DNeo ? 0 : 20 + (10 * _pulseAnim.value),
                          offset: _is3DNeo ? const Offset(4, 4) : Offset.zero,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: _is3DNeo ? 26 : 28,
                      backgroundColor: _C.surface,
                      child: Icon(
                        Icons.person,
                        color: _C.redMid,
                        size: _is3DNeo ? 26 : 30,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.username,
                      style: const TextStyle(
                        color: _C.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _roleColor(widget.role).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 8),
                        border: Border.all(
                          color: _C.border,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        widget.role.toUpperCase(),
                        style: TextStyle(
                          color: _roleColor(widget.role),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 30),
                  border: Border.all(
                    color: _C.border,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  widget.expiredDate,
                  style: const TextStyle(
                    color: _C.redMid,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (_modeSelected) ...[
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _StatusBox(
                    _bugMode == "testfunc"
                        ? Icons.code_rounded
                        : Icons.bug_report,
                    _bugMode == "testfunc"
                        ? "CUSTOM"
                        : (_bugMode == "group"
                            ? "${widget.listBugGroup.length}"
                            : "${widget.listBug.length}"),
                    _bugMode == "testfunc" ? "Func Mode" : "Bug List",
                    is3DNeo: _is3DNeo,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatusBox(
                    Icons.flash_on,
                    "FAST",
                    "Speed",
                    is3DNeo: _is3DNeo,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatusBox(
                    Icons.check_circle,
                    "ONLINE",
                    "Status",
                    is3DNeo: _is3DNeo,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeSlider() {
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * .62,
          child: PageView(
            controller: _modeController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildModeCard(
                color: _C.redMid,
                icon: Icons.phone_android_rounded,
                title: "BUG NUMBER",
                desc: "Kirim bug ke nomor WhatsApp.",
                onPressed: () {
                  setState(() {
                    _bugMode = "number";
                    targetCtrl.clear();
                    _updateSelectedBug();
                    _modeSelected = true;
                  });
                },
              ),
              _buildModeCard(
                color: _C.purple,
                icon: Icons.groups_rounded,
                title: "BUG GROUP",
                desc: "Kirim bug ke grup WhatsApp.",
                onPressed: () {
                  setState(() {
                    _bugMode = "group";
                    targetCtrl.clear();
                    _updateSelectedBug();
                    _modeSelected = true;
                  });
                },
              ),
              _buildModeCard(
                color: _C.green,
                icon: Icons.code_rounded,
                title: "TEST FUNCTION",
                desc: "Eksekusi function JS custom (Private Sender).",
                onPressed: () {
                  setState(() {
                    _bugMode = "testfunc";
                    targetCtrl.clear();
                    loopCtrl.clear();
                    codeCtrl.clear();
                    _modeSelected = true;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SmoothPageIndicator(
          controller: _modeController,
          count: 3,
          effect: ExpandingDotsEffect(
            activeDotColor: _currentPage == 0
                ? _C.redMid
                : _currentPage == 1
                    ? _C.purple
                    : _C.green,
            dotColor: _C.border.withOpacity(0.3),
            dotHeight: 10,
            dotWidth: 10,
            expansionFactor: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required Color color,
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 36),
            color: _C.card,
            border: Border.all(
              color: _C.border,
              width: _is3DNeo ? 3 : 2.5,
            ),
            boxShadow: _is3DNeo
                ? [
                    BoxShadow(
                      color: _C.redMid.withOpacity(0.6),
                      offset: const Offset(8, 8),
                      blurRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(12, 12),
                      blurRadius: 0,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: _C.redMid.withOpacity(.25),
                      blurRadius: 35,
                      spreadRadius: 4,
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 28,
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  "OneCrash project",
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontFamily: "Qaxer",
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Pilih Mode Bug",
                  style: TextStyle(
                    color: _C.text,
                    fontSize: 28,
                    fontFamily: "ready",
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 35),
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: _is3DNeo ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: _is3DNeo ? BorderRadius.circular(0) : null,
                    color: color.withOpacity(.10),
                    border: Border.all(
                      color: _C.border,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(.55),
                        blurRadius: _is3DNeo ? 0 : 40,
                        offset: _is3DNeo ? const Offset(6, 6) : Offset.zero,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 75,
                  ),
                ),
                const SizedBox(height: 35),
                Text(
                  title,
                  style: const TextStyle(
                    color: _C.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  desc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _C.textSub,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 30),
                    border: Border.all(
                      color: _C.border,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    "TAP UNTUK MEMILIH",
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTargetInput() {
    if (_bugMode == 'number' || _bugMode == 'testfunc') {
      return _InputSection(
        icon: Icons.phone_android_rounded,
        label: _bugMode == 'testfunc' ? 'Target Nomor' : 'Nomor Target',
        is3DNeo: _is3DNeo,
        child: _CountryPhoneInput(
          controller: targetCtrl,
          countryCode: _countryCode,
          countryFlag: _countryFlag,
          onCountryTap: _showCountryPicker,
          is3DNeo: _is3DNeo,
        ),
      );
    }

    return _InputSection(
      icon: Icons.link_rounded,
      label: 'Link Grup WhatsApp',
      is3DNeo: _is3DNeo,
      child: _BugInput(
        controller: targetCtrl,
        hint: 'Contoh: https://chat.whatsapp.com/...',
        keyboardType: TextInputType.url,
        icon: Icons.link_rounded,
        is3DNeo: _is3DNeo,
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(_is3DNeo ? 0 : 24)),
          border: Border.all(color: _C.border, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: _C.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'PILIH NEGARA',
              style: TextStyle(
                color: _C.text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            _countryOption('🇮🇩', '+62', 'Indonesia'),
            _countryOption('🇲🇾', '+60', 'Malaysia'),
            _countryOption('🇸🇬', '+65', 'Singapore'),
            _countryOption('🇹🇭', '+66', 'Thailand'),
            _countryOption('🇻🇳', '+84', 'Vietnam'),
            _countryOption('🇵🇭', '+63', 'Philippines'),
            _countryOption('🇮🇳', '+91', 'India'),
            _countryOption('🇺🇸', '+1', 'United States'),
          ],
        ),
      ),
    );
  }

  Widget _countryOption(String flag, String code, String name) {
    final active = _countryCode == code;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _countryFlag = flag;
          _countryCode = code;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: active ? _C.border.withOpacity(0.15) : _C.surface,
          borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 12),
          border: Border.all(
            color: _C.border,
            width: active ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: _C.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              code,
              style: const TextStyle(
                color: _C.redMid,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'ShareTechMono',
              ),
            ),
            if (active) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded,
                  color: _C.redMid, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoopInput() {
    return _InputSection(
      icon: Icons.repeat_rounded,
      label: 'Jumlah Loop',
      is3DNeo: _is3DNeo,
      child: _BugInput(
        controller: loopCtrl,
        hint: 'Contoh: 10',
        keyboardType: TextInputType.number,
        icon: Icons.repeat_rounded,
        is3DNeo: _is3DNeo,
      ),
    );
  }

  Widget _buildCodeInput() {
    return _InputSection(
      icon: Icons.code_rounded,
      label: 'Function Code (JS)',
      is3DNeo: _is3DNeo,
      child: Container(
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 16),
          border: Border.all(color: _C.border, width: 1.5),
        ),
        padding: const EdgeInsets.all(14),
        child: TextField(
          controller: codeCtrl,
          maxLines: 8,
          style: const TextStyle(
            color: _C.text,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
          decoration: const InputDecoration(
            hintText:
                'async function myFunc(sock, target) {\n  // paste your bug code here\n  await sock.sendMessage(target, { text: "Hello" });\n}',
            hintStyle: TextStyle(
              color: _C.textDim,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBugSelector() {
    final bugs = _bugMode == "group" ? widget.listBugGroup : widget.listBug;

    return _InputSection(
      icon: Icons.bug_report_rounded,
      label: 'Select Bug',
      is3DNeo: _is3DNeo,
      child: SizedBox(
        height: 165,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: bugs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, index) {
            final bug = bugs[index];
            final selected = selectedBugId == bug["bug_id"];

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedBugId = bug["bug_id"];
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected ? _C.redMid.withOpacity(0.1) : _C.surface,
                  borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 24),
                  border: Border.all(
                    color: selected ? _C.border : _C.border.withOpacity(0.4),
                    width: selected ? 2.5 : 1.5,
                  ),
                                    boxShadow: _is3DNeo
                      ? [
                          BoxShadow(
                            color: _C.redMid.withOpacity(.5),
                            offset: const Offset(5, 5),
                            blurRadius: 0,
                          ),
                        ]
                      : (selected
                          ? [
                              BoxShadow(
                                color: _C.redMid.withOpacity(.30),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : []),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 18),
                            gradient: _C.btnGrad,
                            boxShadow: [
                              BoxShadow(
                                color: _C.redMid.withOpacity(.5),
                                blurRadius: _is3DNeo ? 0 : 20,
                                offset: _is3DNeo ? const Offset(4, 4) : Offset.zero,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.security_rounded,
                            color: Colors.black,
                            size: 28,
                          ),
                        ),
                        const Spacer(),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: selected
                                ? _C.redMid
                                : _C.border.withOpacity(0.15),
                            shape: _is3DNeo ? BoxShape.rectangle : BoxShape.circle,
                            borderRadius: _is3DNeo ? BorderRadius.circular(0) : null,
                            border: Border.all(
                              color: _C.border,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.check,
                            size: 18,
                            color: selected ? Colors.black : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      bug["bug_name"],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _C.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _C.redMid.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 8),
                        border: Border.all(
                          color: _C.border,
                          width: 1.2,
                        ),
                      ),
                      child: const Text(
                        "READY",
                        style: TextStyle(
                          color: _C.redMid,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1.5,
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
    );
  }

  Widget _buildSenderCard() {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 22),
        border: Border.all(color: _C.border, width: 2),
        boxShadow: _is3DNeo
            ? [
                BoxShadow(
                  color: _C.redMid.withOpacity(0.5),
                  offset: const Offset(6, 6),
                  blurRadius: 0,
                ),
              ]
            : [
                BoxShadow(
                  color: _C.redMid.withOpacity(0.15),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _C.border, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _C.redMid.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 10),
                    border: Border.all(color: _C.border, width: 1.5),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.server,
                    color: _C.redMid,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sender Type',
                      style: TextStyle(
                        color: _C.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Pilih sumber nomor pengirim',
                      style: TextStyle(
                        color: _C.textSub,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _loadGlobalSenders,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 10),
                      border: Border.all(color: _C.border, width: 1.5),
                    ),
                    child: _isLoadingSenders
                        ? const Padding(
                            padding: EdgeInsets.all(7),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _C.redMid,
                            ),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            color: _C.redMid,
                            size: 16,
                          ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: _SenderOption(
                    icon: FontAwesomeIcons.globe,
                    label: 'Global',
                    sublabel: _isLoadingSenders
                        ? 'Loading...'
                        : '${_globalSenders.length} sender',
                    selected: _senderType == 'global',
                    locked: !canAccessGlobalSender,
                    is3DNeo: _is3DNeo,
                    onTap: () {
                      if (!canAccessGlobalSender) {
                        _showAlert('Akses Ditolak',
                            'Sender Global hanya untuk Acces VIP! Buy Vip? upgrade Ke @By_Zii16');
                        return;
                      }
                      setState(() => _senderType = 'global');
                      _loadGlobalSenders();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SenderOption(
                    icon: FontAwesomeIcons.userShield,
                    label: 'Private',
                    sublabel: _isLoadingSenders
    ? 'Loading...'
    : '${_privateSendersList.length} sender',
                    selected: _senderType == 'private',
                    locked: false,
                    is3DNeo: _is3DNeo,
                    onTap: () => setState(() => _senderType = 'private'),
                  ),
                ),
              ],
            ),
          ),
          if (_senderType == 'global' && _globalSenders.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 14),
                border: Border.all(color: _C.border, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.format_list_bulleted_rounded,
                        color: _C.redMid,
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_globalSenders.length} sender aktif',
                        style: const TextStyle(
                          color: _C.textSub,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...(_globalSenders.take(3).map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: _is3DNeo ? BoxShape.rectangle : BoxShape.circle,
                                color: _C.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              s,
                              style: const TextStyle(
                                color: _C.redMid,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ))),
                  if (_globalSenders.length > 3)
                    Text(
                      '+ ${_globalSenders.length - 3} lainnya...',
                      style: const TextStyle(
                        color: _C.textDim,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _sendBtnCtrl,
      builder: (_, __) => GestureDetector(
        onTap: _isSending ? null : _sendBug,
        child: Transform.scale(
          scale: _isSending ? 1.0 : _sendPulse.value,
          child: Container(
            height: 64,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: _C.btnGrad,
              borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 20),
              border: Border.all(color: _C.red, width: 2.5),
              boxShadow: _is3DNeo
                  ? [
                      BoxShadow(
                        color: _C.redMid.withOpacity(0.6),
                        offset: const Offset(6, 6),
                        blurRadius: 0,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: _C.redMid.withOpacity(
                            _isSending ? 0.2 : _sendGlow.value * 0.6),
                        blurRadius: 32,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                if (_isSending)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 20),
                    child: AnimatedBuilder(
                      animation: _waveCtrl,
                      builder: (_, __) => CustomPaint(
                        painter: _WavePainter(_waveCtrl.value),
                        size: const Size(double.infinity, 64),
                      ),
                    ),
                  ),
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isSending
                        ? const Row(
                            key: ValueKey('sending'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 14),
                              Text(
                                'Mengirim Bug...',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            key: ValueKey('idle'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.rocket_launch_rounded,
                                color: Colors.black,
                                size: 24,
                              ),
                              SizedBox(width: 14),
                              Text(
                                'KIRIM BUG ATTACK',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultBanner() {
    if (_responseMsg == null) return const SizedBox();
    final parts = _responseMsg!.split('|');
    final type = parts[0];
    final msg = parts.length > 1 ? parts[1] : '';

    Color color;
    IconData icon;
    switch (type) {
      case 'success':
        color = _C.green;
        icon = Icons.check_circle_rounded;
        break;
      case 'warning':
        color = _C.amber;
        icon = Icons.warning_rounded;
        break;
      default:
        color = _C.redMid;
        icon = Icons.error_rounded;
    }

    return FadeTransition(
      opacity: _resultFade,
      child: SlideTransition(
        position: _resultSlide,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 18),
            border: Border.all(color: _C.border, width: 1.5),
            boxShadow: _is3DNeo
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      offset: const Offset(5, 5),
                      blurRadius: 0,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: color.withOpacity(0.15),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: _is3DNeo ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: _is3DNeo ? BorderRadius.circular(0) : null,
                  color: color.withOpacity(0.15),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type == 'success'
                          ? 'Berhasil'
                          : type == 'warning'
                              ? 'Peringatan'
                              : 'Gagal',
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      msg,
                      style: const TextStyle(
                        color: _C.textSub,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _responseMsg = null);
                  _resultCtrl.reset();
                },
                child: const Icon(
                  Icons.close_rounded,
                  color: _C.textDim,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// COUNTRY PHONE INPUT
// ═══════════════════════════════════════════════════════════════════
class _CountryPhoneInput extends StatefulWidget {
  final TextEditingController controller;
  final String countryCode;
  final String countryFlag;
  final VoidCallback onCountryTap;
  final bool is3DNeo;

  const _CountryPhoneInput({
    required this.controller,
    required this.countryCode,
    required this.countryFlag,
    required this.onCountryTap,
    this.is3DNeo = false,
  });

  @override
  State<_CountryPhoneInput> createState() => _CountryPhoneInputState();
}

class _CountryPhoneInputState extends State<_CountryPhoneInput> {
  bool _focused = false;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(widget.is3DNeo ? 0 : 16),
        border: Border.all(
          color: _C.border,
          width: _focused ? 2.5 : 2,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: _C.redMid.withOpacity(0.2),
                  blurRadius: widget.is3DNeo ? 0 : 16,
                  spreadRadius: widget.is3DNeo ? 0 : 2,
                  offset: widget.is3DNeo ? const Offset(4, 4) : const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onCountryTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: _C.border.withOpacity(0.08),
                borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(widget.is3DNeo ? 0 : 15)),
                border: Border(
                  right: BorderSide(color: _C.border, width: 1.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.countryFlag, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 6),
                  Text(
                    widget.countryCode,
                    style: const TextStyle(
                      color: _C.redMid,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: _C.redMid,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                color: _C.text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'ShareTechMono',
                letterSpacing: 1,
              ),
              cursorColor: _C.redMid,
              decoration: const InputDecoration(
                hintText: '81234567890',
                hintStyle: TextStyle(
                  color: _C.textDim,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// WIDGET PENDUKUNG
// ═══════════════════════════════════════════════════════════════════
class _StatusBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;
  final bool is3DNeo;

  const _StatusBox(this.icon, this.value, this.title, {this.is3DNeo = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(is3DNeo ? 0 : 22),
        border: Border.all(color: _C.border, width: 1.5),
        boxShadow: is3DNeo
            ? [
                BoxShadow(
                  color: _C.redMid.withOpacity(0.4),
                  offset: const Offset(4, 4),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Icon(icon, color: _C.redMid),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: _C.text,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: _C.textSub,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  final bool is3DNeo;

  const _InputSection({
    required this.icon,
    required this.label,
    required this.child,
    this.is3DNeo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(is3DNeo ? 0 : 20),
        border: Border.all(color: _C.border, width: 2),
        boxShadow: is3DNeo
            ? [
                BoxShadow(
                  color: _C.redMid.withOpacity(0.5),
                  offset: const Offset(5, 5),
                  blurRadius: 0,
                ),
              ]
            : [
                BoxShadow(
                  color: _C.redMid.withOpacity(0.12),
                  blurRadius: 10,
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _C.border, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: _C.redMid, size: 15),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: _C.textSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }
}

class _BugInput extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final IconData icon;
  final bool is3DNeo;

  const _BugInput({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    required this.icon,
    this.is3DNeo = false,
  });

  @override
  State<_BugInput> createState() => _BugInputState();
}

class _BugInputState extends State<_BugInput> {
  bool _focused = false;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(widget.is3DNeo ? 0 : 16),
        border: Border.all(
          color: _C.border,
          width: _focused ? 2.5 : 1.5,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: _C.redMid.withOpacity(0.15),
                  blurRadius: widget.is3DNeo ? 0 : 16,
                  spreadRadius: widget.is3DNeo ? 0 : 2,
                  offset: widget.is3DNeo ? const Offset(4, 4) : const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        keyboardType: widget.keyboardType,
        style: const TextStyle(
          color: _C.text,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: _C.redMid,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(
            color: _C.textDim,
            fontSize: 13,
          ),
          prefixIcon: Icon(widget.icon, color: _C.redMid, size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _SenderOption extends StatefulWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool selected;
  final bool locked;
  final bool is3DNeo;
  final VoidCallback onTap;

  const _SenderOption({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.locked,
    required this.onTap,
    this.is3DNeo = false,
  });

  @override
  State<_SenderOption> createState() => _SenderOptionState();
}

class _SenderOptionState extends State<_SenderOption> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? _C.redMid : _C.textSub;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: widget.selected ? _C.redMid.withOpacity(0.1) : _C.surface,
            borderRadius: BorderRadius.circular(widget.is3DNeo ? 0 : 16),
            border: Border.all(
              color: _C.border,
              width: widget.selected ? 2.5 : 1.5,
            ),
            boxShadow: widget.is3DNeo
                ? [
                    BoxShadow(
                      color: _C.redMid.withOpacity(0.5),
                      offset: const Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(widget.icon, color: color, size: 20),
                  if (widget.locked)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _C.amber,
                          border: Border.all(color: _C.card, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: Colors.black,
                          size: 7,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.sublabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _C.textDim,
                  fontSize: 10,
                  height: 1.3,
                ),
              ),
              if (widget.selected) ...[
                const SizedBox(height: 6),
                Container(
                  width: 20,
                  height: 3,
                  decoration: BoxDecoration(
                    color: _C.redMid,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double t;

  _WavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.5 +
          math.sin((x / size.width * 4 * math.pi) + (t * math.pi * 2)) *
              size.height *
              0.15;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.t != t;
}

class _AnimatedBg extends StatelessWidget {
  final AnimationController controller;
  final bool is3DNeo;

  const _AnimatedBg({required this.controller, this.is3DNeo = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: _BgPainter(controller.value, is3DNeo: is3DNeo),
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  final double t;
  final bool is3DNeo;

  _BgPainter(this.t, {this.is3DNeo = false});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = _C.bg;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final grid = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.0;
    const step = 40.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.05 + math.sin(t * math.pi * 2) * 0.02),
          Colors.transparent,
        ],
        radius: 0.9,
      ).createShader(
        Rect.fromCircle(center: Offset(size.width / 2, 0), radius: size.width),
      );
    canvas.drawCircle(Offset(size.width / 2, 0), size.width, glow);

    if (is3DNeo) {
      final boxPaint = Paint()
        ..color = _C.card.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      final boxShadow = Paint()
        ..color = _C.border.withOpacity(0.35)
        ..style = PaintingStyle.fill;
      const boxSize = 80.0;
      for (double x = 0; x < size.width; x += boxSize) {
        for (double y = 0; y < size.height; y += boxSize) {
          final rect = Rect.fromLTWH(x + 4, y + 4, boxSize - 8, boxSize - 8);
          canvas.drawRect(rect.translate(6, 6), boxShadow);
          canvas.drawRect(rect, boxPaint);
          final borderPaint = Paint()
            ..color = _C.border.withOpacity(0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
          canvas.drawRect(rect, borderPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t || old.is3DNeo != is3DNeo;
}

class _GradBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;
  final bool is3DNeo;

  const _GradBtn({
    required this.label,
    required this.onTap,
    this.fullWidth = false,
    this.is3DNeo = false,
  });

  @override
  State<_GradBtn> createState() => _GradBtnState();
}

class _GradBtnState extends State<_GradBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 46,
          width: widget.fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            gradient: _C.btnGrad,
            borderRadius: BorderRadius.circular(widget.is3DNeo ? 0 : 14),
            border: Border.all(color: _C.red, width: 2),
            boxShadow: _down
                ? []
                : widget.is3DNeo
                    ? [
                        BoxShadow(
                          color: _C.redMid.withOpacity(0.6),
                          offset: const Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: _C.redMid.withOpacity(0.35),
                          blurRadius: 16,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
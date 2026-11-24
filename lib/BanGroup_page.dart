import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;
import 'api.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF040A06);
  static const surface   = Color(0xFF08120C);
  static const card      = Color(0xFF0B1810);
  static const border    = Color(0xFF163622);
  static const borderLit = Color(0xFF1F4F31);
  static const red       = Color(0xFF0B4D28);
  static const redMid    = Color(0xFF14713C);
  static const redLight  = Color(0xFF1C9A50);
  static const redFrost  = Color(0xFF5CE89A);
  static const green     = Color(0xFF22C55E);
  static const greenDim  = Color(0xFF16A34A);
  static const amber     = Color(0xFFF59E0B);
  static const text      = Color(0xFFEAFBF0);
  static const textSub   = Color(0xFF8ED4AA);
  static const textDim   = Color(0xFF4C8762);
  static const warning   = Color(0xFFF97316);

  static const LinearGradient btnGrad = LinearGradient(
    colors: [Color(0xFF0B4D28), Color(0xFF14713C), Color(0xFF1C9A50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

Color _roleColor(String role) {
  switch (role.toLowerCase()) {
    case 'developer':    return const Color(0xFFF59E0B);
    case 'owner':    return const Color(0xFFF59E0B);
    case 'admin':    return const Color(0xFFEF4444);
    case 'moderator': return const Color(0xFF22C55E);
    case 'partner':  return const Color(0xFF000000);
    case 'vip':      return const Color(0xFF000000);
    case 'reseller': return const Color(0xFF22C55E);
    default:         return _C.redLight;
  }
}

class BanGroupPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listBugGroup;
  final String role;
  final String expiredDate;

  const BanGroupPage({
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
  State<BanGroupPage> createState() => _BanGroupPageState();
}

class _BanGroupPageState extends State<BanGroupPage> with TickerProviderStateMixin {
  final targetCtrl = TextEditingController();
  String selectedBugId = '';
  String _senderType = 'private';
  bool _isSending = false;
  String? _responseMsg;
  List<String> _globalSenders = [];
  bool _isLoadingSenders = false;

  late AnimationController _bgCtrl;
  late AnimationController _entranceCtrl;
  late AnimationController _sendBtnCtrl;
  late AnimationController _resultCtrl;
  late AnimationController _waveCtrl;
  late Animation<double> _entrance;
  late Animation<double> _sendPulse;
  late Animation<double> _sendGlow;
  late Animation<double> _resultFade;
  late Animation<Offset> _resultSlide;

  bool get canAccessGlobalSender {
    final r = widget.role.toLowerCase();
    return r == 'developer' || r == 'owner' || r == 'admin' || r == 'moderator' || r == 'partner' || r == 'vip';
  }

  @override
  void initState() {
    super.initState();
    // AMBIL BUG PERTAMA DARI listBugGroup (GCBAN)
    if (widget.listBugGroup.isNotEmpty) {
      selectedBugId = "gcban";
    }
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _entrance = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic);
    _sendBtnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _sendPulse = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _sendBtnCtrl, curve: Curves.easeInOut));
    _sendGlow = Tween<double>(begin: 0.25, end: 0.65).animate(CurvedAnimation(parent: _sendBtnCtrl, curve: Curves.easeInOut));
    _resultCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _resultFade = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);
    _resultSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOutCubic));
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
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
    targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGlobalSenders() async {
    setState(() => _isLoadingSenders = true);
    try {
      final res = await http.get(Uri.parse('${Api.baseUrl}/getActiveSenders?key=${widget.sessionKey}')).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['senders'] != null) {
        if (mounted) setState(() => _globalSenders = List<String>.from(data['senders']));
      } else {
        if (mounted) setState(() => _globalSenders = []);
      }
    } catch (_) {
      if (mounted) setState(() => _globalSenders = []);
    } finally {
      if (mounted) setState(() => _isLoadingSenders = false);
    }
  }

  Future<void> _sendBug() async {
    final rawInput = targetCtrl.text.trim();
    final key = widget.sessionKey;

    if (!isValidGroupLink(rawInput)) {
      _showAlert('Link Tidak Valid', 'Masukkan link grup WhatsApp yang valid.\nContoh: https://chat.whatsapp.com/XXX');
      return;
    }

    if (_senderType == 'global' && !canAccessGlobalSender) {
      _showAlert('Akses Ditolak', 'Sender Global hanya untuk Developer, Owner, Admin, Moderator, Partner & VIP!');
      return;
    }

    if (selectedBugId.isEmpty) {
      _showAlert('Error', 'Bug tidak tersedia. Hubungi @xyzyanzzi');
      return;
    }

    setState(() { _isSending = true; _responseMsg = null; });
    _resultCtrl.reset();

    try {
      final encodedTarget = Uri.encodeComponent(rawInput);
      final url = Uri.parse(
        '${Api.baseUrl}/sendBug'
        '?key=$key'
        '&target=$encodedTarget'
        '&bug=$selectedBugId'
        '${_senderType == 'global' ? '&senderMode=global' : ''}',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 20));
      final data = jsonDecode(res.body);

      if (data['valid'] == false) {
        _setResponse('error', 'Session key tidak valid. Silakan login ulang.');
      } else if (data['cooldown'] == true) {
        final wait = data['wait'] ?? 0;
        _setResponse('warning', 'Cooldown aktif! Tunggu $wait detik lagi.');
      } else if (data['sended'] == true) {
        final role = data['role'] ?? widget.role;
        final senderCount = data['senders_used'] ?? 'N/A';
        _setResponse('success', '✅ BAN GROUP BERHASIL!\nSender: $senderCount | Role: $role');
        targetCtrl.clear();
      } else {
        _setResponse('error', '❌ Gagal mengirim. Server maintenance.');
      }
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        _setResponse('error', '⏰ Request timeout. Periksa koneksi internet.');
      } else {
        _setResponse('error', '⚠️ Koneksi error. Periksa jaringan dan coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _setResponse(String type, String msg) {
    if (!mounted) return;
    setState(() => _responseMsg = '$type|$msg');
    _resultCtrl.forward(from: 0);
  }

  bool isValidGroupLink(String s) => s.startsWith('https://') && s.contains('chat.whatsapp.com');

  void _showAlert(String title, String msg) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (ctx, _, __) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.amber.withOpacity(0.3), width: 1.5),
            boxShadow: [BoxShadow(color: _C.amber.withOpacity(0.12), blurRadius: 40)],
          ),
          padding: const EdgeInsets.all(26),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.amber.withOpacity(0.1),
                border: Border.all(color: _C.amber.withOpacity(0.3)),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: _C.amber, size: 26),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(color: _C.text, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: _C.textSub, fontSize: 13, height: 1.5)),
            const SizedBox(height: 22),
            _GradBtn(label: 'OK', fullWidth: true, onTap: () => Navigator.pop(ctx)),
          ]),
        ),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          Positioned.fill(child: _AnimatedBg(controller: _bgCtrl)),
          SafeArea(
            child: FadeTransition(
              opacity: _entrance,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                child: Column(
                  children: [
                    // ─── HERO CARD ────────────────────────────────────
                    _buildHeroCard(),
                    const SizedBox(height: 16),

                    // ─── WARNING BANNER ──────────────────────────────
                    _buildWarningBanner(),
                    const SizedBox(height: 16),

                    // ─── GROUP LINK INPUT ────────────────────────────
                    _buildGroupInput(),
                    const SizedBox(height: 16),

                    // ─── SENDER CARD ──────────────────────────────────
                    _buildSenderCard(),
                    const SizedBox(height: 24),

                    // ─── SEND BUTTON ──────────────────────────────────
                    _buildSendButton(),
                    if (_responseMsg != null) ...[
                      const SizedBox(height: 12),
                      _buildResultBanner(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HERO CARD ───────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(colors: [Color(0xff0a1512), Color(0xff10251d)]),
        border: Border.all(color: _C.green.withOpacity(.3)),
        boxShadow: [BoxShadow(color: _C.green.withOpacity(.15), blurRadius: 25)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [_C.green.withOpacity(0.8), _C.greenDim]),
                  boxShadow: [BoxShadow(color: _C.green.withOpacity(0.4), blurRadius: 20)],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.username,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: _roleColor(widget.role).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _roleColor(widget.role).withOpacity(0.3)),
                          ),
                          child: Text(
                            widget.role.toUpperCase(),
                            style: TextStyle(color: _roleColor(widget.role), fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Exp: ${widget.expiredDate}',
                          style: const TextStyle(color: _C.textSub, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _C.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.fiber_manual_record, color: _C.green, size: 8),
                    SizedBox(width: 4),
                    Text('LIVE', style: TextStyle(color: _C.green, fontSize: 9, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.bug_report_rounded, color: _C.green, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        'GCBAN',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Text('Mode Aktif', style: TextStyle(color: _C.textSub, fontSize: 9)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.flash_on, color: _C.green, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        '${_globalSenders.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Text('Sender', style: TextStyle(color: _C.textSub, fontSize: 9)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: _C.green, size: 22),
                      const SizedBox(height: 4),
                      const Text(
                        'READY',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Text('Status', style: TextStyle(color: _C.textSub, fontSize: 9)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── WARNING BANNER ──────────────────────────────────────────────────────
  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.warning.withOpacity(0.08), _C.warning.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.warning.withOpacity(0.25), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.warning.withOpacity(0.12),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: _C.warning, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '⚠️ PERINGATAN',
                  style: TextStyle(color: _C.warning, fontSize: 13, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  'Tidak semua grup berhasil di-ban. Efektivitas tergantung keamanan grup dan bug yang digunakan.',
                  style: TextStyle(color: _C.textSub, fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── GROUP INPUT ─────────────────────────────────────────────────────────
  Widget _buildGroupInput() {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [BoxShadow(color: _C.green.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _C.border.withOpacity(0.6))),
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: _C.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.link_rounded, color: _C.green, size: 16),
                ),
                const SizedBox(width: 10),
                const Text(
                  'LINK GRUP WHATSAPP',
                  style: TextStyle(color: _C.textSub, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _C.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('GCBAN', style: TextStyle(color: _C.green, fontSize: 9, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: _BugInput(
              controller: targetCtrl,
              hint: 'https://chat.whatsapp.com/...',
              keyboardType: TextInputType.url,
              icon: Icons.link_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SENDER CARD ─────────────────────────────────────────────────────────
  Widget _buildSenderCard() {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [BoxShadow(color: _C.green.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _C.border.withOpacity(0.6))),
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: _C.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _C.borderLit),
                  ),
                  child: const Icon(FontAwesomeIcons.server, color: _C.redLight, size: 14),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sender Type', style: TextStyle(color: _C.text, fontSize: 13, fontWeight: FontWeight.w700)),
                    Text('Pilih sumber sender', style: TextStyle(color: _C.textSub, fontSize: 10)),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _loadGlobalSenders,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _C.border),
                    ),
                    child: _isLoadingSenders
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(strokeWidth: 2, color: _C.redLight),
                          )
                        : const Icon(Icons.refresh_rounded, color: _C.textSub, size: 16),
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
                    sublabel: _isLoadingSenders ? 'Loading...' : '${_globalSenders.length} sender',
                    selected: _senderType == 'global',
                    locked: !canAccessGlobalSender,
                    onTap: () {
                      if (!canAccessGlobalSender) {
                        _showAlert('Akses Ditolak', 'Sender Global hanya untuk Access VIP!\nHubungi @xyzyanzzi untuk upgrade.');
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
                    sublabel: 'Session sendiri',
                    selected: _senderType == 'private',
                    locked: false,
                    onTap: () => setState(() => _senderType = 'private'),
                  ),
                ),
              ],
            ),
          ),
          if (_senderType == 'global' && _globalSenders.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.format_list_bulleted_rounded, color: _C.textSub, size: 13),
                  const SizedBox(width: 6),
                  Text(
                    '${_globalSenders.length} sender aktif',
                    style: const TextStyle(color: _C.textSub, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  ..._globalSenders.take(2).map((s) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _C.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        s.length > 8 ? '${s.substring(0, 8)}...' : s,
                        style: const TextStyle(color: _C.green, fontSize: 8),
                      ),
                    ),
                  )),
                  if (_globalSenders.length > 2)
                    Text(
                      '+${_globalSenders.length - 2}',
                      style: const TextStyle(color: _C.textDim, fontSize: 9),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── SEND BUTTON ─────────────────────────────────────────────────────────
  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _sendBtnCtrl,
      builder: (_, __) => GestureDetector(
        onTap: _isSending ? null : _sendBug,
        child: Transform.scale(
          scale: _isSending ? 1.0 : _sendPulse.value,
          child: Container(
            height: 58,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B4D28), Color(0xFF14713C), Color(0xFF1C9A50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _C.redMid.withOpacity(_isSending ? 0.2 : _sendGlow.value * 0.55),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (_isSending)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedBuilder(
                      animation: _waveCtrl,
                      builder: (_, __) => CustomPaint(
                        painter: _WavePainter(_waveCtrl.value),
                        size: const Size(double.infinity, 58),
                      ),
                    ),
                  ),
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _isSending
                        ? const Row(
                            key: ValueKey('sending'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              ),
                              SizedBox(width: 14),
                              Text(
                                'Mengirim Ban...',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                            ],
                          )
                        : const Row(
                            key: ValueKey('idle'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
                              SizedBox(width: 12),
                              Text(
                                'SEND BAN GROUP',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.2),
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

  // ─── RESULT BANNER ───────────────────────────────────────────────────────
  Widget _buildResultBanner() {
    if (_responseMsg == null) return const SizedBox();
    final parts = _responseMsg!.split('|');
    final type = parts[0];
    final msg = parts.length > 1 ? parts[1] : '';

    Color color;
    IconData icon;
    switch (type) {
      case 'success': color = _C.green; icon = Icons.check_circle_rounded; break;
      case 'warning': color = _C.amber; icon = Icons.warning_rounded; break;
      default: color = _C.red; icon = Icons.error_rounded;
    }

    return FadeTransition(
      opacity: _resultFade,
      child: SlideTransition(
        position: _resultSlide,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.35)),
            boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 16)],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.12),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type == 'success' ? '✅ Berhasil' : type == 'warning' ? '⚠️ Peringatan' : '❌ Gagal',
                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      msg,
                      style: const TextStyle(color: _C.textSub, fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _responseMsg = null);
                  _resultCtrl.reset();
                },
                child: const Icon(Icons.close_rounded, color: _C.textDim, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── BUG INPUT ─────────────────────────────────────────────────────────────
class _BugInput extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final IconData icon;
  const _BugInput({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    required this.icon,
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
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focused ? _C.redMid : _C.border,
          width: _focused ? 1.5 : 1.0,
        ),
        boxShadow: _focused
            ? [BoxShadow(color: _C.redMid.withOpacity(0.1), blurRadius: 14, offset: const Offset(0, 4))]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        keyboardType: widget.keyboardType,
        style: const TextStyle(color: _C.text, fontSize: 14, fontWeight: FontWeight.w500),
        cursorColor: _C.redMid,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: _C.textDim, fontSize: 13),
          prefixIcon: Icon(
            widget.icon,
            color: _focused ? _C.redLight : _C.textSub,
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// ─── SENDER OPTION ─────────────────────────────────────────────────────────
class _SenderOption extends StatefulWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  const _SenderOption({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  State<_SenderOption> createState() => _SenderOptionState();
}

class _SenderOptionState extends State<_SenderOption> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? _C.green : _C.textSub;
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
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: widget.selected ? _C.green.withOpacity(0.08) : _C.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.selected ? _C.green.withOpacity(0.4) : _C.border,
              width: widget.selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(widget.icon, color: color, size: 18),
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
                        child: const Icon(Icons.lock_rounded, color: Colors.white, size: 6),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                widget.sublabel,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _C.textDim, fontSize: 9, height: 1.2),
              ),
              if (widget.selected) ...[
                const SizedBox(height: 4),
                Container(
                  width: 16,
                  height: 2,
                  decoration: BoxDecoration(
                    color: _C.green,
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

// ─── WAVE PAINTER ──────────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final double t;
  _WavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.5 +
          math.sin((x / size.width * 4 * math.pi) + (t * math.pi * 2)) * size.height * 0.15;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.t != t;
}

// ─── ANIMATED BG ───────────────────────────────────────────────────────────
class _AnimatedBg extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBg({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(painter: _BgPainter(controller.value)),
    );
  }
}

class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = _C.border.withOpacity(0.22)
      ..strokeWidth = 0.5;
    const step = 38.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          _C.red.withOpacity(0.10 + math.sin(t * math.pi * 2) * 0.03),
          Colors.transparent,
        ],
        radius: 0.9,
      ).createShader(
        Rect.fromCircle(center: Offset(size.width / 2, 0), radius: size.width),
      );
    canvas.drawCircle(Offset(size.width / 2, 0), size.width, glow);
  }

  @override
bool shouldRepaint(_BgPainter old) => old.t != t;
}

// ─── GRADIENT BUTTON ───────────────────────────────────────────────────────
class _GradBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  const _GradBtn({
    required this.label,
    required this.onTap,
    this.fullWidth = false,
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
            borderRadius: BorderRadius.circular(13),
            boxShadow: _down
                ? []
                : [
                    BoxShadow(
                      color: _C.redMid.withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
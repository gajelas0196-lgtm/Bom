import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'splash.dart';
import 'api.dart';
// ────────────────────────────────────────────────────────────────────────────
//  PALETTE — HITAM + PUTIH GLOW
// ────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg         = Color(0xFF000000);
  static const surface    = Color(0xFF121212);
  static const card       = Color(0xFF1A1A1A);
  static const cardAlt    = Color(0xFF222222);
  static const border     = Color(0xFFFFFFFF);
  static const borderLit  = Color(0xFFE0E0E0);

  static const steel      = Color(0xFF808080);
  static const blueMid    = Color(0xFFFFFFFF);
  static const blueLight  = Color(0xFFE0E0E0);
  static const chrome     = Color(0xFFB0B0B0);
  static const frost      = Color(0xFF808080);

  static const green      = Color(0xFF00FF00);
  static const amber      = Color(0xFFFFCC00);
  static const red        = Color(0xFFFF4444);

  static const text       = Color(0xFFFFFFFF);
  static const textSub    = Color(0xFFB0B0B0);
  static const textDim    = Color(0xFF808080);

  static const LinearGradient metalGrad = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient creamGrad = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF0A0A0A), Color(0xFF000000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient textGrad = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ────────────────────────────────────────────────────────────────────────────
//  LOGIN PAGE
// ────────────────────────────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  final userCtrl    = TextEditingController();
  final passCtrl    = TextEditingController();
  final _formKey    = GlobalKey<FormState>();
  static const platform = MethodChannel('app_security');

  bool _isLoading       = false;
  bool _obscurePass     = true;
  String? _androidId;

  bool _is3DNeoMode = false;

  late AnimationController _bgCtrl;
  late AnimationController _entranceCtrl;
  late AnimationController _logoCtrl;
  late AnimationController _btnCtrl;
  late AnimationController _shakeCtrl;

  late Animation<double> _fade;
  late Animation<Offset>  _slide;
  late Animation<double>  _logoGlow;
  late Animation<double>  _btnPulse;
  late Animation<double>  _shake;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 18))
      ..repeat();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fade  = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceCtrl, curve: Curves.easeOutCubic));

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _logoGlow = Tween<double>(begin: 0.3, end: 0.85)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeInOut));

    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _btnPulse = Tween<double>(begin: 1.0, end: 1.03)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -7.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0),   weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: 0.0),    weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _entranceCtrl.forward();
    _initLogin();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _entranceCtrl.dispose();
    _logoCtrl.dispose();
    _btnCtrl.dispose();
    _shakeCtrl.dispose();
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  void _toggle3DNeo() {
    HapticFeedback.mediumImpact();
    setState(() => _is3DNeoMode = !_is3DNeoMode);
  }

  Future<void> _initLogin() async {
    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      _androidId = deviceInfo.id;

      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;

      String appCertificate;
      try {
        appCertificate =
            await platform.invokeMethod<String>('getSignature') ?? '';
      } catch (_) {
        appCertificate = '';
      }

      if (appVersion.isEmpty || appCertificate.isEmpty) {
        if (!mounted) return;
        _showAlert(
          title: 'APK Tidak Valid',
          message: 'Informasi keamanan aplikasi tidak dapat diverifikasi.',
          type: _AlertType.error,
          showContact: true,
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final savedUser = prefs.getString('username');
      final savedPass = prefs.getString('password');
      final savedKey = prefs.getString('key');

      if (savedUser == null || savedPass == null || savedKey == null) {
        return;
      }

      final uri = Uri.parse('${Api.baseUrl}/myInfo').replace(
        queryParameters: {
          'username': savedUser,
          'password': savedPass,
          'androidId': _androidId ?? '',
          'key': savedKey,
          'appVersion': appVersion,
          'appCertificate': appCertificate,
        },
      );

      final res = await http.get(uri);
      final data = jsonDecode(res.body);

      if (data['error'] == 'SECURITY_FAILED' ||
          data['error'] == 'SECURITY_REQUIRED') {
        if (!mounted) return;
        _showAlert(
          title: 'Akses Ditolak',
          message: data['message'] ?? 'APK tidak valid.',
          type: _AlertType.error,
          showContact: true,
        );
        return;
      }

      if (data['valid'] == true && mounted) {
        await _updateFCM(savedKey);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SplashScreen(
              username: savedUser,
              password: savedPass,
              role: data['role'],
              sessionKey: data['key'],
              expiredDate: data['expiredDate'],
              listBug: _parseList(data['listBug']),
              listBugGroup: _parseList(data['listBugGroup']),
              listDoos: _parseList(data['listDDoS']),
              news: _parseList(data['news']),
              jjVideos: _parseList(data['jjVideos']),
              thanksTo: _parseList(data['thanksTo']),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showAlert(
        title: 'Koneksi Error',
        message: 'Gagal terhubung ke server. Periksa jaringan Anda.',
        type: _AlertType.error,
      );
    }
  }

  List<Map<String, dynamic>> _parseList(dynamic raw) =>
      (raw as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  Future<void> _updateFCM(String sessionKey) async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await http.get(
        Uri.parse('${Api.baseUrl}/updateFCM?key=$sessionKey&token=${Uri.encodeComponent(token)}'),
      );
    } catch(_){}
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = userCtrl.text.trim();
    final password = passCtrl.text.trim();

    setState(() => _isLoading = true);

    try {
      String appVersion = "";
      String appCertificate = "";

      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;

      try {
        appCertificate =
            await platform.invokeMethod<String>('getSignature') ?? '';
      } catch (_) {
        appCertificate = '';
      }

      if (appVersion.isEmpty || appCertificate.isEmpty) {
        _shakeCtrl.forward(from: 0);
        _showAlert(
          title: 'APK Tidak Valid',
          message: 'Informasi keamanan aplikasi tidak dapat diverifikasi.',
          type: _AlertType.error,
          showContact: true,
        );
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final res = await http.post(Uri.parse('${Api.baseUrl}/validate'), body: {
        'username': username,
        'password': password,
        'androidId': _androidId ?? 'unknown',
        'appVersion': appVersion,
        'appCertificate': appCertificate,
      });

      final data = jsonDecode(res.body);

      if (data['error'] == 'SECURITY_FAILED') {
        _shakeCtrl.forward(from: 0);
        _showAlert(
          title: 'Akses Ditolak',
          message: data['message'] ?? 'APK tidak valid.',
          type: _AlertType.error,
          showContact: true,
        );
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (data['maintenance'] == true) {
        _shakeCtrl.forward(from: 0);
        _showAlert(
          title: 'Maintenance',
          message: data['message'] ?? 'Server sedang dalam pemeliharaan.',
          type: _AlertType.warning,
        );
      } else if (data['banned'] == true) {
        _shakeCtrl.forward(from: 0);
        _showAlert(
          title: 'Akun Dibanned',
          message: data['message'] ?? 'Akun Anda telah dibanned oleh Admin.',
          type: _AlertType.error,
        );
      } else if (data['expired'] == true) {
        _shakeCtrl.forward(from: 0);
        _showAlert(
          title: 'Akses Habis',
          message: 'Masa akses Anda telah berakhir. Silakan perpanjang.',
          type: _AlertType.warning,
          showContact: true,
        );
      } else if (data['valid'] != true) {
        _shakeCtrl.forward(from: 0);
        final msg = (data['message'] ?? '').toString().toLowerCase();
        if (msg.contains('perangkat') || msg.contains('device') ||
            msg.contains('another')) {
          _showAlert(
            title: 'Sesi Aktif',
            message: 'Akun ini sedang login di perangkat lain.',
            type: _AlertType.warning,
          );
        } else {
          _showAlert(
            title: 'Login Gagal',
            message: 'Username atau password salah.',
            type: _AlertType.error,
          );
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('username', username);
        prefs.setString('password', password);
        prefs.setString('key', data['key']);
        await _updateFCM(data['key']);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => SplashScreen(
              username: username, password: password,
              role: data['role'], sessionKey: data['key'],
              expiredDate: data['expiredDate'],
              listBug:  _parseList(data['listBug']),
              listBugGroup:  _parseList(data['listBugGroup']),
              listDoos: _parseList(data['listDDoS']),
              news:     _parseList(data['news']),
              jjVideos: _parseList(data['jjVideos']),
              thanksTo: _parseList(data['thanksTo']),
            )),
          );
        }
      }
    } catch (_) {
      _shakeCtrl.forward(from: 0);
      _showAlert(
        title: 'Koneksi Error',
        message: 'Gagal terhubung ke server. Periksa jaringan Anda.',
        type: _AlertType.error,
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showAlert({
    required String title,
    required String message,
    required _AlertType type,
    bool showContact = false,
  }) {
    final color = switch (type) {
      _AlertType.error   => _C.red,
      _AlertType.warning => _C.amber,
      _AlertType.success => _C.green,
    };
    final icon = switch (type) {
      _AlertType.error   => Icons.error_rounded,
      _AlertType.warning => Icons.warning_amber_rounded,
      _AlertType.success => Icons.check_circle_rounded,
    };

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 320),
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
            borderRadius: BorderRadius.circular(_is3DNeoMode ? 0 : 24),
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            boxShadow: [
              if (_is3DNeoMode) ...[
                BoxShadow(color: Colors.black.withOpacity(0.5), offset: const Offset(6, 6), blurRadius: 0),
                BoxShadow(color: color.withOpacity(0.3), offset: const Offset(3, 3), blurRadius: 0),
              ] else
                BoxShadow(color: color.withOpacity(0.2), blurRadius: 50),
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: _is3DNeoMode ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: _is3DNeoMode ? BorderRadius.circular(8) : null,
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(color: _C.text, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Aktura')),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: _C.textSub, fontSize: 13, height: 1.5, fontFamily: 'Aktura')),
            const SizedBox(height: 22),
            if (showContact) ...[
              _GradBtn(
                label: 'Hubungi Admin',
                fullWidth: true,
                is3DNeo: _is3DNeoMode,
                onTap: () async {
                  Navigator.pop(ctx);
                  await launchUrl(Uri.parse('https://t.me/By_Zii16'), mode: LaunchMode.externalApplication);
                },
              ),
              const SizedBox(height: 10),
            ],
            _OutlineBtn(
              label: showContact ? 'Tutup' : 'OK',
              fullWidth: true,
              is3DNeo: _is3DNeoMode,
              onTap: () => Navigator.pop(ctx),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          Positioned.fill(child: _AnimatedBg(controller: _bgCtrl, is3DNeo: _is3DNeoMode)),

          Positioned(
            top: 12,
            right: 16,
            child: SafeArea(
              child: _build3DNeoButton(),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 32),
                        _buildHeading(),
                        const SizedBox(height: 36),
                        AnimatedBuilder(
                          animation: _shake,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(_shake.value, 0),
                            child: child,
                          ),
                          child: _buildForm(),
                        ),
                        const SizedBox(height: 28),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3DNeoButton() {
    return GestureDetector(
      onTap: _toggle3DNeo,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _is3DNeoMode ? _C.blueMid : _C.card,
          borderRadius: BorderRadius.circular(_is3DNeoMode ? 0 : 12),
          border: Border.all(
            color: _is3DNeoMode ? _C.steel : _C.border,
            width: 1.5,
          ),
          boxShadow: _is3DNeoMode
              ? [
                  BoxShadow(color: _C.blueMid.withOpacity(0.4), offset: const Offset(4, 4), blurRadius: 0),
                  BoxShadow(color: Colors.black.withOpacity(0.5), offset: const Offset(6, 6), blurRadius: 0),
                ]
              : [
                  BoxShadow(color: _C.blueMid.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedRotation(
              turns: _is3DNeoMode ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: Icon(
                Icons.view_in_ar_rounded,
                size: 16,
                color: _is3DNeoMode ? Colors.black : _C.blueMid,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '3D NEO',
              style: TextStyle(
                color: _is3DNeoMode ? Colors.black : _C.blueMid,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                fontFamily: 'Aktura',
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoGlow,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: _is3DNeoMode ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: _is3DNeoMode ? BorderRadius.circular(0) : null,
              border: Border.all(color: _C.blueMid.withOpacity(_logoGlow.value * 0.3), width: 1),
            ),
          ),
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: _is3DNeoMode ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: _is3DNeoMode ? BorderRadius.circular(0) : null,
              border: Border.all(color: _C.blueMid.withOpacity(_logoGlow.value * 0.5), width: 1.5),
            ),
          ),
          Hero(
            tag: 'logo',
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_is3DNeoMode ? 0 : 22),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _C.blueMid.withOpacity(_logoGlow.value * 0.8),
                  width: 1.5,
                ),
                boxShadow: _is3DNeoMode
                    ? [
                        BoxShadow(color: _C.blueMid.withOpacity(0.3), offset: const Offset(5, 5), blurRadius: 0),
                        BoxShadow(color: Colors.black.withOpacity(0.5), offset: const Offset(7, 7), blurRadius: 0),
                      ]
                    : [
                        BoxShadow(color: _C.blueMid.withOpacity(_logoGlow.value * 0.4), blurRadius: 28),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_is3DNeoMode ? 0 : 20),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.water_rounded,
                    color: _C.blueMid,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeading() {
    return Column(children: [
      ShaderMask(
        shaderCallback: (b) => _C.textGrad.createShader(b),
        child: Text(
          'Selamat Datang',
          style: TextStyle(
            fontSize: 28,
            fontFamily: "Aktura",
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
            shadows: _is3DNeoMode
                ? const [
                    Shadow(color: Color(0xFFE0E0E0), offset: Offset(2, 2)),
                    Shadow(color: Color(0xFFFFFFFF), offset: Offset(3, 3)),
                  ]
                : null,
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Masuk untuk melanjutkan',
        style: TextStyle(
          color: _C.textSub,
          fontSize: 14,
          fontFamily: 'Aktura',
          fontWeight: FontWeight.w600,
        ),
      ),
    ]);
  }

  Widget _buildForm() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(_is3DNeoMode ? 0 : 24),
        border: Border.all(
          color: _is3DNeoMode ? _C.borderLit : _C.border,
          width: _is3DNeoMode ? 2 : 1.5,
        ),
        boxShadow: _is3DNeoMode
            ? [
                BoxShadow(color: _C.borderLit.withOpacity(0.6), offset: const Offset(8, 8), blurRadius: 0),
                BoxShadow(color: _C.textDim.withOpacity(0.4), offset: const Offset(12, 12), blurRadius: 0),
              ]
            : [
                BoxShadow(color: _C.blueMid.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10)),
              ],
      ),
      child: Form(
        key: _formKey,
        child: Column(children: [
          Row(children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                gradient: _C.metalGrad,
                borderRadius: BorderRadius.circular(_is3DNeoMode ? 0 : 2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Kredensial Akun',
              style: TextStyle(
                color: _C.text,
                fontSize: 14,
                fontFamily: "Aktura",
                fontWeight: FontWeight.w700,
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _LoginField(
            controller: userCtrl,
            label: 'Username',
            icon: Icons.person_outline_rounded,
            is3DNeo: _is3DNeoMode,
            validator: (v) => (v == null || v.isEmpty) ? 'Username tidak boleh kosong' : null,
          ),
          const SizedBox(height: 14),
          _LoginField(
            controller: passCtrl,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePass,
            is3DNeo: _is3DNeoMode,
            onToggleObscure: () => setState(() => _obscurePass = !_obscurePass),
            validator: (v) => (v == null || v.isEmpty) ? 'Password tidak boleh kosong' : null,
          ),
          const SizedBox(height: 24),
          _LoginButton(
            isLoading: _isLoading,
            pulseAnim: _btnPulse,
            is3DNeo: _is3DNeoMode,
            onTap: _login,
          ),
        ]),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          'Belum punya akses ',
          style: TextStyle(
            color: _C.textSub,
            fontSize: 13,
            fontFamily: 'Aktura',
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: () => launchUrl(Uri.parse('https://t.me/By_Zii16'), mode: LaunchMode.externalApplication),
          child: ShaderMask(
            shaderCallback: (b) => _C.metalGrad.createShader(b),
            child: const Text(
              'Beli Sekarang',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'Aktura',
              ),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 20),
      RichText(
        text: TextSpan(
          style: TextStyle(color: _C.textDim, fontSize: 11),
          children: const [
            TextSpan(text: '© ', style: TextStyle(fontFamily: 'ready')),
            TextSpan(text: '2026', style: TextStyle(fontFamily: 'Ready')),
            TextSpan(text: 'OneCrash project', style: TextStyle(fontFamily: 'Qaxer')),
          ],
        ),
      ),
    ]);
  }
}
// ═══════════════════════════════════════════════════════════════════════════
//  LOGIN FIELD
// ═══════════════════════════════════════════════════════════════════════════
class _LoginField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final bool is3DNeo;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;

  const _LoginField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.is3DNeo = false,
    this.onToggleObscure,
    this.validator,
  });

  @override
  State<_LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<_LoginField> {
  bool _focused = false;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(widget.is3DNeo ? 0 : 14),
        border: Border.all(
          color: _focused ? _C.blueMid : _C.border,
          width: _focused ? 2 : 1.5,
        ),
        boxShadow: _focused
            ? [
                if (widget.is3DNeo) ...[
                  BoxShadow(color: _C.blueMid.withOpacity(0.3), offset: const Offset(4, 4), blurRadius: 0),
                ] else
                  BoxShadow(color: _C.blueMid.withOpacity(0.15), blurRadius: 14, offset: const Offset(0, 4)),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focus,
        obscureText: widget.obscure,
        validator: widget.validator,
        style: TextStyle(
          color: _C.text,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Aktura',
        ),
        cursorColor: _C.blueMid,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(color: _C.textSub, fontSize: 13, fontFamily: 'Aktura', fontWeight: FontWeight.w600),
          floatingLabelStyle: TextStyle(color: _C.blueMid, fontSize: 11, fontFamily: 'Aktura', fontWeight: FontWeight.w700),
          prefixIcon: Icon(widget.icon, color: _focused ? _C.blueMid : _C.textSub, size: 18),
          suffixIcon: widget.onToggleObscure != null
              ? IconButton(
                  icon: Icon(
                    widget.obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: _C.textSub,
                    size: 18,
                  ),
                  onPressed: widget.onToggleObscure,
                )
              : null,
          errorStyle: const TextStyle(color: _C.red, fontSize: 11, fontFamily: 'Aktura', fontWeight: FontWeight.w600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  LOGIN BUTTON
// ═══════════════════════════════════════════════════════════════════════════
class _LoginButton extends StatefulWidget {
  final bool isLoading;
  final Animation<double> pulseAnim;
  final bool is3DNeo;
  final VoidCallback onTap;

  const _LoginButton({
    required this.isLoading,
    required this.pulseAnim,
    required this.is3DNeo,
    required this.onTap,
  });

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) { setState(() => _down = false); if (!widget.isLoading) widget.onTap(); },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedBuilder(
        animation: widget.pulseAnim,
        builder: (_, __) => Transform.scale(
          scale: widget.isLoading || _down ? 1.0 : widget.pulseAnim.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 54,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: _C.metalGrad,
              borderRadius: BorderRadius.circular(widget.is3DNeo ? 0 : 16),
              border: widget.is3DNeo
                  ? Border.all(color: _C.steel, width: 2)
                  : Border.all(color: _C.border, width: 2),
              boxShadow: _down || widget.isLoading
                  ? []
                  : widget.is3DNeo
                      ? [
                          BoxShadow(color: _C.steel.withOpacity(0.6), offset: const Offset(6, 6), blurRadius: 0),
                          BoxShadow(color: Colors.black.withOpacity(0.5), offset: const Offset(9, 9), blurRadius: 0),
                        ]
                      : [
                          BoxShadow(color: _C.blueMid.withOpacity(widget.pulseAnim.value * 0.4), blurRadius: 22, offset: const Offset(0, 6)),
                        ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: widget.isLoading
                    ? const SizedBox(key: ValueKey('loading'), width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                    : const Row(
                        key: ValueKey('idle'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.login_rounded, color: Colors.black, size: 18),
                          SizedBox(width: 10),
                          Text(
                            'Masuk',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              fontFamily: 'Aktura',
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  GRADIENT BUTTON
// ═══════════════════════════════════════════════════════════════════════════
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
      onTapUp: (_) { setState(() => _down = false); widget.onTap(); },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 46,
          width: widget.fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            gradient: _C.metalGrad,
            borderRadius: BorderRadius.circular(widget.is3DNeo ? 0 : 13),
            border: widget.is3DNeo
                ? Border.all(color: _C.steel, width: 2)
                : Border.all(color: _C.border, width: 2),
            boxShadow: _down
                ? []
                : widget.is3DNeo
                    ? [
                        BoxShadow(color: _C.steel.withOpacity(0.5), offset: const Offset(4, 4), blurRadius: 0),
                      ]
                    : [
                        BoxShadow(color: _C.blueMid.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4)),
                      ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                fontFamily: 'Aktura',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  OUTLINE BUTTON
// ═══════════════════════════════════════════════════════════════════════════
class _OutlineBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;
  final bool is3DNeo;
  const _OutlineBtn({
    required this.label,
    required this.onTap,
    this.fullWidth = false,
    this.is3DNeo = false,
  });

  @override
  State<_OutlineBtn> createState() => _OutlineBtnState();
}

class _OutlineBtnState extends State<_OutlineBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) { setState(() => _down = false); widget.onTap(); },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 46,
        width: widget.fullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          color: _down ? _C.border.withOpacity(0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(widget.is3DNeo ? 0 : 13),
          border: Border.all(
            color: _C.border,
            width: widget.is3DNeo ? 2 : 1.5,
          ),
          boxShadow: widget.is3DNeo && !_down
              ? [
                  BoxShadow(color: _C.border.withOpacity(0.5), offset: const Offset(4, 4), blurRadius: 0),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            widget.label,
            style: TextStyle(
              color: _C.textSub,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              fontFamily: 'Aktura',
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ANIMATED BACKGROUND
// ═══════════════════════════════════════════════════════════════════════════
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
    final bgPaint = Paint()
      ..shader = _C.creamGrad.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final grid = Paint()
      ..color = _C.border.withOpacity(is3DNeo ? 0.18 : 0.10)
      ..strokeWidth = is3DNeo ? 0.8 : 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (is3DNeo) {
      final boxPaint = Paint()
        ..color = _C.card.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      final boxShadow = Paint()
        ..color = _C.borderLit.withOpacity(0.35)
        ..style = PaintingStyle.fill;
      const boxSize = 80.0;
      for (double x = 0; x < size.width; x += boxSize) {
        for (double y = 0; y < size.height; y += boxSize) {
          final rect = Rect.fromLTWH(x + 4, y + 4, boxSize - 8, boxSize - 8);
          canvas.drawRect(rect.translate(6, 6), boxShadow);
          canvas.drawRect(rect, boxPaint);
          final borderPaint = Paint()
            ..color = _C.borderLit.withOpacity(0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
          canvas.drawRect(rect, borderPaint);
        }
      }
    }

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          _C.blueMid.withOpacity(0.06 + math.sin(t * math.pi * 2) * 0.02),
          Colors.transparent,
        ],
        radius: 0.75,
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 0.35),
        radius: size.width * 0.7,
      ));
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.35),
      size.width * 0.7,
      glow,
    );

    final glow2 = Paint()
      ..shader = RadialGradient(
        colors: [
          _C.frost.withOpacity(0.08 + math.cos(t * math.pi * 2) * 0.03),
          Colors.transparent,
        ],
        radius: 0.5,
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.9, size.height * 0.85),
        radius: size.width * 0.5,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.85),
      size.width * 0.5,
      glow2,
    );
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t || old.is3DNeo != is3DNeo;
}

enum _AlertType { error, warning, success }
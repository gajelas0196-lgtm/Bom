import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'api.dart';

class PartnerPage extends StatefulWidget {
  final String sessionKey;
  final String username;

  const PartnerPage({
    super.key,
    required this.sessionKey,
    required this.username,
  });

  @override
  State<PartnerPage> createState() => _PartnerPageState();
}

class _PartnerPageState extends State<PartnerPage> {
  late String sessionKey;
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];

  final List<String> roleOptions = ['admin', 'vip', 'reseller', 'member'];
  String selectedRole = 'member';

  int currentPage = 1;
  int itemsPerPage = 25;

  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  final deleteController = TextEditingController();
  final editUsernameController = TextEditingController();
  final editDayController = TextEditingController();

  String newUserRole = 'member';
  bool isLoading = false;

  // ===========================
  // QAXER TEAM THEME
  // ===========================
  final Color bgDark = const Color(0xFF050B08);
  final Color surface = const Color(0xFF0B1711);
  final Color surface2 = const Color(0xFF12211A);
  final Color primaryRed = const Color(0xFF1FAF63);
  final Color accentRed = const Color(0xFF37D67A);
  final Color borderGreen = const Color(0xFF225D3D);
  final Color primaryWhite = const Color(0xFFE9F8EF);
  final Color textGrey = const Color(0xFF9DB5A3);
  final Color cardGlass = const Color(0xFF0F1814);
  final Color borderGlass = const Color(0xFF225D3D);

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('${Api.baseUrl}/listUsers?key=$sessionKey'),
      );
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        fullUserList = data['users'] ?? [];
        _filterAndPaginate();
      } else {
        _alert("Info", data['message'] ?? 'Gagal memuat user.');
      }
    } catch (_) {
      _alert("Error", "Gagal terhubung ke server.");
    }
    setState(() => isLoading = false);
  }

  void _filterAndPaginate() {
    setState(() {
      currentPage = 1;
      filteredList = fullUserList.where((u) => u['role'] == selectedRole).toList();
    });
  }

  List<dynamic> _getCurrentPageData() {
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage);
    return filteredList.sublist(start, end > filteredList.length ? filteredList.length : end);
  }

  int get totalPages => (filteredList.length / itemsPerPage).ceil();

  int _countByRole(String role) {
    return fullUserList.where((u) => u['role'] == role).length;
  }

  Future<void> _deleteUser() async {
    final username = deleteController.text.trim();
    if (username.isEmpty) {
      _alert("Peringatan", "Masukkan username yang ingin dihapus.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('${Api.baseUrl}/deleteUser?key=$sessionKey&username=$username'),
      );
      final data = jsonDecode(res.body);

      if (data['deleted'] == true) {
        _alert("Sukses", "User berhasil dihapus.");
        deleteController.clear();
        _fetchUsers();
      } else {
        _alert("Gagal", data['message'] ?? 'Gagal menghapus user.');
      }
    } catch (_) {
      _alert("Error", "Gagal menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  Future<void> _createAccount() async {
    final u = createUsernameController.text.trim();
    final p = createPasswordController.text.trim();
    final d = createDayController.text.trim();

    if (u.isEmpty || p.isEmpty || d.isEmpty) {
      _alert("Peringatan", "Semua field wajib diisi.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
        '${Api.baseUrl}/userAdd?key=$sessionKey&username=$u&password=$p&day=$d&role=$newUserRole',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['created'] == true) {
        _alert("Sukses", "Akun berhasil dibuat sebagai ${newUserRole.toUpperCase()}.");
        createUsernameController.clear();
        createPasswordController.clear();
        createDayController.clear();
        newUserRole = 'member';
        _fetchUsers();
      } else {
        _alert("Gagal", data['message'] ?? 'Gagal membuat akun.');
      }
    } catch (_) {
      _alert("Error", "Gagal menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  Future<void> _editUser() async {
    final u = editUsernameController.text.trim();
    final d = editDayController.text.trim();

    if (u.isEmpty || d.isEmpty) {
      _alert("Peringatan", "Semua field wajib diisi.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final url = Uri.parse('${Api.baseUrl}/editUser?key=$sessionKey&username=$u&addDays=$d');
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['edited'] == true) {
        _alert("Sukses", "Durasi berhasil diperbarui.");
        editUsernameController.clear();
        editDayController.clear();
        _fetchUsers();
      } else {
        _alert("Gagal", data['message'] ?? 'Gagal mengubah durasi.');
      }
    } catch (_) {
      _alert("Error", "Gagal menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  void _alert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accentRed.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: accentRed),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: primaryWhite, fontFamily: 'Aktura')),
          ],
        ),
        content: Text(message, style: TextStyle(color: textGrey, fontFamily: 'Aktura')),
        actions: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryRed, accentRed]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "OK",
                  style: TextStyle(color: primaryWhite, fontWeight: FontWeight.bold, fontFamily: 'Aktura'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== PREMIUM WIDGETS =====

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required dynamic icon,
    TextInputType type = TextInputType.text,
  }) {
    final isNumeric = type == TextInputType.number;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: TextStyle(color: primaryWhite, fontFamily: isNumeric ? 'Ready' : 'Aktura'),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: accentRed.withOpacity(0.9), fontFamily: 'Aktura'),
          prefixIcon: Icon(icon, color: accentRed),
          filled: true,
          fillColor: cardGlass,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: borderGlass),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: borderGlass),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: accentRed, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required String title,
    required dynamic icon,
    required List<Widget> children,
    Color? accentColor,
  }) {
    final accent = accentColor ?? accentRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryRed.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cardGlass.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderGlass.withOpacity(0.6)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cardGlass.withOpacity(0.9),
                  surface2.withOpacity(0.7),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent.withOpacity(0.25),
                            primaryRed.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accent.withOpacity(0.4)),
                      ),
                      child: FaIcon(icon, color: accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: primaryWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          fontFamily: 'Aktura',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accent.withOpacity(0.3)),
                      ),
                      child: Text(
                        "PARTNER",
                        style: TextStyle(
                          color: accent,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontFamily: 'Aktura',
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(
                  height: 28,
                  color: Color(0xFF225D3D),
                  thickness: 0.5,
                ),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required dynamic icon,
    required VoidCallback onTap,
    bool loading = false,
    List<Color>? gradientColors,
  }) {
    final colors = gradientColors ?? [primaryRed, accentRed];
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(colors: colors),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(.35),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: loading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primaryWhite,
                ),
              )
            : Icon(icon, color: primaryWhite, size: 18),
        label: Text(
          text,
          style: TextStyle(
            color: primaryWhite,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontFamily: 'Aktura',
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required dynamic icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.18),
              cardGlass.withOpacity(0.7),
            ],
          ),
          border: Border.all(color: color.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: FaIcon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "$count",
              style: TextStyle(
                color: primaryWhite,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Ready',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: textGrey,
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                fontFamily: 'Aktura',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color badgeColor;
    dynamic badgeIcon;
    switch (role.toLowerCase()) {
      case 'admin':
        badgeColor = const Color(0xFFFF6B6B);
        badgeIcon = Icons.shield;
        break;
      case 'vip':
        badgeColor = const Color(0xFF9B59B6);
        badgeIcon = Icons.star;
        break;
      case 'reseller':
        badgeColor = const Color(0xFF3498DB);
        badgeIcon = Icons.store;
        break;
      default:
        badgeColor = accentRed;
        badgeIcon = Icons.person;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: badgeColor, size: 10),
          const SizedBox(width: 4),
          Text(
            role.toUpperCase(),
            style: TextStyle(
              color: badgeColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              fontFamily: 'Aktura',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(Map user) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            cardGlass,
            surface2.withOpacity(0.5),
          ],
        ),
        border: Border.all(color: borderGlass.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: primaryRed.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryRed.withOpacity(0.3),
                  accentRed.withOpacity(0.15),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: accentRed.withOpacity(0.4)),
            ),
            child: Icon(Icons.person, color: accentRed, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user['username'] ?? '-',
                        style: TextStyle(
                          color: primaryWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: 'Aktura',
                        ),
                      ),
                    ),
                    _buildRoleBadge(user['role'] ?? 'member'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.event, color: textGrey, size: 11),
                    const SizedBox(width: 4),
                    Text(
                      "EXP: ${user['expiredDate'] ?? '-'}",
                      style: TextStyle(color: textGrey, fontSize: 11, fontFamily: 'Ready'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: bgDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: accentRed.withOpacity(0.3)),
                    ),
                    title: Text("Konfirmasi", style: TextStyle(color: primaryWhite, fontFamily: 'Aktura')),
                    content: Text("Hapus user ini?", style: TextStyle(color: textGrey, fontFamily: 'Aktura')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text("Batal", style: TextStyle(color: primaryRed, fontFamily: 'Aktura')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text("Hapus", style: TextStyle(color: Colors.redAccent, fontFamily: 'Aktura')),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  deleteController.text = user['username'];
                  _deleteUser();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: cardGlass.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderGlass.withOpacity(0.5)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: List.generate(totalPages, (index) {
          final page = index + 1;
          final isActive = currentPage == page;
          return GestureDetector(
            onTap: () => setState(() => currentPage = page),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(colors: [primaryRed, accentRed])
                    : null,
                color: isActive ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive ? accentRed : borderGlass,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: accentRed.withOpacity(0.3),
                          blurRadius: 8,
                        )
                      ]
                    : [],
              ),
              child: Text(
                "$page",
                style: TextStyle(
                  color: isActive ? primaryWhite : textGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Ready',
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderGlass),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: bgDark,
          isExpanded: true,
          style: TextStyle(color: primaryWhite, fontSize: 14, fontFamily: 'Aktura'),
          icon: Icon(Icons.keyboard_arrow_down, color: accentRed),
          items: roleOptions.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Row(
                children: [
                  Icon(Icons.circle, color: accentRed, size: 8),
                  const SizedBox(width: 10),
                  Text(role.toUpperCase()),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPartnerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryRed.withOpacity(.22),
            surface2,
            bgDark,
          ],
        ),
        border: Border.all(color: borderGreen),
        boxShadow: [
          BoxShadow(
            color: accentRed.withOpacity(.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [primaryRed, accentRed],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentRed.withOpacity(.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgDark,
                  border: Border.all(color: accentRed, width: 2),
                ),
                child: FaIcon(
                  FontAwesomeIcons.handshake,
                  color: accentRed,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "PARTNER PANEL",
            style: TextStyle(
              color: primaryWhite,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              fontFamily: 'Aktura',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "QAXER TEAM MANAGEMENT",
            style: TextStyle(
              color: accentRed,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
              fontFamily: 'Aktura',
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: primaryRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentRed.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.security, color: accentRed, size: 12),
                const SizedBox(width: 6),
                Text(
                  "COLLABORATION ACCESS",
                  style: TextStyle(
                    color: primaryWhite,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontFamily: 'Aktura',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bgDark,
              primaryRed.withOpacity(0.06),
              bgDark,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Topbar
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios, color: accentRed, size: 18),
                    ),
                    Expanded(
                      child: Text(
                        "PARTNER DASHBOARD",
                        style: TextStyle(
                          color: primaryWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          fontFamily: 'Aktura',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentRed.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user, color: accentRed, size: 12),
                          const SizedBox(width: 6),
                          Text(
                            "ONLINE",
                            style: TextStyle(
                              color: accentRed,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              fontFamily: 'Aktura',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Partner Header
                _buildPartnerHeader(),

                const SizedBox(height: 22),

                // Stats Dashboard
                Row(
                  children: [
                    _buildStatCard(
                      label: "TOTAL",
                      count: fullUserList.length,
                      icon: Icons.groups,
                      color: accentRed,
                    ),
                    _buildStatCard(
                      label: "ADMIN",
                      count: _countByRole('admin'),
                      icon: Icons.shield,
                      color: const Color(0xFFFF6B6B),
                    ),
                    _buildStatCard(
                      label: "VIP",
                      count: _countByRole('vip'),
                      icon: Icons.star,
                      color: const Color(0xFF9B59B6),
                    ),
                    _buildStatCard(
                      label: "MEMBER",
                      count: _countByRole('member'),
                      icon: Icons.person,
                      color: primaryRed,
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // SECTION 1: DELETE USER
                _buildGlassCard(
                  title: "DELETE USER",
                  icon: FaIcon(FontAwesomeIcons.userSlash,
  children: [],
                  accentColor: Colors.redAccent,
                  children: [
                    _buildInput(
                      label: "Username Target",
                      controller: deleteController,
                      icon: FaIcon(FontAwesomeIcons.user,
                    ),
                    const SizedBox(height: 6),
                    _buildButton(
                      text: "DELETE ACCOUNT",
                      icon: Icons.delete_forever,
                      onTap: _deleteUser,
                      loading: isLoading,
                      gradientColors: [Colors.redAccent, Colors.red],
                    ),
                  ],
                ),

                // SECTION 2: CREATE ACCOUNT
                _buildGlassCard(
                  title: "CREATE ACCOUNT",
                  icon: FaIcon(FontAwesomeIcons.userPlus,
                  children: [
                    _buildInput(
                      label: "Username",
                      controller: createUsernameController,
                      icon: FaIcon(FontAwesomeIcons.user,
                    ),
                    _buildInput(
                      label: "Password",
                      controller: createPasswordController,
                      icon: FaIcon(FontAwesomeIcons.lock,
                    ),
                    _buildInput(
                      label: "Durasi (Hari)",
                      controller: createDayController,
                      icon: FaIcon(FontAwesomeIcons.calendarDay,
                      type: TextInputType.number,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "PILIH ROLE",
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Aktura',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: newUserRole,
                      onChanged: (val) =>
                          setState(() => newUserRole = val ?? 'member'),
                    ),
                    const SizedBox(height: 16),
                    _buildButton(
                      text: "CREATE ACCOUNT",
                      icon: Icons.rocket_launch,
                      onTap: _createAccount,
                      loading: isLoading,
                    ),
                  ],
                ),

                // SECTION 3: EXTEND DURATION
                _buildGlassCard(
                  title: "EXTEND DURATION",
                  icon: FaIcon(FontAwesomeIcons.clock,
                  children: [
                    _buildInput(
                      label: "Username Target",
                      controller: editUsernameController,
                      icon: FaIcon(FontAwesomeIcons.userEdit,
                    ),
                    _buildInput(
                      label: "Tambah Hari",
                      controller: editDayController,
                      icon: FaIcon(FontAwesomeIcons.calendarPlus,
                      type: TextInputType.number,
                    ),
                    const SizedBox(height: 6),
                    _buildButton(
                      text: "ADD DAYS",
                      icon: Icons.update,
                      onTap: _editUser,
                      loading: isLoading,
                      gradientColors: [
                        const Color(0xFF1FAF63),
                        accentRed,
                      ],
                    ),
                  ],
                ),

                // SECTION 4: USER LIST
                _buildGlassCard(
                  title: "USER LIST",
                  icon: FaIcon(FontAwesomeIcons.users,
                  children: [
                    Text(
                      "FILTER BY ROLE",
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Aktura',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: selectedRole,
                      onChanged: (val) {
                        if (val != null) {
                          selectedRole = val;
                          _filterAndPaginate();
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accentRed.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.list_alt, color: accentRed, size: 14),
                          const SizedBox(width: 8),
                          Text(
                            "Menampilkan ${filteredList.length} user",
                            style: TextStyle(
                              color: accentRed,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Ready',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    isLoading
                        ? Container(
                            padding: const EdgeInsets.all(30),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: accentRed,
                              ),
                            ),
                          )
                        : filteredList.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(30),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inbox,
                                      color: textGrey,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "Tidak ada user pada role ini",
                                      style: TextStyle(color: textGrey, fontFamily: 'Aktura'),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  ..._getCurrentPageData()
                                      .map((u) => _buildUserItem(u))
                                      .toList(),
                                  const SizedBox(height: 14),
                                  _buildPagination(),
                                ],
                              ),
                  ],
                ),
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    "© QAXER TEAM • PARTNER EDITION",
                    style: TextStyle(
                      color: textGrey.withOpacity(0.6),
                      fontSize: 10,
                      letterSpacing: 2,
                      fontFamily: 'Aktura',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
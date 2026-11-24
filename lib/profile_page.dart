import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'change_password_page.dart';
import 'api.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;

  const ProfilePage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
  String? _networkImageUrl; // Buat nyimpen URL foto dari server
  bool _isUploadingImage = false;

  final ImagePicker _picker = ImagePicker();

  // Controller buat edit profile
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _sessionKeyController = TextEditingController();
  
  bool _isSavingProfile = false;

  // --- TEMA WARNA CYAN ---
  final Color bgDark = const Color(0xFF0B1A1A);
  final Color primaryCyan = const Color(0xFF00ACC1);
  final Color accentCyan = const Color(0xFF18FFFF);
  final Color primaryWhite = Colors.white;

  final Color cardGlass = Colors.white.withOpacity(0.05);
  final Color borderGlass = Colors.white.withOpacity(0.1);

  @override
  void initState() {
    super.initState();
    _loadLocalProfileImage();
    _fetchProfileData();
  }

  Future<void> _loadLocalProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_${widget.username}');
    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  Future<void> _fetchProfileData() async {
    try {
      final res = await http.get(Uri.parse("${Api.baseUrl}/api/getProfile?username=${widget.username}&sessionKey=${widget.sessionKey}"));
      final json = jsonDecode(res.body);
      if (json["success"] == true) {
        setState(() {
          _displayNameController.text = json["displayName"] ?? "";
          _bioController.text = json["bio"] ?? "";
          _networkImageUrl = json["profileImageUrl"]; // Ambil URL foto dari server
        });
      }
    } catch (_) {}
  }

  String _censorText(String text, {bool isPassword = false}) {
    if (text.isEmpty) return "N/A";
    if (isPassword) return "••••••••";
    if (text.length <= 2) return "${text.substring(0, 1)}••";
    return "${text.substring(0, 2)}${'•' * (text.length - 2)}";
  }

  Future<void> _showImageSourceDialog() {
    return showModalBottomSheet(
      context: context,
      backgroundColor: bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF00ACC1)),
              title: const Text("Kamera", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF18FFFF)),
              title: const Text("Galeri", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        // 1. Update UI lokal biar real-time (foto langsung berubah)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_${widget.username}', imageFile.path);
        
        setState(() {
          _profileImage = imageFile;
          _networkImageUrl = null; // Prioritaskan tampilin foto lokal yg baru dipilih
          _isUploadingImage = true;
        });

        // 2. Upload ke server
        var request = http.MultipartRequest('POST', Uri.parse('${Api.baseUrl}/api/uploadProfileImage'));
        request.fields['username'] = widget.username;
        request.fields['sessionKey'] = widget.sessionKey;
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
        
        var response = await request.send();
        
        if (mounted) {
          setState(() => _isUploadingImage = false);
        }

        if (response.statusCode == 200) {
          var responseData = await response.stream.toBytes();
          var responseString = String.fromCharCodes(responseData);
          var json = jsonDecode(responseString);
          
          if (json['success'] == true) {
            // Simpen url ke cache
            await prefs.setString('profile_image_url_${widget.username}', json['imageUrl']);
            
            if (mounted) {
              setState(() {
                _networkImageUrl = json['imageUrl'];
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Foto profil berhasil diupload!"), backgroundColor: Colors.green),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Gagal upload foto ke server"), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isUploadingImage = false);
      print("Error picking image: $e");
    }
  }

  Future<void> _saveProfile() async {
    if (_sessionKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session Key wajib diisi untuk konfirmasi!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSavingProfile = true);

    try {
      final res = await http.post(
        Uri.parse("${Api.baseUrl}/api/updateProfile"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': widget.username,
          'sessionKey': _sessionKeyController.text.trim(),
          'displayName': _displayNameController.text.trim(),
          'bio': _bioController.text.trim(),
        }),
      );

      final json = jsonDecode(res.body);
      if (json["success"] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile berhasil diperbarui!"), backgroundColor: Colors.green),
          );
          _sessionKeyController.clear();
          FocusScope.of(context).unfocus();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: ${json["message"] ?? 'Unknown error'}"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) setState(() => _isSavingProfile = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: accentCyan),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "MY PROFILE",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgDark, primaryCyan.withOpacity(0.1), bgDark],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Avatar
              Center(
                child: GestureDetector(
                  onTap: _isUploadingImage ? null : _showImageSourceDialog,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [primaryCyan, accentCyan]),
                          boxShadow: [BoxShadow(color: primaryCyan.withOpacity(0.5), blurRadius: 20, spreadRadius: 2)],
                        ),
                        child: ClipOval(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Logika nampilin foto: Prioritas lokal, kalo ga ada pake network, kalo ga ada pake icon
                              if (_profileImage != null)
                                Image.file(_profileImage!, fit: BoxFit.cover, width: 120, height: 120)
                              else if (_networkImageUrl != null && _networkImageUrl!.isNotEmpty)
                                Image.network(_networkImageUrl!, fit: BoxFit.cover, width: 120, height: 120)
                              else
                                Icon(FontAwesomeIcons.userAstronaut, size: 50, color: Colors.white.withOpacity(0.8)),

                              // Loading indicator pas upload
                              if (_isUploadingImage)
                                Container(
                                  color: Colors.black54,
                                  child: CircularProgressIndicator(color: accentCyan),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentCyan,
                            shape: BoxShape.circle,
                            border: Border.all(color: bgDark, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              
              Text(
                _displayNameController.text.isNotEmpty ? _displayNameController.text : widget.username,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'),
              ),
              Text(
                widget.role.toUpperCase(),
                style: TextStyle(color: accentCyan, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.5),
              ),

              const SizedBox(height: 30),

              // Info Cards
              Row(
                children: [
                  Expanded(child: _buildInfoCard(icon: Icons.person_outline, label: "Username", value: _censorText(widget.username))),
                  const SizedBox(width: 15),
                  Expanded(child: _buildInfoCard(icon: Icons.lock_outline, label: "Password", value: _censorText(widget.password, isPassword: true))),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildInfoCard(icon: Icons.verified_user_outlined, label: "Role", value: widget.role.toUpperCase())),
                  const SizedBox(width: 15),
                  Expanded(child: _buildInfoCard(icon: Icons.calendar_today_outlined, label: "Expired", value: widget.expiredDate)),
                ],
              ),
              const SizedBox(height: 15),
              _buildInfoCard(icon: Icons.vpn_key, label: "Session Key", value: "${widget.sessionKey.substring(0, 8)}..."),

              const SizedBox(height: 40),


              const SizedBox(height: 20),

              // Change Password Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.lock_reset, color: Colors.white),
                  label: const Text(
                    "CHANGE PASSWORD",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryCyan,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: primaryCyan.withOpacity(0.5),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangePasswordPage(username: widget.username, sessionKey: widget.sessionKey),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: primaryCyan, size: 20),
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: bgDark.withOpacity(0.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderGlass),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentCyan, width: 2),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: cardGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGlass),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryCyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentCyan, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'ShareTechMono'),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
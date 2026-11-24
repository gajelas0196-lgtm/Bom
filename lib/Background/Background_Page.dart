import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'api.dart'; // Sesuaikan path API lo

class _C {
  static const bg        = Color(0xFF060F0A);
  static const surface   = Color(0xFF0C1E14);
  static const card      = Color(0xFF102418);
  static const border    = Color(0xFF1A3D2A);
  static const borderLit = Color(0xFF1E4A35);
  static const red       = Color(0xFF0D6B3E);
  static const redMid    = Color(0xFF15803D);
  static const redLight  = Color(0xFF22C55E);
  static const green     = Color(0xFF22C55E);
  static const blue      = Color(0xFF1B6FBD);
  static const text      = Color(0xFFE2EDF9);
  static const textSub   = Color(0xFF7A9BBF);
  static const textDim   = Color(0xFF3A5470);

  static const LinearGradient btnGrad = LinearGradient(
    colors: [redMid, redLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

final ${Api.baseUrl} = Api.baseUrl;

const List<Color> _presetColors = [
  Color(0xFF0D6B3E), Color(0xFF22C55E), Color(0xFF10B981), Color(0xFF14B8A6),
  Color(0xFF06B6D4), Color(0xFF0EA5E9), Color(0xFF1B6FBD), Color(0xFF6366F1),
  Color(0xFF8B5CF6), Color(0xFFA855F7), Color(0xFFEC4899), Color(0xFFEF4444),
  Color(0xFFF97316), Color(0xFFF59E0B), Color(0xFF1F2937), Color(0xFF000000),
];

String _colorToHex(Color c) {
  final r = (c.r * 255).round();
  final g = (c.g * 255).round();
  final b = (c.b * 255).round();
  return '#${r.toRadixString(16).padLeft(2, '0').toUpperCase()}'
         '${g.toRadixString(16).padLeft(2, '0').toUpperCase()}'
         '${b.toRadixString(16).padLeft(2, '0').toUpperCase()}';
}

Color _hexToColor(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

class BackgroundPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;
  final Function(String? type, String? value)? onBackgroundChanged;

  const BackgroundPage({
    super.key,
    required this.sessionKey,
    required this.username,
    required this.role,
    this.onBackgroundChanged,
  });

  @override
  State<BackgroundPage> createState() => _BackgroundPageState();
}

class _BackgroundPageState extends State<BackgroundPage> {
  int _mode = 0; // 0 = foto, 1 = video, 2 = warna

  File? _selectedImage;
  File? _selectedVideo;
  VideoPlayerController? _selectedVideoCtrl;
  
  String? _currentImageUrl;
  String? _currentVideoUrl;
  String? _currentColorHex;

  int _selectedPresetIndex = 0;
  bool _useCustomColor = false;
  double _hue = 140;

  bool _isSaving = false;
  bool _isLoading = true;

  late PageController _colorCtrl;
  static const int _initialColorPage = 5000;
  double _colorPage = _initialColorPage.toDouble();

  @override
  void initState() {
    super.initState();
    _colorCtrl = PageController(viewportFraction: 0.26, initialPage: _initialColorPage);
    _colorCtrl.addListener(() {
      if (!mounted) return;
      final page = _colorCtrl.page ?? _initialColorPage.toDouble();
      final nearest = page.round();
      final diff = (page - nearest).abs();

      if (diff < 0.4) {
        final idx = nearest % _presetColors.length;
        setState(() {
          _colorPage = page;
          _selectedPresetIndex = idx;
          _useCustomColor = false;
        });
      } else {
        setState(() => _colorPage = page);
      }
    });
    _loadCurrentBackground();
  }

  @override
  void dispose() {
    _colorCtrl.dispose();
    _selectedVideoCtrl?.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentBackground() async {
    try {
      final res = await http.get(
        Uri.parse("${Api.baseUrl}/background/get?username=${widget.username}&key=${widget.sessionKey}"),
      );
      final json = jsonDecode(res.body);
      if (json["success"] == true && json["data"] != null) {
        final data = json["data"];
        setState(() {
          if (data["type"] == "image") {
            _currentImageUrl = data["value"];
            _mode = 0;
          } else if (data["type"] == "video") {
            _currentVideoUrl = data["value"];
            _mode = 1;
          } else if (data["type"] == "color") {
            _currentColorHex = data["value"];
            _mode = 2;
            final color = _hexToColor(data["value"]);
            final hsv = HSVColor.fromColor(color);
            _hue = hsv.hue;
            final idx = _presetColors.indexWhere((c) => _colorToHex(c) == data["value"]);
            if (idx >= 0) {
              _selectedPresetIndex = idx;
              _colorCtrl.jumpToPage(_initialColorPage + idx);
            } else {
              _useCustomColor = true;
            }
          }
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) setState(() => _selectedImage = File(picked.path));
    } catch (e) {
      _showSnack("Gagal memilih foto: $e");
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 30));
      if (picked != null) {
        _selectedVideoCtrl?.dispose();
        _selectedVideo = File(picked.path);
        _selectedVideoCtrl = VideoPlayerController.file(_selectedVideo!)
          ..initialize().then((_) {
            _selectedVideoCtrl!.setLooping(true);
            _selectedVideoCtrl!.setVolume(0);
            _selectedVideoCtrl!.play();
            if (mounted) setState(() {});
          });
        setState(() {});
      }
    } catch (e) {
      _showSnack("Gagal memilih video: $e");
    }
  }

  Future<void> _saveImage() async {
    if (_selectedImage == null) return _showSnack("Pilih foto dulu!");
    setState(() => _isSaving = true);
    try {
      final request = http.MultipartRequest('POST', Uri.parse("${Api.baseUrl}/background/upload-image"));
      request.fields['userId'] = widget.username;
      request.fields['username'] = widget.username;
      request.fields['role'] = widget.role;
      request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));

      final response = await http.Response.fromStream(await request.send());
      final json = jsonDecode(response.body);

      if (json["success"] == true) {
        setState(() {
          _currentImageUrl = json["data"]["value"];
          _selectedImage = null;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('bg_type_${widget.username}', 'image');
        await prefs.setString('bg_value_${widget.username}', _currentImageUrl!);
        
        widget.onBackgroundChanged?.call('image', _currentImageUrl);
        _showSuccessDialog("Background foto berhasil disimpan!");
      } else {
        _showSnack("Gagal: ${json["message"] ?? 'Unknown error'}");
      }
    } catch (e) {
      _showSnack("Error: $e");
    }
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _saveVideo() async {
    if (_selectedVideo == null) return _showSnack("Pilih video dulu!");
    setState(() => _isSaving = true);
    try {
      final request = http.MultipartRequest('POST', Uri.parse("${Api.baseUrl}/background/upload-video"));
      request.fields['userId'] = widget.username;
      request.fields['username'] = widget.username;
      request.fields['role'] = widget.role;
      request.files.add(await http.MultipartFile.fromPath('video', _selectedVideo!.path));

      final response = await http.Response.fromStream(await request.send());
      final json = jsonDecode(response.body);

      if (json["success"] == true) {
        setState(() {
          _currentVideoUrl = json["data"]["value"];
          _selectedVideo = null;
          _selectedVideoCtrl?.dispose();
          _selectedVideoCtrl = null;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('bg_type_${widget.username}', 'video');
        await prefs.setString('bg_value_${widget.username}', _currentVideoUrl!);
        
        widget.onBackgroundChanged?.call('video', _currentVideoUrl);
        _showSuccessDialog("Background video berhasil disimpan!");
      } else {
        _showSnack("Gagal: ${json["message"] ?? 'Unknown error'}");
      }
    } catch (e) {
      _showSnack("Error: $e");
    }
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _saveColor() async {
    final color = _currentColor();
    final hex = _colorToHex(color);
    setState(() => _isSaving = true);
    try {
      final res = await http.post(
        Uri.parse("${Api.baseUrl}/background/set-color"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.username,
          'username': widget.username,
          'role': widget.role,
          'color': hex,
        }),
      );
      final json = jsonDecode(res.body);
      if (json["success"] == true) {
        setState(() => _currentColorHex = hex);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('bg_type_${widget.username}', 'color');
        await prefs.setString('bg_value_${widget.username}', hex);
        
        widget.onBackgroundChanged?.call('color', hex);
        _showSuccessDialog("Background warna berhasil disimpan!");
      } else {
        _showSnack("Gagal: ${json["message"] ?? 'Unknown error'}");
      }
    } catch (e) {
      _showSnack("Error: $e");
    }
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _clearBackground() async {
    setState(() => _isSaving = true);
    try {
      final res = await http.post(
        Uri.parse("${Api.baseUrl}/background/clear"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': widget.username, 'key': widget.sessionKey}),
      );
      final json = jsonDecode(res.body);
      if (json["success"] == true) {
        setState(() {
          _currentImageUrl = null;
          _currentVideoUrl = null;
          _currentColorHex = null;
          _selectedImage = null;
          _selectedVideo = null;
          _selectedVideoCtrl?.dispose();
          _selectedVideoCtrl = null;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('bg_type_${widget.username}');
        await prefs.remove('bg_value_${widget.username}');
        
        widget.onBackgroundChanged?.call(null, null);
        _showSuccessDialog("Background direset ke default!");
      }
    } catch (e) {
      _showSnack("Error: $e");
    }
    if (mounted) setState(() => _isSaving = false);
  }

  Color _currentColor() {
    if (_useCustomColor) return HSVColor.fromAHSV(1.0, _hue, 1.0, 1.0).toColor();
    return _presetColors[_selectedPresetIndex];
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: _C.surface, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccessDialog(String msg) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.transparent,
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
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.green.withOpacity(0.3), width: 1.5),
            boxShadow: [BoxShadow(color: _C.green.withOpacity(0.15), blurRadius: 50)],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.green.withOpacity(0.1),
                border: Border.all(color: _C.green.withOpacity(0.3)),
              ),
              child: Icon(Icons.check_rounded, color: _C.green, size: 26),
            ),
            const SizedBox(height: 16),
            Text("Berhasil", style: TextStyle(color: _C.text, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(msg, textAlign: TextAlign.center, style: TextStyle(color: _C.textSub, fontSize: 13, height: 1.5)),
            const SizedBox(height: 24),
            _GradBtn(label: 'OK', fullWidth: true, onTap: () => Navigator.pop(ctx)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.border),
              ),
              child: Icon(Icons.arrow_back_rounded, color: _C.text, size: 20),
            ),
          ),
        ),
        title: Text("Background", style: TextStyle(color: _C.text, fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          if (_currentImageUrl != null || _currentVideoUrl != null || _currentColorHex != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: _isSaving ? null : _clearBackground,
                child: Container(
                  decoration: BoxDecoration(
                    color: _C.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.border),
                  ),
                  child: Icon(Icons.refresh_rounded, color: _C.textSub, size: 18),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _C.green))
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModeToggle(),
                    const SizedBox(height: 24),
                    _buildPreview(),
                    const SizedBox(height: 28),
                    if (_mode == 0) _buildPhotoMode() 
                    else if (_mode == 1) _buildVideoMode() 
                    else _buildColorMode(),
                    const SizedBox(height: 32),
                    _GradBtn(
                      label: _isSaving
                          ? "Menyimpan..."
                          : (_mode == 0 ? "Upload & Simpan" : _mode == 1 ? "Upload & Simpan" : "Simpan Warna"),
                      fullWidth: true,
                      onTap: _isSaving
                          ? () {}
                          : () {
                              if (_mode == 0) _saveImage();
                              else if (_mode == 1) _saveVideo();
                              else _saveColor();
                            },
                    ),
                    if (_isSaving)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Center(
                          child: SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _C.green),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Expanded(child: _modeTab("Foto", Icons.image_rounded, 0)),
          Expanded(child: _modeTab("Video", Icons.videocam_rounded, 1)),
          Expanded(child: _modeTab("Warna", Icons.palette_rounded, 2)),
        ],
      ),
    );
  }

  Widget _modeTab(String label, IconData icon, int index) {
    final active = _mode == index;
    return GestureDetector(
      onTap: () => setState(() => _mode = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 46,
        decoration: BoxDecoration(
          gradient: active ? _C.btnGrad : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: active ? Colors.white : _C.textSub),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: active ? Colors.white : _C.textSub, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.borderLit),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_mode == 0)
              _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                  : _currentImageUrl != null
                      ? Image.network(_currentImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholderPreview())
                      : _emptyPhotoPreview()
            else if (_mode == 1)
              _selectedVideoCtrl != null && _selectedVideoCtrl!.value.isInitialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _selectedVideoCtrl!.value.size.width,
                        height: _selectedVideoCtrl!.value.size.height,
                        child: VideoPlayer(_selectedVideoCtrl!),
                      ),
                    )
                  : _currentVideoUrl != null
                      ? Image.network(
                          "https://api.ikyyxd.my.id/download/ythumbnaim?url=${_currentVideoUrl}",
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderPreview(),
                        )
                      : _emptyPhotoPreview()
            else
              _buildColorPreview(),

            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.35), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              top: 16, left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_mode == 0 ? Icons.image_rounded : _mode == 1 ? Icons.videocam_rounded : Icons.palette_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _mode == 0 ? "Foto" : _mode == 1 ? "Video" : "Warna  ${_colorToHex(_currentColor())}",
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPreview() {
    final color = _currentColor();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.75), color], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
    );
  }

  Widget _emptyPhotoPreview() {
    return Container(
      color: _C.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_mode == 1 ? Icons.video_library_outlined : Icons.add_photo_alternate_outlined, color: _C.textSub, size: 44),
            const SizedBox(height: 10),
            Text(_mode == 1 ? "Belum ada video" : "Belum ada foto", style: TextStyle(color: _C.textSub, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _placeholderPreview() {
    return Container(color: _C.surface, child: Center(child: Icon(Icons.broken_image, color: _C.textDim, size: 40)));
  }

  Widget _buildPhotoMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Pilih Foto", style: TextStyle(color: _C.text, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text("Unggah foto dari galeri untuk dijadikan background", style: TextStyle(color: _C.textSub, fontSize: 12)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.border, width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _C.green.withOpacity(0.1),
                    border: Border.all(color: _C.green.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.cloud_upload_rounded, color: _C.green, size: 30),
                ),
                const SizedBox(height: 16),
                Text("Tap untuk memilih foto", style: TextStyle(color: _C.text, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text("JPG, PNG • maks 5MB", style: TextStyle(color: _C.textSub, fontSize: 11)),
              ],
            ),
          ),
        ),
        if (_selectedImage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _C.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: _C.green, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text("Foto dipilih, tekan Simpan untuk upload", style: TextStyle(color: _C.green, fontSize: 12))),
                GestureDetector(
                  onTap: () => setState(() => _selectedImage = null),
                  child: Text("Batal", style: TextStyle(color: _C.textSub, fontSize: 12, decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVideoMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Pilih Video", style: TextStyle(color: _C.text, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text("Unggah video pendek (maks 30 detik)", style: TextStyle(color: _C.textSub, fontSize: 12)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _pickVideo,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.border, width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _C.green.withOpacity(0.1),
                    border: Border.all(color: _C.green.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.video_call_rounded, color: _C.green, size: 30),
                ),
                const SizedBox(height: 16),
                Text("Tap untuk memilih video", style: TextStyle(color: _C.text, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text("MP4, MOV • maks 20MB", style: TextStyle(color: _C.textSub, fontSize: 11)),
              ],
            ),
          ),
        ),
        if (_selectedVideo != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _C.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: _C.green, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text("Video dipilih, tekan Simpan untuk upload", style: TextStyle(color: _C.green, fontSize: 12))),
                GestureDetector(
                  onTap: () {
                    _selectedVideoCtrl?.dispose();
                    setState(() {
                      _selectedVideo = null;
                      _selectedVideoCtrl = null;
                    });
                  },
                  child: Text("Batal", style: TextStyle(color: _C.textSub, fontSize: 12, decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildColorMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Pilih Warna", style: TextStyle(color: _C.text, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text("Geser buletan warna-warni untuk memilih", style: TextStyle(color: _C.textSub, fontSize: 12)),
        const SizedBox(height: 24),
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _colorCtrl,
            itemCount: null,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (_, i) {
              final index = i % _presetColors.length;
              final color = _presetColors[index];

              final diff = (_colorPage - i.toDouble()).abs();
              final scale = (1 - diff * 0.12).clamp(0.72, 1.0);
              final isActive = diff < 0.5;

              return AnimatedBuilder(
                animation: _colorCtrl,
                builder: (context, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: GestureDetector(
                  onTap: () {
                    _colorCtrl.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(color: isActive ? Colors.white : Colors.white24, width: isActive ? 4 : 2),
                      boxShadow: isActive
                          ? [BoxShadow(color: color.withOpacity(0.55), blurRadius: 28, spreadRadius: 4)]
                          : [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
                    ),
                    child: isActive ? Center(child: Icon(Icons.check_rounded, color: Colors.white, size: 38)) : null,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentColor(),
                    border: Border.all(color: Colors.white30),
                    boxShadow: [BoxShadow(color: _currentColor().withOpacity(0.4), blurRadius: 8)],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _colorToHex(_currentColor()),
                  style: TextStyle(color: _C.text, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Icon(Icons.tune_rounded, color: _C.textSub, size: 16),
            const SizedBox(width: 8),
            Text("Atur Warna Custom", style: TextStyle(color: _C.text, fontSize: 14, fontWeight: FontWeight.w700)),
            const Spacer(),
            if (_useCustomColor)
              GestureDetector(
                onTap: () {
                  setState(() => _useCustomColor = false);
                  _colorCtrl.animateToPage(_initialColorPage + _selectedPresetIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
                },
                child: Text("Reset", style: TextStyle(color: _C.green, fontSize: 12, decoration: TextDecoration.underline)),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _buildHueSlider(),
      ],
    );
  }

  Widget _buildHueSlider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (details) {
            final ratio = (details.localPosition.dx / width).clamp(0.0, 1.0);
            setState(() {
              _hue = ratio * 360;
              _useCustomColor = true;
            });
          },
          onPanUpdate: (details) {
            final ratio = (details.localPosition.dx / width).clamp(0.0, 1.0);
            setState(() {
              _hue = ratio * 360;
              _useCustomColor = true;
            });
          },
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: List.generate(13, (i) => HSVColor.fromAHSV(1.0, (i * 30).toDouble(), 1.0, 1.0).toColor()),
              ),
              border: Border.all(color: Colors.white12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: (_hue / 360) * (width - 40),
                  top: 4,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: HSVColor.fromAHSV(1.0, _hue, 1.0, 1.0).toColor(),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GradBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;
  const _GradBtn({required this.label, required this.onTap, this.fullWidth = false});

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
          height: 50,
          width: widget.fullWidth ? double.infinity : null,
          padding: widget.fullWidth ? null : const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: _C.btnGrad,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _down ? [] : [BoxShadow(color: _C.redMid.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Center(
            child: Text(widget.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ),
    );
  }
}
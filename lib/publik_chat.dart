import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api.dart';

final baseUrl = Api.baseUrl;

// ==========================================================
// HELPER FUNCTIONS
// ==========================================================
String _getWsUrl() {
  String url = Api.baseUrl;
  if (url.startsWith('https')) return 'wss://${url.substring(8)}';
  if (url.startsWith('http')) return 'ws://${url.substring(7)}';
  return 'ws://serverptrerodactyl.smasnug.web.id:2581';
}

bool _isImageUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final lower = url.toLowerCase();
  return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.gif') || lower.endsWith('.webp');
}

bool _isVideoUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final lower = url.toLowerCase();
  return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.webm');
}

String _formatTime(String? timestamp) {
  if (timestamp == null || timestamp.isEmpty) return '';
  try {
    final dt = DateTime.parse(timestamp);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return '';
  }
}

// ==========================================================
// MODELS
// ==========================================================
class ChatMessage {
  final String id, userId, username, displayName, role, timestamp, avatarUrl;
  final String? message, imageUrl, voiceUrl, videoUrl, profileImageUrl;
  final bool isDeleted;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.role,
    required this.timestamp,
    required this.avatarUrl,
    required this.isDeleted,
    this.message,
    this.imageUrl,
    this.voiceUrl,
    this.videoUrl,
    this.profileImageUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? json['username']?.toString() ?? 'Unknown',
      role: json['role']?.toString() ?? 'Member',
      message: json['message']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      voiceUrl: json['voiceUrl']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
      timestamp: json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      avatarUrl: json['avatarUrl']?.toString() ?? 'assets/images/logo.jpg',
      profileImageUrl: json['profileImageUrl']?.toString(),
      isDeleted: json['isDeleted'] ?? false,
    );
  }
}

class UserModel {
  final String username;
  final String displayName;
  final String role;
  final String? profileImageUrl;

  UserModel({
    required this.username,
    required this.displayName,
    required this.role,
    this.profileImageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? json['username']?.toString() ?? 'Unknown',
      role: json['role']?.toString() ?? 'Member',
      profileImageUrl: json['profileImageUrl']?.toString(),
    );
  }
}

// ==========================================================
// MAIN COMMUNITY PAGE
// ==========================================================
class CommunityPage extends StatefulWidget {
  final String username, role, sessionKey;
  const CommunityPage({
    super.key,
    required this.username,
    required this.role,
    required this.sessionKey,
  });

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color accent = const Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Community Chat",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(width: 3.0, color: accent),
            insets: const EdgeInsets.symmetric(horizontal: 50.0),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: "GLOBAL"),
            Tab(text: "PRIVATE"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          GlobalChatTab(username: widget.username, role: widget.role),
          PrivateChatTab(username: widget.username, sessionKey: widget.sessionKey),
        ],
      ),
    );
  }
}

// ==========================================================
// GLOBAL CHAT TAB
// ==========================================================
class GlobalChatTab extends StatefulWidget {
  final String username, role;
  const GlobalChatTab({super.key, required this.username, required this.role});

  @override
  State<GlobalChatTab> createState() => _GlobalChatTabState();
}

class _GlobalChatTabState extends State<GlobalChatTab> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final Color accent = const Color(0xFF22C55E);

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _hasError = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadMessages(isBackground: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _loadMessages({bool isBackground = false}) async {
    if (!isBackground) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final res = await http.get(Uri.parse('${Api.baseUrl}/chat/messages')).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200 && mounted) {
        dynamic decoded = json.decode(res.body);
        List<dynamic> data = [];
        
        // Deep parser biar ga error walau format server beda
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map) {
          if (decoded.containsKey('messages') && decoded['messages'] is List) {
            data = decoded['messages'];
          } else if (decoded.containsKey('data') && decoded['data'] is List) {
            data = decoded['data'];
          } else if (decoded.containsKey('success') && decoded['success'] == true) {
            if (decoded.containsKey('messages') && decoded['messages'] is List) {
              data = decoded['messages'];
            }
          }
        }

        setState(() {
          _messages = data.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList();
          _isLoading = false;
          _hasError = false;
        });
        _scrollToBottom();
      } else {
        if (mounted && !isBackground) setState(() => _hasError = true);
      }
    } catch (e) {
      if (mounted && !isBackground) setState(() => _hasError = true);
    } finally {
      if (mounted && !isBackground) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    _msgCtrl.clear();
    setState(() => _isSending = true);

    try {
      final response = await http.post(
        Uri.parse('${Api.baseUrl}/chat/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': widget.username,
          'username': widget.username,
          'role': widget.role,
          'message': text,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _loadMessages(isBackground: true);
      } else {
        _showError("Gagal mengirim pesan (${response.statusCode})");
      }
    } catch (e) {
      _showError("Error jaringan: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendMedia(bool isVideo) async {
    try {
      final XFile? file = isVideo
          ? await _picker.pickVideo(source: ImageSource.gallery)
          : await _picker.pickImage(source: ImageSource.gallery);

      if (file == null) return;

      setState(() => _isSending = true);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Api.baseUrl}/chat/upload-${isVideo ? 'video' : 'image'}'),
      );

      request.files.add(await http.MultipartFile.fromPath(
        isVideo ? 'video' : 'image',
        file.path,
      ));

      request.fields['userId'] = widget.username;
      request.fields['username'] = widget.username;
      request.fields['role'] = widget.role;

      final response = await request.send().timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        _loadMessages(isBackground: true);
      } else {
        _showError("Gagal upload media (${response.statusCode})");
      }
    } catch (e) {
      _showError("Error upload: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _saveMedia(String url, bool isVideo) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.${isVideo ? 'mp4' : 'jpg'}');
        await file.writeAsBytes(res.bodyBytes);
        if (isVideo) {
          await GallerySaver.saveVideo(file.path);
        } else {
          await GallerySaver.saveImage(file.path);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${isVideo ? 'Video' : 'Foto'} berhasil disimpan'),
              backgroundColor: accent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan media'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (_, __) {
        bool isMe = __ % 2 == 0;
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            width: MediaQuery.of(context).size.width * 0.6,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, color: Colors.white30, size: 60),
          const SizedBox(height: 16),
          const Text(
            "Gagal memuat pesan",
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _loadMessages(),
            icon: const Icon(Icons.refresh),
            label: const Text("Coba Lagi"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_rounded, color: accent.withOpacity(0.3), size: 60),
          const SizedBox(height: 16),
          const Text(
            "Belum ada pesan",
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "Mulai percakapan sekarang!",
            style: TextStyle(color: Colors.white30, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color c = role.toLowerCase() == 'developer'
        ? Colors.purple
        : role.toLowerCase() == 'owner'
            ? Colors.orange
            : role.toLowerCase() == 'admin'
                ? Colors.red
                : Colors.blueGrey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.withOpacity(0.5)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(color: c, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.userId == widget.username;
    bool hasImage = (msg.imageUrl != null && msg.imageUrl!.isNotEmpty) || _isImageUrl(msg.message);
    bool hasVideo = (msg.videoUrl != null && msg.videoUrl!.isNotEmpty) || _isVideoUrl(msg.message);
    String? mediaUrl = msg.imageUrl ?? msg.videoUrl ?? (hasImage || hasVideo ? msg.message : null);

    if (msg.isDeleted) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, color: Colors.grey.shade600, size: 16),
              const SizedBox(width: 8),
              Text(
                "Pesan ini dihapus",
                style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Colors.teal, Colors.green.shade800]),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: ClipOval(
                child: msg.profileImageUrl != null && msg.profileImageUrl!.isNotEmpty
                    ? Image.network(
                        msg.profileImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 18),
                      )
                    : const Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? accent.withOpacity(0.9) : const Color(0xFF1A2520),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              msg.displayName.isNotEmpty ? msg.displayName : msg.username,
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildRoleBadge(msg.role),
                        ],
                      ),
                    ),
                  if (hasImage && mediaUrl != null) ...[
                    GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: Stack(
                            children: [
                              InteractiveViewer(child: Image.network(mediaUrl, fit: BoxFit.contain)),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.download, color: Colors.white),
                                  ),
                                  onPressed: () => _saveMedia(mediaUrl, false),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          mediaUrl,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, p) => p == null
                              ? child
                              : const SizedBox(
                                  height: 200,
                                  width: 200,
                                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                                ),
                        ),
                      ),
                    ),
                  ] else if (hasVideo && mediaUrl != null) ...[
                    GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: VideoPlayerWidget(videoUrl: mediaUrl, onSave: () => _saveMedia(mediaUrl, true)),
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 200,
                          height: 150,
                          color: Colors.black54,
                          child: const Center(
                            child: Icon(Icons.play_circle_filled, color: Colors.white, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ] else if (msg.message != null && msg.message!.isNotEmpty) ...[
                    SelectableText(
                      msg.message!,
                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatTime(msg.timestamp),
                      style: TextStyle(
                        color: isMe ? Colors.white70 : Colors.white54,
                        fontSize: 10,
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

  Widget _buildInputBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF121B16),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.image_rounded, color: accent),
            onPressed: _isSending ? null : () => _sendMedia(false),
          ),
          IconButton(
            icon: Icon(Icons.videocam_rounded, color: accent),
            onPressed: _isSending ? null : () => _sendMedia(true),
          ),
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              onSubmitted: (_) => _sendText(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [accent, Colors.green.shade700]),
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _isSending ? null : _sendText,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: accent,
            backgroundColor: const Color(0xFF121B16),
            onRefresh: () => _loadMessages(),
            child: _isLoading
                ? _buildLoadingShimmer()
                : _hasError
                    ? _buildErrorState()
                    : _messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.only(bottom: 20, top: 10),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) => _buildMessageBubble(_messages[i]),
                          ),
          ),
        ),
        _buildInputBar(),
      ],
    );
  }
}

// ==========================================================
// PRIVATE CHAT TAB (SEARCH + LIST)
// ==========================================================
class PrivateChatTab extends StatefulWidget {
  final String username, sessionKey;
  const PrivateChatTab({super.key, required this.username, required this.sessionKey});

  @override
  State<PrivateChatTab> createState() => _PrivateChatTabState();
}

class _PrivateChatTabState extends State<PrivateChatTab> {
  List<UserModel> _users = [];
  List<UserModel> _filtered = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();
  final Color accent = const Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchCtrl.addListener(() {
      setState(() {
        _filtered = _users
            .where((u) =>
                u.username.toLowerCase().contains(_searchCtrl.text.toLowerCase()) ||
                u.displayName.toLowerCase().contains(_searchCtrl.text.toLowerCase()))
            .toList();
      });
    });
  }

  Future<void> _fetchUsers() async {
    try {
      final res = await http.get(Uri.parse('${Api.baseUrl}/api/chatUsers')).timeout(const Duration(seconds: 10));
      final decoded = jsonDecode(res.body);

      if (decoded['success'] == true && mounted) {
        List<dynamic> usersJson = decoded['users'] ?? [];
        setState(() {
          _users = usersJson
              .map((u) => UserModel.fromJson(u as Map<String, dynamic>))
              .where((u) => u.username != widget.username)
              .toList();
          _filtered = _users;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: accent));
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF121B16),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, color: Colors.white54),
              hintText: 'Cari username...',
              hintStyle: TextStyle(color: Colors.white38),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            ),
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? const Center(
                  child: Text(
                    "User tidak ditemukan",
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final u = _filtered[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121B16),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [Colors.teal, Colors.green.shade800]),
                          ),
                          child: ClipOval(
                            child: u.profileImageUrl != null && u.profileImageUrl!.isNotEmpty
                                ? Image.network(
                                    u.profileImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                                  )
                                : const Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                        title: Text(
                          u.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          "@${u.username} • ${u.role.toUpperCase()}",
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PrivateChatRoom(
                              myUsername: widget.username,
                              targetUsername: u.username,
                              targetDisplayName: u.displayName,
                              targetProfileUrl: u.profileImageUrl,
                              sessionKey: widget.sessionKey,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ==========================================================
// PRIVATE CHAT ROOM (MEDIA + WS)
// ==========================================================
class PrivateChatRoom extends StatefulWidget {
  final String myUsername, targetUsername, targetDisplayName, sessionKey;
  final String? targetProfileUrl;

  const PrivateChatRoom({
    super.key,
    required this.myUsername,
    required this.targetUsername,
    required this.targetDisplayName,
    required this.sessionKey,
    this.targetProfileUrl,
  });

  @override
  State<PrivateChatRoom> createState() => _PrivateChatRoomState();
}

class _PrivateChatRoomState extends State<PrivateChatRoom> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();
  late WebSocketChannel _channel;
  List<Map<String, dynamic>> _messages = [];
  bool _isConnected = false;
  bool _isSending = false;
  final Color accent = const Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();
    _connectWs();
  }

  void _connectWs() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_getWsUrl()));
      _channel.sink.add(jsonEncode({'type': 'auth', 'key': widget.sessionKey}));
      _channel.sink.add(jsonEncode({'type': 'getMessages', 'with': widget.targetUsername}));

      _channel.stream.listen(
        (event) {
          final data = jsonDecode(event);
          if (data['type'] == 'messages') {
            setState(() {
              _messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);
              _isConnected = true;
            });
            _scrollToBottom();
          } else if (data['type'] == 'chat') {
            final msg = data['message'] as Map<String, dynamic>;
            final isRelevant = (msg['from'] == widget.targetUsername && msg['to'] == widget.myUsername) ||
                (msg['from'] == widget.myUsername && msg['to'] == widget.targetUsername);
            if (isRelevant) {
              setState(() => _messages.add(msg));
              _scrollToBottom();
            }
          }
        },
        onError: (_) => setState(() => _isConnected = false),
        onDone: () => setState(() => _isConnected = false),
      );
    } catch (_) {
      setState(() => _isConnected = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendMedia(bool isVideo) async {
    try {
      final XFile? file = isVideo
          ? await _picker.pickVideo(source: ImageSource.gallery)
          : await _picker.pickImage(source: ImageSource.gallery);

      if (file == null) return;
      setState(() => _isSending = true);

      // UBAH KE ENDPOINT BACKGROUND BIAR GA MASUK GLOBAL CHAT
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Api.baseUrl}/background/upload-${isVideo ? 'video' : 'image'}'),
      );

      request.files.add(await http.MultipartFile.fromPath(
        isVideo ? 'video' : 'image',
        file.path,
      ));

      request.fields['userId'] = widget.myUsername;
      request.fields['username'] = widget.myUsername;
      request.fields['role'] = 'user';

      final response = await request.send().timeout(const Duration(seconds: 30));
      final responseData = await response.stream.toBytes();
      final jsonString = String.fromCharCodes(responseData);
      final json = jsonDecode(jsonString);

      if (json['success'] == true && _isConnected) {
        // Ambil URL dari response background
        final String url = json['data']?['value']?.toString() ?? '';
        
        if (url.isNotEmpty) {
          _channel.sink.add(jsonEncode({
            'type': 'chat',
            'to': widget.targetUsername,
            'message': url,
            'mediaType': isVideo ? 'video' : 'image',
          }));
        } else {
          _showError("URL media tidak ditemukan dari server");
        }
      } else {
        _showError("Gagal upload media private");
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _sendText() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || !_isConnected) return;

    _channel.sink.add(jsonEncode({
      'type': 'chat',
      'to': widget.targetUsername,
      'message': text,
      'mediaType': 'text',
    }));

    _msgCtrl.clear();
    _scrollToBottom();
    
    // HAPUS Optimistic UI update biar pesan tidak dobel karena server mengirim balik pesan kita
  }

  @override
  void dispose() {
    _channel.sink.close();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final isMe = msg['from'] == widget.myUsername;
    String content = msg['message']?.toString() ?? '';
    String mediaType = msg['mediaType']?.toString() ?? 'text';

    if (mediaType == 'text') {
      if (_isImageUrl(content)) mediaType = 'image';
      else if (_isVideoUrl(content)) mediaType = 'video';
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? accent.withOpacity(0.9) : const Color(0xFF1A2520),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (mediaType == 'image') ...[
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: InteractiveViewer(child: Image.network(content, fit: BoxFit.contain)),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    content,
                    width: 180,
                    height: 180,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, p) => p == null
                        ? child
                        : const SizedBox(
                            height: 180,
                            width: 180,
                            child: Center(child: CircularProgressIndicator(color: Colors.white)),
                          ),
                  ),
                ),
              ),
            ] else if (mediaType == 'video') ...[
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: VideoPlayerWidget(videoUrl: content, onSave: () {}),
                    ),
                  ),
                ),
                child: Container(
                  width: 180,
                  height: 150,
                  color: Colors.black54,
                  child: const Center(
                    child: Icon(Icons.play_circle_filled, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ] else ...[
              Text(
                content,
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatTime(msg['time']?.toString()),
              style: TextStyle(color: isMe ? Colors.white70 : Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF121B16),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.image_rounded, color: accent),
            onPressed: _isSending ? null : () => _sendMedia(false),
          ),
          IconButton(
            icon: Icon(Icons.videocam_rounded, color: accent),
            onPressed: _isSending ? null : () => _sendMedia(true),
          ),
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              onSubmitted: (_) => _sendText(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [accent, Colors.green.shade700]),
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _isSending ? null : _sendText,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121B16),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Colors.teal, Colors.green.shade800]),
              ),
              child: ClipOval(
                child: widget.targetProfileUrl != null && widget.targetProfileUrl!.isNotEmpty
                    ? Image.network(
                        widget.targetProfileUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                      )
                    : const Icon(Icons.person, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.targetDisplayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isConnected ? accent : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isConnected ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: _isConnected ? accent : Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      "Mulai chat dengan ${widget.targetDisplayName}",
                      style: const TextStyle(color: Colors.white30),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _buildBubble(_messages[i]),
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }
}

// ==========================================================
// VIDEO PLAYER WIDGET
// ==========================================================
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onSave;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.onSave,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _ctrl;
  ChewieController? _chewie;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _ctrl.initialize();
      _chewie = ChewieController(
        videoPlayerController: _ctrl,
        autoPlay: true,
        looping: false,
        aspectRatio: _ctrl.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF22C55E),
          handleColor: const Color(0xFF4ADE80),
          bufferedColor: Colors.white.withOpacity(0.3),
          backgroundColor: Colors.white.withOpacity(0.1),
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _chewie?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_error != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                "Gagal memuat video",
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _initVideo();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                ),
                child: const Text("Coba Lagi"),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        if (_chewie != null) Chewie(controller: _chewie!),
        if (widget.onSave != null)
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.download, color: Colors.white),
              ),
              onPressed: widget.onSave,
            ),
          ),
      ],
    );
  }
}
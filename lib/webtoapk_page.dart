import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class WebToApkPage extends StatefulWidget {
  const WebToApkPage({super.key});

  @override
  State<WebToApkPage> createState() => _WebToApkPageState();
}

class _WebToApkPageState extends State<WebToApkPage>
    with SingleTickerProviderStateMixin {
  final _url = TextEditingController();
  final _name = TextEditingController();
  final _icon = TextEditingController();
  final _package = TextEditingController();

  bool loading = false;
  bool downloading = false;
double downloadProgress = 0;
  String progress = "";
  int currentStep = 0;

  Map<String, dynamic>? result;
  String runtime = "";

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _buildSteps = [
    "Validating input data",
    "Connecting to build server",
    "Sending build request",
    "Downloading web assets",
    "Compiling APK resources",
    "Generating APK signature",
    "Packaging final APK",
    "Finalizing build",
  ];

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    _icon.addListener(() {
      setState(() {});
    });
  }

  void _setStepFromProgress(String p) {
    int idx = 0;
    if (p.contains("Validating")) idx = 0;
    else if (p.contains("Connecting")) idx = 1;
    else if (p.contains("Sending")) idx = 2;
    else if (p.contains("Building")) idx = 3;
    else if (p.contains("Success")) idx = _buildSteps.length;

    if (idx > currentStep) {
      setState(() {
        currentStep = idx;
      });
    }
  }

  Future<void> buildApk() async {
    if (_url.text.isEmpty ||
        _name.text.isEmpty ||
        _icon.text.isEmpty ||
        _package.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lengkapi semua data.")),
      );
      return;
    }

    setState(() {
      loading = true;
      progress = "Validating...";
      result = null;
      currentStep = 0;
    });

    try {
      setState(() {
        progress = "Connecting Server...";
      });
      _setStepFromProgress(progress);

      await Future.delayed(
        const Duration(milliseconds: 500),
      );
      final uri = Uri.parse(
        "https://api.ikyyxd.my.id/tools/web2apk"
        "?url=${Uri.encodeComponent(_url.text)}"
        "&icon=${Uri.encodeComponent(_icon.text)}"
        "&name=${Uri.encodeComponent(_name.text)}"
        "&package=${Uri.encodeComponent(_package.text)}",
      );

      setState(() {
        progress = "Sending Request...";
      });
      _setStepFromProgress(progress);

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      final res = await http.get(uri);
      setState(() {
        progress = "Building APK...";
      });
      _setStepFromProgress(progress);
      final json = jsonDecode(res.body);

      if (json["status"] == true) {
        setState(() {
          progress = "Build Success";
          result = json["result"];
          runtime = json["runtime"] ?? "";
          currentStep = _buildSteps.length;
        });
        _animController.forward();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(json["message"] ?? "Build gagal")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> downloadApk() async {
  if (result == null) return;

  try {
    setState(() {
      downloading = true;
      downloadProgress = 0;
    });

    final dir = await getApplicationDocumentsDirectory();

    final savePath =
        "${dir.path}/${result!["appName"]}.apk";

    await Dio().download(
      result!["downloadUrl"],
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          setState(() {
            downloadProgress = received / total;
          });
        }
      },
    );

    setState(() {
      downloading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("APK berhasil didownload"),
      ),
    );

    OpenFilex.open(savePath);
  } catch (e) {
    setState(() {
      downloading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}

  Widget buildField(
    String title,
    IconData icon,
    TextEditingController controller, {
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xff183426),
            labelText: title,
            labelStyle: const TextStyle(color: Colors.white70),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon: Icon(
              icon,
              color: Colors.greenAccent,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Colors.greenAccent,
                width: 2,
              ),
            ),
          ),
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStepList() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff10291F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.greenAccent.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.engineering,
                color: Colors.greenAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "Build Process",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Text(
                    "${(currentStep / _buildSteps.length * 100).round()}%",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: currentStep / _buildSteps.length,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 18),
          ...List.generate(_buildSteps.length, (i) {
            final isDone = i < currentStep;
            final isCurrent = i == currentStep && loading;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrent
                    ? Colors.greenAccent.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrent
                      ? Colors.greenAccent.withOpacity(0.4)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  if (isDone)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.greenAccent,
                      size: 20,
                    )
                  else if (isCurrent)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.greenAccent,
                      ),
                    )
                  else
                    Icon(
                      Icons.radio_button_unchecked,
                      color: Colors.white.withOpacity(0.25),
                      size: 20,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _buildSteps[i],
                      style: TextStyle(
                        color: isDone
                            ? Colors.white
                            : isCurrent
                                ? Colors.greenAccent
                                : Colors.white.withOpacity(0.4),
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget infoTile(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff183426),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.greenAccent.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.greenAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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
  void dispose() {
    _url.dispose();
    _name.dispose();
    _icon.dispose();
    _package.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xff183426),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xff214535),
                Color(0xff183426),
              ],
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.android,
                color: Colors.greenAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Web To APK",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff10291F),
              Color(0xff183426),
              Color(0xff0a1d16),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xff214535),
                      Color(0xff183426),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color:
                                  Colors.greenAccent.withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.rocket_launch,
                            color: Colors.greenAccent,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Convert Web to APK",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Build Android APK from your website in seconds",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Form Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xff214535),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    buildField(
                      "Website URL",
                      Icons.language,
                      _url,
                      hint: "https://example.com",
                    ),
                    buildField(
                      "APK Name",
                      Icons.android,
                      _name,
                      hint: "My Awesome App",
                    ),
                    buildField(
                      "Icon URL",
                      Icons.image,
                      _icon,
                      hint: "https://example.com/icon.png",
                    ),

                    const SizedBox(height: 10),

                    if (_icon.text.isNotEmpty)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [
                                Colors.greenAccent,
                                Color(0xff183426),
                              ],
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              _icon.text,
                              height: 90,
                              width: 90,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child,
                                  loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 90,
                                  width: 90,
                                  color: const Color(0xff183426),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.greenAccent,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) {
                                return Container(
                                  height: 90,
                                  width: 90,
                                  color: const Color(0xff183426),
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: Colors.white54,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 15),
                    buildField(
                      "Package Name",
                      Icons.inventory_2,
                      _package,
                      hint: "com.example.myapp",
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: loading
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Colors.greenAccent,
                                    Color(0xff2e7d52),
                                  ],
                                ),
                          boxShadow: loading
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.greenAccent
                                        .withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: loading ? null : buildApk,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: loading
                                ? const Color(0xff183426)
                                : Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.greenAccent,
                                  ),
                                )
                              : const Icon(
                                  Icons.build,
                                  color: Colors.white,
                                ),
                          label: Text(
                            loading ? "Building..." : "Start Build",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Build Process
              if (loading) _buildStepList(),

              if (result != null)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xff1b5e3f),
                                Color(0xff214535),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.greenAccent.withOpacity(0.4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent
                                    .withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.greenAccent.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.greenAccent,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                "BUILD SUCCESS",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        infoTile(
                          "APK Name",
                          result!["appName"] ?? "-",
                          Icons.android,
                        ),
                        infoTile(
                          "Package",
                          result!["packageName"] ?? "-",
                          Icons.inventory_2,
                        ),
                        infoTile(
                          "Version",
                          result!["version"] ?? "-",
                          Icons.verified,
                        ),
                        infoTile(
                          "Runtime",
                          runtime,
                          Icons.timer,
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.greenAccent,
                                  Color(0xff2e7d52),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.greenAccent
                                      .withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: downloading ? null : downloadApk,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: downloading
    ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
    : const Icon(
        Icons.download,
        color: Colors.white,
      ),
                              label: Text(
  downloading
      ? "Downloading ${(downloadProgress * 100).toStringAsFixed(0)}%"
      : "Download APK",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
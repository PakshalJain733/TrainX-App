import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final int latestVersionCode;
  final String latestVersionName;
  final String apkUrl;
  final List<String> releaseNotes;
  final bool forceUpdate;

  AppUpdateInfo({
    required this.hasUpdate,
    required this.latestVersionCode,
    required this.latestVersionName,
    required this.apkUrl,
    required this.releaseNotes,
    required this.forceUpdate,
  });
}

class AppUpdateService {
  static const MethodChannel _platformChannel = MethodChannel('com.trainx.app/channel');
  static bool _dialogShowing = false;

  /// Check server for the latest version info
  static Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(
            Uri.parse(AppConstants.appVersionEndpoint),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          final int serverCode = data['versionCode'] is int
              ? data['versionCode']
              : int.tryParse(data['versionCode'].toString()) ?? 1;
          final String serverName = data['versionName']?.toString() ?? '1.0.0';
          final String apkUrl = data['apkUrl']?.toString() ?? AppConstants.fallbackApkUrl;
          final bool force = data['forceUpdate'] == true;

          List<String> notes = [];
          if (data['releaseNotes'] is List) {
            notes = (data['releaseNotes'] as List).map((e) => e.toString()).toList();
          } else if (data['releaseNotes'] is String && (data['releaseNotes'] as String).isNotEmpty) {
            notes = (data['releaseNotes'] as String).split('\n');
          }

          final bool needsUpdate = serverCode > AppConstants.currentVersionCode;

          return AppUpdateInfo(
            hasUpdate: needsUpdate,
            latestVersionCode: serverCode,
            latestVersionName: serverName,
            apkUrl: apkUrl,
            releaseNotes: notes,
            forceUpdate: force,
          );
        }
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Version check failed: $e');
    }
    return null;
  }

  /// Launch download / update via native Intent
  static Future<bool> startUpdate(String apkUrl) async {
    try {
      final targetUrl = apkUrl.isNotEmpty ? apkUrl : AppConstants.fallbackApkUrl;
      final result = await _platformChannel.invokeMethod<bool>('openUrl', {'url': targetUrl});
      return result ?? true;
    } catch (e) {
      debugPrint('[AppUpdateService] Native openUrl error: $e');
      return false;
    }
  }

  /// Check version and prompt if update is available
  static Future<void> checkAndPrompt(
    BuildContext context, {
    bool showNoUpdateToast = false,
  }) async {
    if (_dialogShowing) return;

    final info = await checkForUpdate();

    if (!context.mounted) return;

    if (info != null && info.hasUpdate) {
      showUpdateDialog(context, info);
    } else if (showNoUpdateToast) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
              const SizedBox(width: 10),
              Text(
                'TrainX is up to date (v${AppConstants.currentVersionName})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F2942),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Display the Update Prompt Dialog
  static void showUpdateDialog(BuildContext context, AppUpdateInfo info) {
    if (_dialogShowing) return;
    _dialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (ctx) => PopScope(
        canPop: !info.forceUpdate,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.system_update_rounded,
                        color: Color(0xFF0053C0),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Update Available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'TrainX v${info.latestVersionName} (current: v${AppConstants.currentVersionName})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "What's New:",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),

                // Release Notes List
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: info.releaseNotes.isEmpty
                          ? [
                              const Text(
                                '• Performance improvements and bug fixes',
                                style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                              )
                            ]
                          : info.releaseNotes
                              .map(
                                (note) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '• ',
                                        style: TextStyle(
                                          color: Color(0xFF0053C0),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          note.replaceFirst(RegExp(r'^[•\-\*]\s*'), ''),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF334155),
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!info.forceUpdate) ...[
                      TextButton(
                        onPressed: () {
                          _dialogShowing = false;
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Later',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0053C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text(
                        'Update Now',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      onPressed: () async {
                        _dialogShowing = false;
                        Navigator.pop(ctx);
                        await startUpdate(info.apkUrl);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      _dialogShowing = false;
    });
  }
}

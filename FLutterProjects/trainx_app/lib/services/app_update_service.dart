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

  /// Launch native in-app background download & installer
  static Future<bool> startInAppUpdate(String apkUrl) async {
    try {
      final targetUrl = apkUrl.isNotEmpty ? apkUrl : AppConstants.fallbackApkUrl;
      final result = await _platformChannel.invokeMethod<bool>('startInAppUpdate', {'url': targetUrl});
      return result ?? true;
    } catch (e) {
      debugPrint('[AppUpdateService] Native startInAppUpdate error: $e');
      return false;
    }
  }

  /// Cancel active in-app download
  static Future<void> cancelInAppUpdate() async {
    try {
      await _platformChannel.invokeMethod('cancelInAppUpdate');
    } catch (_) {}
  }

  /// Re-trigger install of previously downloaded APK
  static Future<bool> installDownloadedApk({String? path}) async {
    try {
      final result = await _platformChannel.invokeMethod<bool>('installDownloadedApk', {'path': path});
      return result ?? true;
    } catch (e) {
      debugPrint('[AppUpdateService] Native installDownloadedApk error: $e');
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

  /// Display the In-App Update Dialog with real-time download progress
  static void showUpdateDialog(BuildContext context, AppUpdateInfo info) {
    if (_dialogShowing) return;
    _dialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (ctx) {
        bool isDownloading = false;
        bool isComplete = false;
        String? errorMessage;
        int bytesReceived = 0;
        int totalBytes = 0;
        double progress = 0.0;
        String? downloadedApkPath;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            void setupChannelHandlers() {
              _platformChannel.setMethodCallHandler((call) async {
                if (call.method == 'onProgress') {
                  final args = Map<String, dynamic>.from(call.arguments);
                  final received = (args['received'] as num?)?.toInt() ?? 0;
                  final total = (args['total'] as num?)?.toInt() ?? 0;
                  final pct = (args['percent'] as num?)?.toDouble() ?? 0.0;
                  setDialogState(() {
                    bytesReceived = received;
                    totalBytes = total;
                    progress = pct.clamp(0.0, 1.0);
                  });
                } else if (call.method == 'onComplete') {
                  final args = Map<String, dynamic>.from(call.arguments);
                  final path = args['path']?.toString();
                  setDialogState(() {
                    isDownloading = false;
                    isComplete = true;
                    errorMessage = null;
                    downloadedApkPath = path;
                  });
                } else if (call.method == 'onError') {
                  final args = Map<String, dynamic>.from(call.arguments);
                  final msg = args['message']?.toString() ?? 'Download failed';
                  setDialogState(() {
                    isDownloading = false;
                    errorMessage = msg;
                  });
                }
              });
            }

            void triggerDownload() {
              setupChannelHandlers();
              setDialogState(() {
                isDownloading = true;
                isComplete = false;
                errorMessage = null;
                bytesReceived = 0;
                totalBytes = 0;
                progress = 0.0;
              });
              startInAppUpdate(info.apkUrl);
            }

            return PopScope(
              canPop: !info.forceUpdate && !isDownloading,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop && isDownloading) {
                  cancelInAppUpdate();
                }
              },
              child: Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                elevation: 12,
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
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isComplete
                                  ? const Color(0xFFECFDF5)
                                  : isDownloading
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isComplete
                                  ? Icons.check_circle_rounded
                                  : isDownloading
                                      ? Icons.downloading_rounded
                                      : Icons.system_update_rounded,
                              color: isComplete ? const Color(0xFF10B981) : const Color(0xFF0053C0),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isComplete
                                      ? 'Ready to Install'
                                      : isDownloading
                                          ? 'Downloading Update'
                                          : 'Update Available',
                                  style: const TextStyle(
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

                      const SizedBox(height: 18),

                      // VIEW 1: Downloading in progress
                      if (isDownloading) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    totalBytes > 0
                                        ? '${(bytesReceived / (1024 * 1024)).toStringAsFixed(1)} MB / ${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
                                        : 'Connecting to server...',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0053C0),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress > 0 ? progress : null,
                                  minHeight: 10,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0053C0)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Row(
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF64748B)),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Downloading directly in-app. Installation starts automatically.',
                                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                cancelInAppUpdate();
                                setDialogState(() {
                                  isDownloading = false;
                                });
                              },
                              child: const Text('Cancel Download', style: TextStyle(color: Color(0xFFEF4444))),
                            ),
                          ],
                        ),
                      ]
                      // VIEW 2: Download Complete
                      else if (isComplete) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Download Complete!',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'The package installer has started. If the system prompt did not appear automatically, tap "Install Now" below.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF047857), height: 1.35),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                _dialogShowing = false;
                                Navigator.pop(ctx);
                              },
                              child: const Text('Close', style: TextStyle(color: Color(0xFF64748B))),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.install_mobile_rounded, size: 18),
                              label: const Text(
                                'Install Now',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              onPressed: () {
                                installDownloadedApk(path: downloadedApkPath);
                              },
                            ),
                          ],
                        ),
                      ]
                      // VIEW 3: Initial update prompt or Error
                      else ...[
                        if (errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

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
                              label: Text(
                                errorMessage != null ? 'Retry Update' : 'Update Now',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              onPressed: () {
                                triggerDownload();
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _dialogShowing = false;
    });
  }
}

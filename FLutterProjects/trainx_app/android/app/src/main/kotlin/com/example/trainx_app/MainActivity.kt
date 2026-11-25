package com.example.trainx_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedInputStream
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.trainx.app/channel"
    private var methodChannel: MethodChannel? = null
    private var pendingInstallFile: File? = null
    @Volatile
    private var isDownloadCancelled = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startInAppUpdate" -> {
                    val url = call.argument<String>("url")
                    if (!url.isNullOrEmpty()) {
                        isDownloadCancelled = false
                        startBackgroundDownload(url)
                        result.success(true)
                    } else {
                        result.error("INVALID_URL", "Download URL cannot be empty", null)
                    }
                }
                "cancelInAppUpdate" -> {
                    isDownloadCancelled = true
                    result.success(true)
                }
                "installDownloadedApk" -> {
                    val path = call.argument<String>("path")
                    val file = if (!path.isNullOrEmpty()) File(path) else pendingInstallFile
                    if (file != null && file.exists()) {
                        installApk(file)
                        result.success(true)
                    } else {
                        result.error("FILE_NOT_FOUND", "Downloaded APK file not found", null)
                    }
                }
                "canInstallPackages" -> {
                    val canInstall = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        packageManager.canRequestPackageInstalls()
                    } else {
                        true
                    }
                    result.success(canInstall)
                }
                "openInstallPermissionSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        try {
                            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                data = Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SETTINGS_FAILED", e.message, null)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("OPEN_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_URL", "URL cannot be null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        // If user returns after granting "Allow from this source" permission, resume install
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val file = pendingInstallFile
            if (file != null && file.exists() && packageManager.canRequestPackageInstalls()) {
                pendingInstallFile = null
                installApk(file)
            }
        }
    }

    private fun startBackgroundDownload(downloadUrl: String) {
        thread(start = true, isDaemon = true, name = "TrainXUpdaterThread") {
            var input: InputStream? = null
            var output: FileOutputStream? = null
            try {
                // Target file in app's external files directory or cache
                val targetDir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: cacheDir
                if (!targetDir.exists()) targetDir.mkdirs()
                val targetFile = File(targetDir, "TrainX_update.apk")
                if (targetFile.exists()) targetFile.delete()

                val pair = getConnectedInputStream(downloadUrl)
                input = BufferedInputStream(pair.first)
                output = FileOutputStream(targetFile)

                val totalBytes = pair.second
                val buffer = ByteArray(16384)
                var bytesRead: Int
                var totalRead: Long = 0
                var lastProgressTime: Long = 0

                while (input.read(buffer).also { bytesRead = it } != -1) {
                    if (isDownloadCancelled) {
                        targetFile.delete()
                        runOnUiThread {
                            methodChannel?.invokeMethod("onError", mapOf("message" to "Download cancelled"))
                        }
                        return@thread
                    }

                    output.write(buffer, 0, bytesRead)
                    totalRead += bytesRead

                    val now = System.currentTimeMillis()
                    if (now - lastProgressTime >= 150) {
                        lastProgressTime = now
                        val pct = if (totalBytes > 0) totalRead.toDouble() / totalBytes.toDouble() else 0.0
                        runOnUiThread {
                            methodChannel?.invokeMethod(
                                "onProgress",
                                mapOf(
                                    "received" to totalRead,
                                    "total" to totalBytes,
                                    "percent" to pct
                                )
                            )
                        }
                    }
                }

                output.flush()
                output.close()
                output = null
                input.close()
                input = null

                pendingInstallFile = targetFile

                runOnUiThread {
                    methodChannel?.invokeMethod(
                        "onComplete",
                        mapOf(
                            "path" to targetFile.absolutePath,
                            "size" to targetFile.length()
                        )
                    )
                    installApk(targetFile)
                }
            } catch (e: Exception) {
                runOnUiThread {
                    methodChannel?.invokeMethod(
                        "onError",
                        mapOf("message" to (e.message ?: "Download failed"))
                    )
                }
            } finally {
                try { input?.close() } catch (_: Exception) {}
                try { output?.close() } catch (_: Exception) {}
            }
        }
    }

    private fun getConnectedInputStream(urlStr: String): Pair<InputStream, Long> {
        var currentUrl = urlStr
        var redirects = 0
        while (redirects < 6) {
            val url = URL(currentUrl)
            val connection = url.openConnection() as HttpURLConnection
            connection.instanceFollowRedirects = true
            connection.connectTimeout = 15000
            connection.readTimeout = 40000
            connection.setRequestProperty("User-Agent", "TrainX-Android-InAppUpdater")
            val status = connection.responseCode

            if (status == HttpURLConnection.HTTP_MOVED_PERM ||
                status == HttpURLConnection.HTTP_MOVED_TEMP ||
                status == HttpURLConnection.HTTP_SEE_OTHER ||
                status == 307 || status == 308) {
                val newUrl = connection.getHeaderField("Location")
                if (!newUrl.isNullOrEmpty()) {
                    currentUrl = newUrl
                    redirects++
                    continue
                }
            }

            if (status in 200..299) {
                val length = connection.contentLengthLong
                return Pair(connection.inputStream, length)
            } else {
                throw Exception("Server returned HTTP $status")
            }
        }
        throw Exception("Too many redirects: $urlStr")
    }

    private fun installApk(apkFile: File) {
        try {
            pendingInstallFile = apkFile

            // Check if permission to install unknown apps is granted on Android 8+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                if (!packageManager.canRequestPackageInstalls()) {
                    val settingsIntent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                        data = Uri.parse("package:$packageName")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(settingsIntent)
                    return
                }
            }

            // Launch package installer via FileProvider
            val contentUri: Uri = FileProvider.getUriForFile(
                applicationContext,
                "${applicationContext.packageName}.fileprovider",
                apkFile
            )

            val installIntent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(contentUri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            startActivity(installIntent)
        } catch (e: Exception) {
            android.util.Log.e("TrainXUpdater", "Failed to start package installer", e)
            runOnUiThread {
                methodChannel?.invokeMethod("onError", mapOf("message" to "Installer error: ${e.message}"))
            }
        }
    }
}

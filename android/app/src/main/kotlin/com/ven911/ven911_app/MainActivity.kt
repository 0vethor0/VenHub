package com.ven911.ven911_app

import android.app.Activity
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val INSTALL_REQUEST_CODE = 12345
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.ven911.ven911_app/install",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getApkUri" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrBlank()) {
                        result.error("INVALID", "path required", null)
                        return@setMethodCallHandler
                    }
                    val uri = FileProvider.getUriForFile(
                        this,
                        "${applicationContext.packageName}.fileprovider",
                        File(path),
                    )
                    result.success(uri.toString())
                }
                "installApk" -> {
                    val uri = call.argument<String>("uri")
                    if (uri.isNullOrBlank()) {
                        result.error("INVALID", "uri required", null)
                        return@setMethodCallHandler
                    }
                    pendingResult = result
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(android.net.Uri.parse(uri), "application/vnd.android.package-archive")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                    }
                    try {
                        startActivityForResult(intent, INSTALL_REQUEST_CODE)
                    } catch (e: Exception) {
                        pendingResult = null
                        result.error("INSTALL_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == INSTALL_REQUEST_CODE) {
            val result = pendingResult
            pendingResult = null
            if (result != null) {
                when (resultCode) {
                    Activity.RESULT_OK -> result.success("SUCCESS")
                    Activity.RESULT_CANCELED -> result.success("CANCELLED")
                    else -> result.error("INSTALL_FAILED", "Result code: $resultCode", null)
                }
            }
        }
    }
}

package com.maharashtratyres.maharashtra_tyres

import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "maharashtra_tyres/pdf"
        ).setMethodCallHandler { call, result ->
            if (call.method != "saveAndOpenPdf") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val bytes = call.argument<ByteArray>("bytes")
            val filename = call.argument<String>("filename")
            if (bytes == null || filename.isNullOrBlank()) {
                result.error("invalid_pdf", "PDF data or filename is missing.", null)
                return@setMethodCallHandler
            }

            try {
                result.success(savePdfToDownloads(bytes, filename))
            } catch (error: Exception) {
                result.error("pdf_save_failed", error.message, null)
            }
        }
    }

    private fun savePdfToDownloads(bytes: ByteArray, filename: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false

        val safeFilename = filename
            .replace("/", "_")
            .replace("\\", "_")
            .let { if (it.endsWith(".pdf", ignoreCase = true)) it else "$it.pdf" }
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, safeFilename)
            put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
            put(
                MediaStore.MediaColumns.RELATIVE_PATH,
                "${Environment.DIRECTORY_DOWNLOADS}/Maharashtra Tyres"
            )
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("Could not create the PDF in Downloads.")

        try {
            val output = contentResolver.openOutputStream(uri)
                ?: throw IllegalStateException("Could not write the PDF file.")
            output.use { it.write(bytes) }
            contentResolver.update(
                uri,
                ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) },
                null,
                null
            )

            val viewIntent = Intent(Intent.ACTION_VIEW)
                .setDataAndType(uri, "application/pdf")
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            try {
                startActivity(Intent.createChooser(viewIntent, "Open invoice PDF"))
            } catch (_: Exception) {
                // The PDF is saved even when no PDF viewer is installed.
            }
            return true
        } catch (error: Exception) {
            contentResolver.delete(uri, null, null)
            throw error
        }
    }
}

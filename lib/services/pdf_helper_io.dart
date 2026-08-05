import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<File?> _savePdfToStorage(List<int> bytes, String filename) async {
  try {
    Directory? dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!dir.existsSync()) {
        dir = await getExternalStorageDirectory();
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      dir = await getApplicationDocumentsDirectory();
    } else {
      dir = await getDownloadsDirectory();
    }
    dir ??= await getApplicationDocumentsDirectory();

    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  } catch (e) {
    debugPrint('Storage save error: $e');
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }
}

Future<void> saveAndOpenPdf(List<int> bytes, String filename) async {
  try {
    final file = await _savePdfToStorage(bytes, filename);
    if (file != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          text: 'Invoice PDF: $filename',
        ),
      );
    }
  } catch (e) {
    debugPrint('Local PDF save and open warning: $e');
  }
}

Future<void> sharePdf(List<int> bytes, String filename, {String? text}) async {
  try {
    final file = await _savePdfToStorage(bytes, filename);
    if (file != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          text: text,
        ),
      );
    }
  } catch (e) {
    debugPrint('Local PDF share warning: $e');
  }
}

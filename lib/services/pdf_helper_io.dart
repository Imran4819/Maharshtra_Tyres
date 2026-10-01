import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const _androidPdfChannel = MethodChannel('maharashtra_tyres/pdf');

Future<File?> _savePdfToStorage(List<int> bytes, String filename) async {
  try {
    Directory? dir;
    if (Platform.isIOS || Platform.isMacOS) {
      dir = await getApplicationDocumentsDirectory();
    } else if (Platform.isAndroid) {
      dir = await getExternalStorageDirectory();
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

Future<bool> saveAndOpenPdf(List<int> bytes, String filename) async {
  if (Platform.isAndroid) {
    try {
      final saved = await _androidPdfChannel.invokeMethod<bool>(
        'saveAndOpenPdf',
        {'bytes': Uint8List.fromList(bytes), 'filename': filename},
      );
      if (saved == true) return true;
    } on PlatformException catch (e) {
      debugPrint('Android PDF save warning: ${e.message}');
    } on MissingPluginException {
      // Use the regular share flow on older app installations.
    }
  }

  try {
    final file = await _savePdfToStorage(bytes, filename);
    if (file != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          text: 'Invoice PDF: $filename',
        ),
      );
      return true;
    }
  } catch (e) {
    debugPrint('Local PDF save and open warning: $e');
  }
  return false;
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

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void saveAndOpenPdf(List<int> bytes, String filename) {
  try {
    final file = File(filename);
    file.writeAsBytesSync(bytes);
  } catch (e) {
    // Sandboxed storage safety
    debugPrint('Local PDF save warning: $e');
  }
}

Future<void> sharePdf(List<int> bytes, String filename, {String? text}) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: text,
      ),
    );
  } catch (e) {
    debugPrint('Local PDF share warning: $e');
  }
}

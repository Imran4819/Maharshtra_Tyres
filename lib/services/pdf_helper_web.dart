// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

void saveAndOpenPdf(List<int> bytes, String filename) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  // Open in a new tab
  html.window.open(url, '_blank');
  
  // Trigger download as well
  html.AnchorElement(href: url)
    ..setAttribute("download", filename)
    ..click();
    
  html.Url.revokeObjectUrl(url);
}

Future<void> sharePdf(List<int> bytes, String filename, {String? text}) async {
  try {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(Uint8List.fromList(bytes), name: filename, mimeType: 'application/pdf')],
        text: text,
      ),
    );
  } catch (e) {
    saveAndOpenPdf(bytes, filename);
  }
}

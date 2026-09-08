import 'dart:html' as html;

Future<void> downloadFile(List<int> bytes, String filename) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<void> downloadFromUrl(String url, String filename) async {
  String downloadUrl = url;
  if (url.contains('/upload/') && !url.contains('fl_attachment')) {
    downloadUrl = url.replaceAll('/upload/', '/upload/fl_attachment/');
  }
  final anchor = html.AnchorElement(href: downloadUrl)
    ..setAttribute("download", filename)
    ..target = "_blank";
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
}

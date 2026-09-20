import 'dart:html' as html;

Future<void> downloadFile(List<int> bytes, String filename) async {
  final safeName = filename.replaceAll(RegExp(r'[^\w\s\.-]'), '_').replaceAll(RegExp(r'\s+'), '_');
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", safeName)
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  Future.delayed(const Duration(seconds: 10), () {
    html.Url.revokeObjectUrl(url);
  });
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

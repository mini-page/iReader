import 'package:html/parser.dart' show parse;

String stripHtml(String html) {
  if (html.isEmpty) return html;
  try {
    final document = parse(html);
    final body = document.body;
    if (body != null && body.text.trim().isNotEmpty) {
      return body.text.trim().replaceAll('\u00a0', ' ');
    }
  } catch (_) {}
  final stripped = html.replaceAll(RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true), '');
  return stripped.replaceAll('&nbsp;', ' ').trim();
}

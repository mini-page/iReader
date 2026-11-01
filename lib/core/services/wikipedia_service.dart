import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ireader/core/models/app_failure.dart';
import 'package:ireader/core/models/service_result.dart';
import 'package:ireader/shared/utils/text_utils.dart';

class WikipediaArticle {
  final String title;
  final String extract;
  final String? imageUrl;
  final String? description;

  WikipediaArticle({
    required this.title,
    required this.extract,
    this.imageUrl,
    this.description,
  });

  factory WikipediaArticle.fromJson(Map<String, dynamic> json) {
    return WikipediaArticle(
      title: json['title'] ?? '',
      extract: json['extract'] ?? '',
      description: json['description'],
      imageUrl: json['originalimage']?['source'],
    );
  }
}

class WikipediaService {
  static const _baseUrl = 'https://en.wikipedia.org/api/rest_v1/page/summary';

  Future<ServiceResult<WikipediaArticle>> fetchSummary(String title) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/${Uri.encodeComponent(title)}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ServiceResult.success(WikipediaArticle.fromJson(data));
      }
      return ServiceResult.error(
        AppFailure(
          AppFailureType.network,
          'Wikipedia request failed (${response.statusCode}).',
        ),
      );
    } catch (e) {
      return ServiceResult.error(
        AppFailure(
          AppFailureType.network,
          'Wikipedia request failed: $e',
        ),
      );
    }
  }

  /// Fetches the full content using the mobile-sections endpoint for a complete reading session.
  Future<ServiceResult<String>> fetchFullContent(String title) async {
    try {
      // Using the mobile-sections endpoint to get more than just the summary
      final response = await http.get(Uri.parse(
          'https://en.wikipedia.org/api/rest_v1/page/mobile-sections/${Uri.encodeComponent(title)}'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lead = data['lead'] as Map<String, dynamic>?;
        final leadSections = lead?['sections'] as List<dynamic>?;
        if (leadSections == null || leadSections.isEmpty) {
          final summary = await fetchSummary(title);
          if (summary.isSuccess && summary.requireData.extract.isNotEmpty) {
            return ServiceResult.success(summary.requireData.extract);
          }
          return ServiceResult.error(
            const AppFailure(AppFailureType.parsing, 'Wikipedia article has no lead section.'),
          );
        }
        final leadSection = leadSections[0]['text'] as String? ?? '';
        final remaining = data['remaining'] as Map<String, dynamic>?;
        final remainingSections = remaining?['sections'] as List<dynamic>? ?? [];
        
        StringBuffer fullText = StringBuffer();
        fullText.writeln(stripHtml(leadSection));
        
        for (var section in remainingSections) {
          final sectionTitle = section['line'] ?? '';
          final sectionText = section['text'] ?? '';
          if (sectionTitle.isNotEmpty) {
            fullText.writeln('\n\n$sectionTitle\n');
          }
          fullText.writeln(stripHtml(sectionText));
        }
        
        final text = fullText.toString().trim();
        if (text.isNotEmpty) {
          return ServiceResult.success(text);
        }
      }
    } catch (e) {
      final summary = await fetchSummary(title);
      if (summary.isSuccess && summary.requireData.extract.isNotEmpty) {
        return ServiceResult.success(summary.requireData.extract);
      }
      return ServiceResult.error(
        AppFailure(
          AppFailureType.network,
          'Wikipedia fetch failed: $e',
        ),
      );
    }

    final summary = await fetchSummary(title);
    if (summary.isSuccess && summary.requireData.extract.isNotEmpty) {
      return ServiceResult.success(summary.requireData.extract);
    }
    return ServiceResult.error(
      const AppFailure(
        AppFailureType.parsing,
        'Wikipedia article returned no readable content.',
      ),
    );
  }

}

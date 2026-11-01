import 'package:readability/readability.dart' as readability;
import 'package:ireader/core/models/app_failure.dart';
import 'package:ireader/core/models/service_result.dart';

class ExtractedArticle {
  final String title;
  final String content;
  final String? excerpt;
  final String? siteName;

  ExtractedArticle({
    required this.title,
    required this.content,
    this.excerpt,
    this.siteName,
  });
}

class ArticleService {
  Future<ServiceResult<ExtractedArticle>> extractFromUrl(String url) async {
    try {
      final result = await readability.parseAsync(url);

      final article = ExtractedArticle(
        title: result.title ?? 'Untitled',
        content: result.textContent ?? '',
        excerpt: result.excerpt,
        siteName: result.siteName,
      );
      if (article.content.trim().isEmpty) {
        return ServiceResult.error(
          const AppFailure(
            AppFailureType.parsing,
            'Could not extract main content from this URL.',
          ),
        );
      }
      return ServiceResult.success(article);
    } catch (e) {
      return ServiceResult.error(
        AppFailure(
          AppFailureType.network,
          'Network or parsing error: $e',
        ),
      );
    }
  }
}

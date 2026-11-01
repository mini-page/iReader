import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:ireader/core/models/service_result.dart';
import 'package:ireader/core/providers/app_providers.dart';

final translationProvider =
    FutureProvider.family<ServiceResult<String>, String>((ref, text) async {
  final service = ref.read(translationServiceProvider);
  return service.translate(text);
});

class TargetLanguageNotifier extends Notifier<TranslateLanguage> {
  @override
  TranslateLanguage build() => TranslateLanguage.spanish;
  void setLanguage(TranslateLanguage lang) => state = lang;
}

final targetLanguageProvider = NotifierProvider<TargetLanguageNotifier, TranslateLanguage>(TargetLanguageNotifier.new);

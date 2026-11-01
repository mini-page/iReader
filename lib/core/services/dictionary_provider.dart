import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:ireader/core/models/service_result.dart';
import 'package:ireader/core/providers/app_providers.dart';
import '../services/dictionary_service.dart';

final wordLookupProvider =
    FutureProvider.family<ServiceResult<DictionaryEntry>, String>(
  (ref, word) async {
    final service = ref.read(dictionaryServiceProvider);
    return service.lookup(word);
  },
);

final wordTranslationProvider =
    FutureProvider.family<ServiceResult<String>, String>(
  (ref, word) async {
    final service = ref.read(translationServiceProvider);
    return service.translate(word, target: TranslateLanguage.spanish);
  },
);

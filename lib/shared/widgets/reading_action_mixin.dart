import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:epubx/epubx.dart';
import 'package:image/image.dart' as img;

import 'package:ireader/core/providers/app_providers.dart';
import 'package:ireader/shared/utils/text_utils.dart';
import 'package:ireader/core/services/ai_service.dart';
import 'package:ireader/features/home/data/sessions_provider.dart';
import 'package:ireader/features/library/data/books_provider.dart';
import 'package:ireader/shared/models/book.dart';

mixin ReadingActionMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool isProcessing = false;
  String processingLabel = 'EXTRACTING KNOWLEDGE';

  void setProcessing(bool value, [String label = 'EXTRACTING KNOWLEDGE']) {
    if (mounted) {
      setState(() {
        isProcessing = value;
        processingLabel = label;
      });
    }
  }

  void _showThemedSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message, 
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black, 
            fontWeight: FontWeight.bold,
            fontSize: 13,
          )
        ),
        backgroundColor: isError 
            ? const Color(0xFFFF3B3B) 
            : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 10,
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> handleAiAction(Future<String> Function(AIProvider p) action, String label) async {
    final aiService = ref.read(aiServiceProvider);
    final provider = await aiService.getProvider();
    if (provider == null) {
      if (mounted) _showThemedSnackBar('AI not configured in settings.', isError: true);
      return;
    }

    setProcessing(true, label);
    try {
      final result = await action(provider);
      if (mounted) {
        context.push('/preview', extra: {'title': 'AI Generated', 'content': result, 'id': null});
        ref.invalidate(sessionsProvider);
      }
    } catch (e) {
      if (mounted) _showThemedSnackBar('AI Error: $e', isError: true);
    } finally {
      setProcessing(false);
    }
  }

  Future<void> pickFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom, 
      allowedExtensions: ['txt', 'pdf', 'docx', 'epub'],
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    setProcessing(true, 'EXTRACTING FILES');
    
    final sessionRepo = ref.read(sessionRepositoryProvider);
    final bookRepo = ref.read(bookRepositoryProvider);
    final existingSessions = await sessionRepo.all();
    final existingBooks = await bookRepo.all();
    
    int addedCount = 0;
    int duplicateCount = 0;

    for (final pickedFile in result.files) {
      if (pickedFile.path == null) continue;
      final file = File(pickedFile.path!);
      final extension = pickedFile.extension?.toLowerCase();
      String title = pickedFile.name;
      if (title.contains('.')) {
        title = title.substring(0, title.lastIndexOf('.'));
      }

      try {
        if (extension == 'epub') {
          final isDuplicate = existingBooks.any((b) => b.title == title);
          if (isDuplicate) {
            duplicateCount++;
            continue;
          }

          final bytes = await file.readAsBytes();
          final epubBook = await EpubReader.readBook(bytes);
          
          List<BookChapter> chapters = [];
          void extractChapters(List<EpubChapter> epubChapters) {
            for (var chapter in epubChapters) {
              if (chapter.HtmlContent != null && chapter.HtmlContent!.trim().isNotEmpty) {
                chapters.add(BookChapter(
                  title: chapter.Title ?? 'Untitled Chapter',
                  content: stripHtml(chapter.HtmlContent!),
                ));
              }
              if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
                extractChapters(chapter.SubChapters!);
              }
            }
          }
          
          extractChapters(epubBook.Chapters ?? []);

          if (chapters.isNotEmpty) {
            final newBook = Book(
              id: const Uuid().v4(),
              title: epubBook.Title ?? title,
              author: epubBook.Author ?? 'Unknown',
              cover: epubBook.CoverImage != null ? Uint8List.fromList(img.encodePng(epubBook.CoverImage!)) : null,
              chapters: chapters,
              updatedAt: DateTime.now(),
            );
            await bookRepo.create(newBook);
            addedCount++;
          }
          continue;
        }

        String content = '';
        if (extension == 'txt') {
          content = await file.readAsString();
        } else if (extension == 'pdf') {
          final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
          content = PdfTextExtractor(document).extractText();
          document.dispose();
        } else if (extension == 'docx') {
          content = docxToText(await file.readAsBytes());
        }

        if (content.trim().isNotEmpty) {
          final isDuplicate = existingSessions.any((s) => s.title == title || s.content == content);
          if (!isDuplicate) {
            final newSession = await sessionRepo.create(
              title: title,
              content: content,
              wpm: 250,
            );
            existingSessions.add(newSession);
            addedCount++;
          } else {
            duplicateCount++;
          }
        }
      } catch (e) {
        if (mounted) _showThemedSnackBar('File Error ($title): $e', isError: true);
        continue;
      }
    }

    setProcessing(false);
    
    if (mounted) {
      if (addedCount > 0) {
        _showThemedSnackBar('Imported $addedCount new file(s) to library. ${duplicateCount > 0 ? '($duplicateCount duplicates ignored)' : ''}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.invalidate(sessionsProvider);
            ref.invalidate(booksProvider);
          }
        });
      } else {
        _showThemedSnackBar('No new files imported ($duplicateCount duplicates ignored).');
      }
    }
  }

  void showInputDialog({required String title, required String hint, required String actionLabel, required Function(String) onConfirm}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () { Navigator.pop(context); onConfirm(controller.text.trim()); }, child: Text(actionLabel)),
        ],
      ),
    );
  }

  void showTopicDialog() {
    showInputDialog(
      title: 'AI Topic Generator',
      hint: 'Enter any topic (e.g. Quantum Physics)',
      actionLabel: 'Generate',
      onConfirm: (val) => handleAiAction((p) => p.generateTopic(val), 'RESEARCHING TOPIC'),
    );
  }

  void showWikiDialog() {
    showInputDialog(
      title: 'Wikipedia Fetcher',
      hint: 'Article title...',
      actionLabel: 'Fetch',
      onConfirm: (val) => fetchWikipediaArticle(val),
    );
  }

  void showUrlDialog() {
    showInputDialog(
      title: 'URL Reader',
      hint: 'https://...',
      actionLabel: 'Extract',
      onConfirm: (val) => extractAndRead(val),
    );
  }

  Future<void> extractAndRead(String url) async {
    setProcessing(true, 'PARSING WEBPAGE');
    try {
      final articleResult =
          await ref.read(articleServiceProvider).extractFromUrl(url);
      if (articleResult.isSuccess) {
        final article = articleResult.requireData;
        if (mounted) {
          context.push('/preview', extra: {'title': article.title, 'content': article.content, 'id': null});
          ref.invalidate(sessionsProvider);
        }
      } else {
        if (mounted) {
          _showThemedSnackBar(
            articleResult.failure?.message ??
                'Could not extract main content from this URL.',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) _showThemedSnackBar('Network/Parsing Error: $e', isError: true);
    } finally {
      setProcessing(false);
    }
  }

  Future<void> fetchWikipediaArticle(String title) async {
    setProcessing(true, 'ACCESSING KNOWLEDGE');
    try {
      final result = await ref.read(wikipediaServiceProvider).fetchFullContent(title);
      if (result.isSuccess) {
        if (mounted) {
          context.push('/preview', extra: {
            'title': title,
            'content': result.requireData,
            'id': null,
          });
          ref.invalidate(sessionsProvider);
        }
      } else if (mounted) {
        _showThemedSnackBar(
          result.failure?.message ?? 'Failed to fetch Wikipedia article.',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showThemedSnackBar('Wikipedia Error: $e', isError: true);
      }
    } finally {
      setProcessing(false);
    }
  }
}

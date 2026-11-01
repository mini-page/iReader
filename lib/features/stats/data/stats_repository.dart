import 'package:hive_flutter/hive_flutter.dart';
import '../../../shared/models/reading_stats.dart';

class StatsRepository {
  static const String _boxName = 'stats_box';
  static const String _key = 'reading_stats';

  Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  ReadingStats getStats() {
    final box = Hive.box(_boxName);
    final data = box.get(_key);
    if (data == null) return ReadingStats.initial();
    
    if (data is Map) {
      return ReadingStats(
        totalWordsRead: data['totalWordsRead'] ?? 0,
        totalTimeSeconds: data['totalTimeSeconds'] ?? 0,
        sessionsCount: data['sessionsCount'] ?? 0,
        averageWpm: (data['averageWpm'] ?? 0).toDouble(),
        lastSessionDate: DateTime.parse(data['lastSessionDate'] ?? DateTime.now().toIso8601String()),
        dailyWords: Map<String, int>.from(data['dailyWords'] ?? {}),
      );
    }
    return data as ReadingStats;
  }

  Future<void> saveStats(ReadingStats stats) async {
    final box = Hive.box(_boxName);
    await box.put(_key, {
      'totalWordsRead': stats.totalWordsRead,
      'totalTimeSeconds': stats.totalTimeSeconds,
      'sessionsCount': stats.sessionsCount,
      'averageWpm': stats.averageWpm,
      'lastSessionDate': stats.lastSessionDate.toIso8601String(),
      'dailyWords': stats.dailyWords,
    });
  }

  Future<void> addSession(int words, int seconds, double wpm) async {
    final current = getStats();
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final newDaily = Map<String, int>.from(current.dailyWords);
    newDaily[today] = (newDaily[today] ?? 0) + words;

    final newTotalWords = current.totalWordsRead + words;
    final newTotalTime = current.totalTimeSeconds + seconds;
    final newCount = current.sessionsCount + 1;
    final newAvgWpm = ((current.averageWpm * current.sessionsCount) + wpm) / newCount;

    await saveStats(current.copyWith(
      totalWordsRead: newTotalWords,
      totalTimeSeconds: newTotalTime,
      sessionsCount: newCount,
      averageWpm: newAvgWpm,
      lastSessionDate: DateTime.now(),
      dailyWords: newDaily,
    ));
  }

  Future<void> clear() async {
    await saveStats(ReadingStats.initial());
  }
}

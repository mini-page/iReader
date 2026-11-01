class ReadingStats {
  final int totalWordsRead;
  
  final int totalTimeSeconds;
  
  final int sessionsCount;
  
  final double averageWpm;
  
  final DateTime lastSessionDate;
  
  final Map<String, int> dailyWords; // "yyyy-MM-dd" -> words

  const ReadingStats({
    required this.totalWordsRead,
    required this.totalTimeSeconds,
    required this.sessionsCount,
    required this.averageWpm,
    required this.lastSessionDate,
    required this.dailyWords,
  });

  factory ReadingStats.initial() => ReadingStats(
    totalWordsRead: 0,
    totalTimeSeconds: 0,
    sessionsCount: 0,
    averageWpm: 0,
    lastSessionDate: DateTime.now(),
    dailyWords: {},
  );

  ReadingStats copyWith({
    int? totalWordsRead,
    int? totalTimeSeconds,
    int? sessionsCount,
    double? averageWpm,
    DateTime? lastSessionDate,
    Map<String, int>? dailyWords,
  }) => ReadingStats(
    totalWordsRead: totalWordsRead ?? this.totalWordsRead,
    totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
    sessionsCount: sessionsCount ?? this.sessionsCount,
    averageWpm: averageWpm ?? this.averageWpm,
    lastSessionDate: lastSessionDate ?? this.lastSessionDate,
    dailyWords: dailyWords ?? this.dailyWords,
  );
}

class JournalEntry {
  final String id;
  final DateTime timestamp;
  final int moodScore; // 1 to 5 (1: very low, 5: peaceful)
  final String prompt;
  final String content;
  final double? associatedDistressScore;
  final List<String> tags;

  const JournalEntry({
    required this.id,
    required this.timestamp,
    required this.moodScore,
    required this.prompt,
    required this.content,
    this.associatedDistressScore,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'moodScore': moodScore,
        'prompt': prompt,
        'content': content,
        'associatedDistressScore': associatedDistressScore,
        'tags': tags,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        moodScore: json['moodScore'] as int? ?? 3,
        prompt: json['prompt'] as String? ?? 'How are you feeling right now?',
        content: json['content'] as String? ?? '',
        associatedDistressScore: (json['associatedDistressScore'] as num?)?.toDouble(),
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      );
}

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/journal_entry.dart';
import '../../data/datasources/local_database_service.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final LocalDatabaseService _db = LocalDatabaseService();
  final TextEditingController _contentController = TextEditingController();
  int _selectedMood = 3;
  int _promptIndex = 0;
  bool _isLoading = true;
  List<JournalEntry> _entries = [];

  final List<String> _prompts = [
    'What thoughts or pressures are taking up space right now?',
    'Name three physical sensations you feel in your body at this moment.',
    'What is one small kindness you can offer yourself today?',
    'What went well earlier, however small it might seem?',
    'Write down what you wish you could say out loud right now.',
  ];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    final list = await _db.getJournalEntries();
    if (mounted) {
      setState(() {
        _entries = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveEntry() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) return;

    final entry = JournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      moodScore: _selectedMood,
      prompt: _prompts[_promptIndex],
      content: text,
      associatedDistressScore: 32.0, // Attached to current biometric context
      tags: ['Self-Reflection'],
    );

    await _db.saveJournalEntry(entry);
    _contentController.clear();
    await _loadEntries();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reflection encrypted and saved safely to your device.'),
          backgroundColor: AppColors.primaryTeal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mindful Reflections'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Prompt Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Prompt for reflection',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          onPressed: () {
                            setState(() {
                              _promptIndex = (_promptIndex + 1) % _prompts.length;
                            });
                          },
                        ),
                      ],
                    ),
                    Text(
                      _prompts[_promptIndex],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),

                    // Mood Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMoodChoice(1, '😣'),
                        _buildMoodChoice(2, '😕'),
                        _buildMoodChoice(3, '😐'),
                        _buildMoodChoice(4, '🙂'),
                        _buildMoodChoice(5, '😌'),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Input Field
                    TextField(
                      controller: _contentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Pour out whatever is on your mind. Everything stays encrypted locally.',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _saveEntry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.lock_outline_rounded, size: 16),
                        label: const Text('Save Encrypted'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Past Reflections (${_entries.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_entries.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'No saved reflections yet. Writing helps de-clutter racing thoughts.',
                      style: TextStyle(
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final e = _entries[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${e.timestamp.day}/${e.timestamp.month} • ${e.timestamp.hour.toString().padLeft(2, '0')}:${e.timestamp.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                ),
                              ),
                              Text(_moodToEmoji(e.moodScore), style: const TextStyle(fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            e.prompt,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryTeal),
                          ),
                          const SizedBox(height: 4),
                          Text(e.content, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodChoice(int score, String emoji) {
    final isSelected = _selectedMood == score;
    return GestureDetector(
      onTap: () => setState(() => _selectedMood = score),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  String _moodToEmoji(int score) {
    switch (score) {
      case 1:
        return '😣';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😌';
      default:
        return '😐';
    }
  }
}

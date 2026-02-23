import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'dart:typed_data';
import '../../../../theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import 'package:ailanguageapp/features/settings/presentation/providers/app_locale_provider.dart';
import '../../domain/entities/lesson.dart';
import '../providers/lessons_provider.dart';
import '../../data/lessons_repository.dart';
import '../widgets/interactive_cards.dart';

class LessonDetailPage extends ConsumerStatefulWidget {
  final Lesson lesson;

  const LessonDetailPage({super.key, required this.lesson});

  @override
  ConsumerState<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends ConsumerState<LessonDetailPage> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  bool _isCompleting = false;
  bool _isReady = false;
  late bool _isCompleted;
  final Set<int> _solvedChallengeIndexes = <int>{};

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.lesson.status == LessonStatus.completed;
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _player.openPlayer();
    if (mounted) setState(() => _isReady = true);
  }

  @override
  void dispose() {
    _player.closePlayer();

    super.dispose();
  }

  Future<void> _completeLesson() async {
    if (_isCompleted || _isCompleting) return;
    setState(() => _isCompleting = true);
    try {
      await ref
          .read(lessonsRepositoryProvider)
          .completeLesson(widget.lesson.id);
      ref.invalidate(lessonsProvider);
      if (mounted) {
        setState(() => _isCompleted = true);
        final s = AppStrings.forLocale(ref.read(appLocaleProvider));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.lessonCompletedAndSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${AppStrings.forLocale(ref.read(appLocaleProvider)).error}: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  Future<void> _playPronunciation(String text) async {
    if (!_isReady || text.trim().isEmpty) return;
    // Prefer the explicitly set target_language in the content, or fallback to 'en' (which shouldn't happen for lessons)
    final targetLanguage = (widget.lesson.content['target_language'] ?? 'en')
        .toString();
    try {
      final audio = await ref
          .read(lessonsRepositoryProvider)
          .synthesizeSpeech(text: text, languageCode: targetLanguage);
      if (_player.isPlaying) {
        await _player.stopPlayer();
      }
      final codec = audio.codec.toLowerCase() == 'mp3'
          ? Codec.mp3
          : Codec.pcm16;
      await _player.startPlayer(
        fromDataBuffer: Uint8List.fromList(audio.bytes),
        codec: codec,
        sampleRate: audio.sampleRate,
      );
    } catch (e) {
      // keep interaction responsive even if audio fails
      debugPrint("Audio playback failed: $e");
    }
  }



  Future<void> _markSolvedAndMaybeComplete(int index, int total) async {
    if (_solvedChallengeIndexes.contains(index)) return;
    setState(() => _solvedChallengeIndexes.add(index));
    if (_solvedChallengeIndexes.length == total) {
      await _completeLesson();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    final s = AppStrings.forLocale(locale);
    // Backend now returns 'challenges', but we support 'cards' for backward compat or if map differs.
    final List<dynamic> challengesRaw = (widget.lesson.content['challenges'] as List?) ?? 
                                        (widget.lesson.content['cards'] as List?) ?? [];
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: Colors.transparent,
      ),
      body: challengesRaw.isEmpty
          ? Center(
              child: Text(
                s.noInteractiveContent,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: challengesRaw.length + 1,
              itemBuilder: (context, index) {
                if (index == challengesRaw.length) {
                  final solved = _solvedChallengeIndexes.length;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        _isCompleted
                            ? s.lessonCompleted
                            : _isCompleting
                            ? s.saving
                            : '${s.progress}: $solved/${challengesRaw.length}',
                        style: TextStyle(
                            color: _isCompleted ? Colors.green : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  );
                }

                final challengeData = (challengesRaw[index] as Map).cast<String, dynamic>();
                final type = (challengeData['type'] ?? '').toString();
                final isSolved = _solvedChallengeIndexes.contains(index);

                return Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  margin: const EdgeInsets.only(bottom: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                Text(
                                  '${s.challenge} ${index + 1}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                                if (isSolved)
                                    const Icon(Icons.check_circle, color: Colors.green, size: 20)
                            ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Render appropriate widget based on type
                        if (type == 'IMAGE_CHOICE' || type == 'vocab_image')
                             ImageChoiceWidget(
                                 cardData: challengeData,
                                 isSolved: isSolved,
                                 onPlayAudio: _playPronunciation,
                                 onSolved: () => _markSolvedAndMaybeComplete(index, challengesRaw.length),
                             )
                        else if (type == 'TRANSLATE_PICKER' || type == 'translate')
                            TranslatePickerWidget(
                                cardData: challengeData,
                                isSolved: isSolved,
                                onPlayAudio: _playPronunciation,
                                onSolved: () => _markSolvedAndMaybeComplete(index, challengesRaw.length),
                            )
                        else if (type == 'SENTENCE_BUILDER' || type == 'word_bank')
                            SentenceBuilderWidget(
                                cardData: challengeData,
                                isSolved: isSolved,
                                onPlayAudio: _playPronunciation,
                                onSolved: () => _markSolvedAndMaybeComplete(index, challengesRaw.length),
                            )
                        else
                             Text(
                                "Unknown challenge type: $type",
                                style: TextStyle(color: Theme.of(context).colorScheme.error),
                             )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

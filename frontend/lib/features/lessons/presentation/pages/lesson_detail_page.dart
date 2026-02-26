import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isLoadingContent = false;
  Lesson? _lessonWithContent;
  final Set<int> _solvedChallengeIndexes = <int>{};

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.lesson.status == LessonStatus.completed;
    _lessonWithContent = widget.lesson;
    _bootstrapLessonContent();
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _player.openPlayer();
    if (mounted) setState(() => _isReady = true);
  }

  Future<void> _bootstrapLessonContent() async {
    // If the incoming lesson already has interactive content, we can render immediately.
    final hasCards = (widget.lesson.content['challenges'] as List?)?.isNotEmpty ??
        (widget.lesson.content['cards'] as List?)?.isNotEmpty ??
        false;
    if (hasCards) {
      return;
    }

    setState(() {
      _isLoadingContent = true;
    });

    try {
      final repo = ref.read(lessonsRepositoryProvider);
      final language = ref.read(appLocaleProvider); // app language (for detail we already know target inside content)
      // For details we prefer the target language, but backend also resolves it; we can omit language here.
      final fullLesson = await repo.getLessonDetails(lessonId: widget.lesson.id, languageCode: null);
      if (!mounted) return;
      setState(() {
        _lessonWithContent = fullLesson;
        _isLoadingContent = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingContent = false;
      });
    }
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
    final effectiveLesson = _lessonWithContent ?? widget.lesson;
    final locale = ref.watch(appLocaleProvider);
    final s = AppStrings.forLocale(locale);
    // Backend now returns 'challenges', but we support 'cards' for backward compat or if map differs.
    final List<dynamic> challengesRaw = (effectiveLesson.content['challenges'] as List?) ??
        (effectiveLesson.content['cards'] as List?) ??
        [];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final totalChallenges = challengesRaw.length;
    final solvedCount = _solvedChallengeIndexes.length;
    final progress =
        totalChallenges == 0 ? 0.0 : solvedCount / totalChallenges.toDouble();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: Colors.transparent,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: totalChallenges == 0 && !_isLoadingContent
              ? Center(
                  child: Text(
                    s.noInteractiveContent,
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top progress bar
                    Text(
                      '${s.progress}: $solvedCount/$totalChallenges',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          width:
                              (MediaQuery.of(context).size.width - 32) * progress,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.secondary,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _isLoadingContent && challengesRaw.isEmpty
                          ? ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: 3,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? Colors.black.withOpacity(0.35)
                                            : Colors.black.withOpacity(0.06),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          color: colorScheme.surfaceVariant
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        width: double.infinity,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          color: colorScheme.surfaceVariant
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          color: colorScheme.surfaceVariant
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: challengesRaw.length,
                              itemBuilder: (context, index) {
                                final challengeData =
                                    (challengesRaw[index] as Map)
                                        .cast<String, dynamic>();
                                final type =
                                    (challengeData['type'] ?? '').toString();
                                final isSolved =
                                    _solvedChallengeIndexes.contains(index);

                                return AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? Colors.black.withOpacity(0.35)
                                            : Colors.black.withOpacity(0.06),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: isSolved
                                          ? Colors.green.withOpacity(0.4)
                                          : colorScheme.outlineVariant
                                              .withOpacity(0.4),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${s.challenge} ${index + 1}',
                                              style: theme
                                                  .textTheme.labelSmall
                                                  ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                            if (isSolved)
                                              Icon(
                                                Icons.check_circle_rounded,
                                                color:
                                                    Colors.green.shade500,
                                                size: 20,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Render appropriate widget based on type
                                        if (type == 'IMAGE_CHOICE' ||
                                            type == 'vocab_image')
                                          ImageChoiceWidget(
                                            cardData: challengeData,
                                            isSolved: isSolved,
                                            onPlayAudio: _playPronunciation,
                                            onSolved: () =>
                                                _markSolvedAndMaybeComplete(
                                                    index,
                                                    challengesRaw.length),
                                          )
                                        else if (type ==
                                                'TRANSLATE_PICKER' ||
                                            type == 'translate')
                                          TranslatePickerWidget(
                                            cardData: challengeData,
                                            isSolved: isSolved,
                                            onPlayAudio: _playPronunciation,
                                            onSolved: () =>
                                                _markSolvedAndMaybeComplete(
                                                    index,
                                                    challengesRaw.length),
                                          )
                                        else if (type ==
                                                'SENTENCE_BUILDER' ||
                                            type == 'word_bank')
                                          SentenceBuilderWidget(
                                            cardData: challengeData,
                                            isSolved: isSolved,
                                            onPlayAudio: _playPronunciation,
                                            onSolved: () =>
                                                _markSolvedAndMaybeComplete(
                                                    index,
                                                    challengesRaw.length),
                                          )
                                        else
                                          Text(
                                            "Unknown challenge type: $type",
                                            style: TextStyle(
                                                color: colorScheme.error,
                                                fontWeight:
                                                    FontWeight.w600),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    // Bottom pinned button (UI only, no new logic)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isCompleted
                            ? () {
                                Navigator.of(context).maybePop();
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          _isCompleted ? s.lessonCompleted : s.continueButton,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

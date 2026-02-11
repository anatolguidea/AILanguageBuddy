import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_colors.dart';
import '../../data/lesson_content_mapper.dart';
import '../../data/lessons_repository.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_content.dart';
import '../providers/lessons_provider.dart';

class LessonDetailPage extends ConsumerStatefulWidget {
  final Lesson lesson;

  const LessonDetailPage({super.key, required this.lesson});

  @override
  ConsumerState<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends ConsumerState<LessonDetailPage> {
  bool _isLoading = false;
  int _exerciseIndex = 0;
  bool _isCurrentExerciseSolved = false;
  late final LessonContent _content;
  late List<_WordToken> _bank;
  late List<_WordToken?> _slots;

  @override
  void initState() {
    super.initState();
    _content = LessonContentMapper.fromMap(widget.lesson.content);
    _loadExercise();
  }

  ArrangeWordsExercise? get _currentExercise {
    if (_content.exercises.isEmpty) return null;
    if (_exerciseIndex < 0 || _exerciseIndex >= _content.exercises.length) {
      return null;
    }
    return _content.exercises[_exerciseIndex];
  }

  void _loadExercise() {
    final exercise = _currentExercise;
    if (exercise == null) {
      _bank = <_WordToken>[];
      _slots = <_WordToken?>[];
      return;
    }
    _bank = List<_WordToken>.generate(
      exercise.words.length,
      (index) =>
          _WordToken(id: '${exercise.id}-$index', text: exercise.words[index]),
      growable: true,
    );
    _slots = List<_WordToken?>.filled(
      exercise.solution.length,
      null,
      growable: false,
    );
    _isCurrentExerciseSolved = false;
  }

  bool get _canCompleteLesson {
    if (widget.lesson.status == LessonStatus.completed) return false;
    if (_content.exercises.isEmpty) return true;
    return _isCurrentExerciseSolved &&
        _exerciseIndex == _content.exercises.length - 1;
  }

  void _placeToken(_WordToken token, int slotIndex) {
    if (slotIndex < 0 || slotIndex >= _slots.length) return;
    setState(() {
      _removeTokenEverywhere(token);
      final replaced = _slots[slotIndex];
      if (replaced != null) _bank.add(replaced);
      _slots[slotIndex] = token;
    });
  }

  void _removeTokenEverywhere(_WordToken token) {
    _bank.removeWhere((candidate) => candidate.id == token.id);
    for (var i = 0; i < _slots.length; i++) {
      if (_slots[i]?.id == token.id) {
        _slots[i] = null;
      }
    }
  }

  void _removeFromSlot(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= _slots.length) return;
    final token = _slots[slotIndex];
    if (token == null) return;
    setState(() {
      _slots[slotIndex] = null;
      _bank.add(token);
    });
  }

  void _checkExercise() {
    final exercise = _currentExercise;
    if (exercise == null) return;
    if (_slots.any((slot) => slot == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Place all words before checking.')),
      );
      return;
    }
    final answer = _slots.map((token) => token!.text).toList(growable: false);
    final isCorrect = _matches(answer, exercise.solution);
    if (!isCorrect) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not correct yet. Rearrange and try again.'),
        ),
      );
      return;
    }

    final isLast = _exerciseIndex == _content.exercises.length - 1;
    if (isLast) {
      setState(() => _isCurrentExerciseSolved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfect. You solved all exercises.')),
      );
      return;
    }

    setState(() {
      _exerciseIndex += 1;
      _loadExercise();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Great. Next exercise unlocked.')),
    );
  }

  bool _matches(List<String> answer, List<String> expected) {
    if (answer.length != expected.length) return false;
    for (var i = 0; i < answer.length; i++) {
      if (answer[i] != expected[i]) return false;
    }
    return true;
  }

  Future<void> _completeLesson() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(lessonsRepositoryProvider)
          .completeLesson(
            lessonId: widget.lesson.id,
            languageCode: widget.lesson.languageCode,
            orderIndex: widget.lesson.orderIndex,
          );
      ref.invalidate(lessonsProvider);
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lesson completed!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _currentExercise;
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.lesson.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                if (_content.sections.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ..._content.sections.map(
                    (text) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
                if (exercise != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceElevated),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exercise ${_exerciseIndex + 1}/${_content.exercises.length}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          exercise.prompt,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hint: ${exercise.hint}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List<Widget>.generate(_slots.length, (
                            index,
                          ) {
                            final token = _slots[index];
                            return DragTarget<_WordToken>(
                              onWillAcceptWithDetails: (details) => true,
                              onAcceptWithDetails: (details) =>
                                  _placeToken(details.data, index),
                              builder: (context, candidateData, rejectedData) {
                                final isHovering = candidateData.isNotEmpty;
                                return GestureDetector(
                                  onTap: () => _removeFromSlot(index),
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 64,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: token == null
                                          ? AppColors.surfaceElevated
                                          : AppColors.primary,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isHovering
                                            ? Colors.white
                                            : AppColors.surfaceElevated,
                                      ),
                                    ),
                                    child: Text(
                                      token?.text ?? 'Drop',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Word bank',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.9,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _bank
                              .map(
                                (token) => LongPressDraggable<_WordToken>(
                                  data: token,
                                  feedback: Material(
                                    color: Colors.transparent,
                                    child: _WordChip(
                                      text: token.text,
                                      active: true,
                                    ),
                                  ),
                                  childWhenDragging: _WordChip(
                                    text: token.text,
                                    active: false,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      final firstEmpty = _slots.indexWhere(
                                        (slot) => slot == null,
                                      );
                                      if (firstEmpty != -1) {
                                        _placeToken(token, firstEmpty);
                                      }
                                    },
                                    child: _WordChip(
                                      text: token.text,
                                      active: true,
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isCurrentExerciseSolved
                                ? null
                                : _checkExercise,
                            child: const Text('Check answer'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || !_canCompleteLesson
                    ? null
                    : _completeLesson,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.lesson.status == LessonStatus.completed
                            ? 'Completed'
                            : (_canCompleteLesson
                                  ? 'Complete Lesson'
                                  : 'Solve exercise to continue'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordToken {
  final String id;
  final String text;

  const _WordToken({required this.id, required this.text});
}

class _WordChip extends StatelessWidget {
  final String text;
  final bool active;

  const _WordChip({required this.text, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1 : 0.35,
      duration: const Duration(milliseconds: 140),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

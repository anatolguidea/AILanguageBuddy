import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// Table for storing lesson completion status
class LessonProgressTable extends Table {
  TextColumn get id => text()(); // "lesson_id"
  TextColumn get languageCode => text()();
  IntColumn get stars => integer().withDefault(const Constant(0))();
  DateTimeColumn get completionDate => dateTime().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id, languageCode};
}

// Table for Spaced Repetition System (SRS)
class WordStrengthTable extends Table {
  TextColumn get word => text()();
  TextColumn get languageCode => text()();
  RealColumn get strength => real().withDefault(const Constant(0.0))(); // 0.0 to 1.0
  DateTimeColumn get lastReviewDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {word, languageCode};
}

@DriftDatabase(tables: [LessonProgressTable, WordStrengthTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

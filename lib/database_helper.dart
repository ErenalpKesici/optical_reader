import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "MyDatabase.db";
  static const _databaseVersion = 1;

  static const table = 'my_table';

  static const columnId = 'id';
  static const columnName = 'name';
  static const columnAge = 'age';

  late Database _db;

  // this opens the database (and creates it if it doesn't exist)
  Future<void> init() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    _db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE tests (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            correct_answers TEXT NOT NULL,
            question_count INTEGER NOT NULL
          )
          ''');

    await db.execute('''
            CREATE TABLE student_answers (
              id INTEGER PRIMARY KEY,
              student_id INTEGER,
              test_id INTEGER,
              question_id INTEGER,
              results TEXT NOT NULL,
              FOREIGN KEY(student_id) REFERENCES students(id),
              FOREIGN KEY(test_id) REFERENCES tests(id)
            )
          ''');

    await db.execute('''
          CREATE TABLE students (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL
          )
          ''');
  }

  // Helper methods

  Future<int> insert(String table, Map<String, dynamic> row) async {
    String columns = row.keys.join(", ");
    String values = row.values.map((value) => "'$value'").join(", ");
    String query = 'CREATE TABLE IF NOT EXISTS $table ($columns)';
    await _db.execute(query);

    query = 'INSERT INTO $table ($columns) VALUES ($values)';
    return await _db.rawInsert(query);
  }

  // All of the rows are returned as a list of maps, where each map is
  // a key-value list of columns.
  Future<List<Map<String, dynamic>>> getRows(
      {required String table, String where = '1'}) async {
    return await _db.query(table, where: where);
  }

  // All of the methods (insert, query, update, delete) can also be done using
  // raw SQL commands. This method uses a raw query to give the row count.
  Future<int> queryRowCount() async {
    final results = await _db.rawQuery('SELECT COUNT(*) FROM $table');
    return Sqflite.firstIntValue(results) ?? 0;
  }

  // We are assuming here that the id column in the map is set. The other
  // column values will be used to update the row.
  Future<int> update(String table, Map<String, dynamic> row) async {
    int id = row[columnId];
    return await _db.update(
      table,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Deletes the row specified by the id. The number of affected rows is
  // returned. This should be 1 as long as the row exists.
  Future<int> delete(String table, String where, List args) async {
    return await _db.delete(table, where: where, whereArgs: args);
  }
}

import 'package:sqflite/sqflite.dart';
import 'create_sqlite.dart';

class DataInserter {
  final DBHelper _dbHelper = DBHelper();

  /// Inserts the fetched data into the 'itemnames' table.
  /// 
  /// The input [rows] is expected to be a List of Lists structured as:
  /// - rows[0]: ['ctr', 1, 2, 3, ...] (indexes)
  /// - rows[1]: ['itemname', 'Okra', 'Sitaw', ...]
  /// - rows[2]: ['sold_count', 866, 835, ...]
  /// - rows[3]: ['image_path', 'sample', 'sample', ...]
  Future<void> insertFetchedData(List<List<dynamic>> rows) async {
    final db = await _dbHelper.database;

    // Start a batch for better performance
    Batch batch = db.batch();

    // Insert each item starting from index 1 (skip header)
    for (int i = 1; i < rows[0].length; i++) {
      final Map<String, dynamic> item = {
        'itemname': rows[1][i],
        'sold_count': rows[2][i],
        'image_path': rows[3][i],
      };

      batch.insert(
        'itemnames',
        item,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Commit the batch insert
    await batch.commit(noResult: true);
  }
}

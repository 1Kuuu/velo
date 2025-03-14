import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Example method to write data
  Future<void> writeData(String path, Map<String, dynamic> data) async {
    try {
      await _database.child(path).set(data);
    } catch (e) {
      print('Error writing to database: $e');
      rethrow;
    }
  }

  // Example method to read data once
  Future<dynamic> readData(String path) async {
    try {
      final snapshot = await _database.child(path).get();
      return snapshot.value;
    } catch (e) {
      print('Error reading from database: $e');
      rethrow;
    }
  }

  // Example method to listen to real-time updates
  Stream<DatabaseEvent> streamData(String path) {
    return _database.child(path).onValue;
  }

  // Example method to update specific fields
  Future<void> updateData(String path, Map<String, dynamic> data) async {
    try {
      await _database.child(path).update(data);
    } catch (e) {
      print('Error updating database: $e');
      rethrow;
    }
  }

  // Example method to remove data
  Future<void> removeData(String path) async {
    try {
      await _database.child(path).remove();
    } catch (e) {
      print('Error removing data: $e');
      rethrow;
    }
  }
}

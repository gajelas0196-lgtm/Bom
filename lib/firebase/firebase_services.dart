import 'package:firebase_database/firebase_database.dart';

class FirebaseService {

  final DatabaseReference _db = FirebaseDatabase.instance.ref();


  Future<void> writeData(
    String path,
    Map<String, dynamic> data,
  ) async {
    await _db.child(path).set(data);
  }


  Future<DataSnapshot> readData(
    String path,
  ) async {
    return await _db.child(path).get();
  }


  Stream<DatabaseEvent> listenData(
    String path,
  ) {
    return _db.child(path).onValue;
  }


  Future<void> updateData(
    String path,
    Map<String, dynamic> data,
  ) async {
    await _db.child(path).update(data);
  }


  Future<void> deleteData(
    String path,
  ) async {
    await _db.child(path).remove();
  }
}


final firebaseService = FirebaseService();
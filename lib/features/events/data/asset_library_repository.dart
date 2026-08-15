import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/asset_library_entry.dart';

class AssetLibraryRepository {
  AssetLibraryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _assets => _firestore.collection('assetLibrary');

  Stream<List<AssetLibraryEntry>> watchAll() {
    return _assets.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs.map(AssetLibraryEntry.fromDoc).toList(),
        );
  }

  Future<void> addEntry({required String name, required String url, required AssetType type}) {
    return _assets.add({'name': name, 'url': url, 'type': type.name});
  }

  Future<void> deleteEntry(String id) {
    return _assets.doc(id).delete();
  }
}

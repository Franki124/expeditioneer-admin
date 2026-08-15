import 'package:cloud_firestore/cloud_firestore.dart';

enum AssetType { image, model3d }

class AssetLibraryEntry {
  const AssetLibraryEntry({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
  });

  final String id;
  final String name;
  final String url;
  final AssetType type;

  factory AssetLibraryEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AssetLibraryEntry(
      id: doc.id,
      name: data['name'] as String? ?? '',
      url: data['url'] as String? ?? '',
      type: data['type'] == 'model3d' ? AssetType.model3d : AssetType.image,
    );
  }
}

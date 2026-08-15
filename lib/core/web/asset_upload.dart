import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../features/events/domain/asset_library_entry.dart';
import 'cloudinary_config.dart';
import 'file_picker.dart';

const _maxUploadBytes = 10 * 1024 * 1024;
const _uploadTimeout = Duration(seconds: 30);

class AssetTooLargeException implements Exception {}

class AssetUploadTimeoutException implements Exception {}

class CloudinaryNotConfiguredException implements Exception {}

/// Opens the browser's file picker and uploads the chosen file to
/// Cloudinary via its unsigned-upload API, returning the resulting
/// `secure_url` (same shape as a pasted URL, so nothing downstream needs to
/// know the difference) plus the original filename, for callers that want
/// to use it as a default asset-library name. Returns null if the user
/// cancels the picker.
Future<({String url, String filename})?> pickAndUploadAsset(AssetType type) async {
  if (!isCloudinaryConfigured) throw CloudinaryNotConfiguredException();

  final accept = type == AssetType.model3d ? '.glb,.gltf,.obj,model/*' : 'image/*';
  final picked = await pickFile(accept: accept);
  if (picked == null) return null;
  if (picked.bytes.lengthInBytes > _maxUploadBytes) throw AssetTooLargeException();

  // Cloudinary's 'image' resource type applies image processing/validation;
  // anything else (3D models) goes through 'raw' — stored and served as-is.
  final resourceType = type == AssetType.model3d ? 'raw' : 'image';
  final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudinaryCloudName/$resourceType/upload');
  final folder = type == AssetType.model3d ? 'assets/models' : 'assets/images';

  try {
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = cloudinaryUploadPreset
      ..fields['folder'] = folder
      ..files.add(http.MultipartFile.fromBytes('file', picked.bytes, filename: picked.name));
    final streamedResponse = await request.send().timeout(_uploadTimeout);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200) {
      throw Exception('Cloudinary upload failed (${response.statusCode}): ${response.body}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (url: body['secure_url'] as String, filename: picked.name);
  } on TimeoutException {
    throw AssetUploadTimeoutException();
  }
}

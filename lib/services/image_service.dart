import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (kIsWeb) {
          // On web, return a data URI (base64) so UI can display without filesystem
          final bytes = await image.readAsBytes();
          final base64Str = base64Encode(bytes);
          final ext = image.name.contains('.')
              ? image.name.split('.').last
              : 'jpg';
          return 'data:image/$ext;base64,$base64Str';
        }

        return await _saveImageToLocalDirectory(image);
      }
    } catch (e) {
      // print('Erreur lors de la suppression de l\'image: $e');
    }
    return null;
  }

  Future<String?> takePhotoWithCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          final base64Str = base64Encode(bytes);
          final ext = image.name.contains('.')
              ? image.name.split('.').last
              : 'jpg';
          return 'data:image/$ext;base64,$base64Str';
        }

        return await _saveImageToLocalDirectory(image);
      }
    } catch (e) {
      // print('Erreur lors de la prise de photo: $e');
    }
    return null;
  }

  Future<String?> _saveImageToLocalDirectory(XFile image) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDirPath = path.join(appDir.path, 'profile_images');

      // Créer le dossier s'il n'existe pas
      final Directory imagesDir = Directory(imagesDirPath);
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Générer un nom de fichier unique
      final String fileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(imagesDirPath, fileName);

      // Copier l'image vers le répertoire local
      await File(image.path).copy(filePath);

      return filePath;
    } catch (e) {
      // print('Erreur lors de la sauvegarde de l\'image: $e');
      return null;
    }
  }

  Future<bool> deleteImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
        return true;
      }
    } catch (e) {
      // print('Erreur lors de la sauvegarde de l\'image: $e');
    }
    return false;
  }
}

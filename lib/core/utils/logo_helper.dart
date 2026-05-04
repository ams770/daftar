import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class LogoHelper {
  static const String _logoFileName = 'brand_logo';

  /// Picks an image from gallery and saves it to the documents directory.
  /// Returns the filename with extension if successful, null otherwise.
  static Future<String?> pickAndSaveLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return null;

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String extension = p.extension(image.path);
    final String fileName = '$_logoFileName$extension';
    final String targetPath = p.join(appDir.path, fileName);

    // Delete existing logo files with different extensions if any
    final List<String> commonExtensions = ['.jpg', '.jpeg', '.png'];
    for (final ext in commonExtensions) {
      final oldFile = File(p.join(appDir.path, '$_logoFileName$ext'));
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    }

    final File savedImage = await File(image.path).copy(targetPath);
    return p.basename(savedImage.path);
  }

  /// Resolves the full absolute path for a given logo filename.
  static Future<String> getFullPath(String fileName) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, fileName);
  }

  /// Checks if a logo file exists.
  static Future<bool> logoExists(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return false;
    final String fullPath = await getFullPath(fileName);
    return File(fullPath).exists();
  }
}

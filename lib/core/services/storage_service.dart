import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:elimupepe/models/ebook.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:elimupepe/core/services/database_service.dart';

class StorageService {
  StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  static final StorageService _instance = StorageService._internal();
  static StorageService get instance => _instance;

  // Assign category based on filename
  String _assignCategory(String fileName) {
    final fileNameLower = fileName.toLowerCase();

    if (fileNameLower.contains('revision') ||
        fileNameLower.contains('revise')) {
      return 'Revision Books';
    } else if (fileNameLower.contains('reader') ||
        fileNameLower.contains('story')) {
      return 'Readers';
    } else if (fileNameLower.contains('reference') ||
        fileNameLower.contains('dict')) {
      return 'Reference Books';
    } else {
      // Default to Textbooks for LB, worksheet, activities, etc.
      return 'Textbooks';
    }
  }

  // Get application documents directory for storing ebooks
  Future<Directory> getEbooksDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final ebooksDir = Directory('${appDocDir.path}/ebooks');

    // Create directory if it doesn't exist
    if (!await ebooksDir.exists()) {
      await ebooksDir.create(recursive: true);
    }

    return ebooksDir;
  }

  // Get total storage used by ebooks
  Future<int> getUsedStorage() async {
    final ebooksDir = await getEbooksDirectory();
    int totalSize = 0;

    if (await ebooksDir.exists()) {
      final files = ebooksDir.listSync(recursive: true);
      for (var file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
    }

    return totalSize;
  }

  // Save file to secure storage
  Future<String> saveEbookFile(List<int> fileBytes, String fileName) async {
    try {
      final ebooksDir = await getEbooksDirectory();
      final file = File('${ebooksDir.path}/$fileName');
      await file.writeAsBytes(fileBytes);
      return file.path;
    } catch (e) {
      throw Exception('Failed to save ebook: $e');
    }
  }

  // Delete ebook file
  Future<void> deleteEbookFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete ebook file: $e');
    }
  }

  // Check if file exists
  Future<bool> ebookFileExists(String filePath) async {
    final file = File(filePath);
    return file.exists();
  }

  // Get file size
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Clear all ebook storage
  Future<void> clearAllEbooks() async {
    try {
      final ebooksDir = await getEbooksDirectory();
      if (await ebooksDir.exists()) {
        await ebooksDir.delete(recursive: true);
        // Recreate empty directory
        await ebooksDir.create(recursive: true);
      }
    } catch (e) {
      throw Exception('Failed to clear ebooks: $e');
    }
  }

  // Copy bundled ebooks from grade folders to app storage
  Future<void> copyBundledEbooksToStorage(
    DatabaseService databaseService, {
    String? targetGrade,
  }) async {
    try {
      final ebooksDir = await getEbooksDirectory();
      final existingBooks = {
        for (final ebook in await databaseService.getAllEbooks()) ebook.id,
      };

      // Define all known PDFs by grade
      final Map<int, List<String>> gradeBooks = {
        1: [
          'CRE Grade 1 -cropped.pdf',
          'English LB Grade 1.pdf',
          'Environmental Activities Grade 1 -cropped.pdf',
          'Kiswahili GRADE 1 -cropped.pdf',
          'Maths Grade 1.pdf',
        ],
        2: [
          'CRE G2 LB - cropped.pdf',
          'English LB 2 - cropped.pdf',
          'Environmental Activities Grade 2 - cropped.pdf',
          'Grade 2 Kisw - Feb 2025.pdf',
          'Maths Grade 2.pdf',
        ],
        3: [
          'CRE G3 main.pdf',
          'English LB Grade 3.pdf',
          'Environmental Activities Grade 3 LB - cropped.pdf',
          'Kiswahili G3 cropped.pdf',
          'Mathematics Activities Grade 3.pdf',
        ],
      };

      // Process each grade
      for (var entry in gradeBooks.entries) {
        final gradeNum = entry.key;

        // Filter by targeted grade if provided
        if (targetGrade != null) {
          final normalizedTarget = targetGrade.toLowerCase().trim();
          final expectedGrade = 'grade $gradeNum';
          if (normalizedTarget != expectedGrade &&
              normalizedTarget != gradeNum.toString()) {
            continue; // Skip books that don't match the learner's grade
          }
        }

        final pdfFiles = entry.value;

        for (final fileName in pdfFiles) {
          final assetPath = 'assets/ebooks/grade$gradeNum/$fileName';
          final destination = File(p.join(ebooksDir.path, fileName));

          // Skip work that already exists. The database check avoids reloading
          // the asset on every launch, while the file check lets us restore a
          // missing file if the database entry survived but storage did not.
          if (existingBooks.contains(fileName) && await destination.exists()) {
            continue;
          }

          // Copy asset to app storage
          try {
            final data = await rootBundle.load(assetPath);
            await destination.writeAsBytes(data.buffer.asUint8List());

            final fileSize = await destination.length();

            // Try to copy matching thumbnail image if it exists
            final baseName = p.basenameWithoutExtension(fileName);
            String? coverImagePath;
            for (final ext in ['.jpg', '.jpeg', '.png']) {
              try {
                final imageAssetPath =
                    'assets/ebooks/grade$gradeNum/$baseName$ext';
                final imageData = await rootBundle.load(imageAssetPath);
                final imageDest = File(p.join(ebooksDir.path, '$baseName$ext'));
                await imageDest.writeAsBytes(imageData.buffer.asUint8List());
                coverImagePath = imageDest.path;
                break; // Found a matching image, stop searching
              } catch (e) {
                // Image doesn't exist, continue to next extension
                continue;
              }
            }

            // Register in database with grade and category
            final ebook = Ebook(
              id: fileName,
              title: p
                  .basenameWithoutExtension(fileName)
                  .replaceAll('_', ' ')
                  .replaceAll('-', ' ')
                  .trim(),
              author: 'Bundled Ebook',
              description: 'Grade $gradeNum ebook',
              coverUrl: null,
              localPath: destination.path,
              totalPages: 0,
              downloadedDate: DateTime.now(),
              isDownloaded: true,
              fileSize: fileSize,
              serverUrl: null,
              grade: 'Grade $gradeNum',
              category: _assignCategory(fileName),
              coverImagePath: coverImagePath,
            );

            await databaseService.addBundledEbook(ebook);
          } catch (e) {
            // Skip if asset loading fails
            continue;
          }
        }
      }
    } catch (e) {
      // Continue silently
    }
  }
}

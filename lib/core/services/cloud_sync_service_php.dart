import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:elimupepe/models/ebook.dart';
import 'package:elimupepe/core/services/database_service.dart';
import 'package:elimupepe/core/services/php_api_service.dart';

/// Service to sync cloud books from PHP backend and download them locally
class CloudSyncServicePhp {
  static final CloudSyncServicePhp instance = CloudSyncServicePhp._internal();
  factory CloudSyncServicePhp() => instance;
  CloudSyncServicePhp._internal();

  final PhpApiService _phpApiService = PhpApiService.instance;
  final DatabaseService _databaseService = DatabaseService.instance;
  final Dio _dio = Dio();

  /// Check if a book is already downloaded locally
  Future<bool> isBookDownloaded(String bookId) async {
    final localBooks = await _databaseService.getAllEbooks();
    return localBooks.any((book) => book.id == bookId);
  }

  /// Sync categories and grades from PHP API for downloaded books
  Future<void> syncDownloadedBookMetadata() async {
    try {
      final cloudBooks = await _phpApiService.getCloudBooks();
      final localBooks = await _databaseService.getAllEbooks();

      // Create a map of cloud books by ID for quick lookup
      final cloudBooksMap = {for (var book in cloudBooks) book.id: book};

      // Update local books with latest cloud metadata
      for (final localBook in localBooks) {
        final cloudBook = cloudBooksMap[localBook.id];
        if (cloudBook != null) {
          // Check if category or grade changed
          if (localBook.category != cloudBook.category ||
              localBook.grade != cloudBook.grade) {
            // Update local book with cloud metadata
            final updatedBook = localBook.copyWith(
              category: cloudBook.category,
              grade: cloudBook.grade,
            );
            await _databaseService.updateEbook(updatedBook);
            print('Synced metadata for: ${localBook.title}');
          }
        }
      }
    } catch (e) {
      print('Error syncing downloaded book metadata: $e');
    }
  }

  /// Remove bundled books from local storage (offline-safe)
  Future<void> removeBundledBooks() async {
    try {
      final localBooks = await _databaseService.getAllEbooks();
      for (final localBook in localBooks) {
        final isBundledBook = localBook.id.toLowerCase().endsWith('.pdf');
        if (isBundledBook) {
          await deleteDownloadedBook(localBook.id);
        }
      }
    } catch (e) {
      print('Error removing bundled books: $e');
    }
  }

  /// Get all cloud books that are not yet downloaded
  Future<List<Ebook>> getAvailableCloudBooks() async {
    try {
      final cloudBooks = await _phpApiService.getCloudBooks();
      final localBooks = await _databaseService.getAllEbooks();
      final localBookIds = localBooks.map((book) => book.id).toSet();

      // Return only books not yet downloaded
      return cloudBooks
          .where((book) => !localBookIds.contains(book.id))
          .toList();
    } catch (e) {
      print('Error getting available cloud books (offline?): $e');
      // Return empty list if offline - don't break the app
      return [];
    }
  }

  /// Download a book from PHP backend
  Future<bool> downloadBook(
    Ebook cloudBook, {
    Function(double)? onProgress,
  }) async {
    try {
      print('Starting download for: ${cloudBook.title}');

      // Get app's private storage directory
      final directory = await getApplicationDocumentsDirectory();
      final ebooksDir = Directory('${directory.path}/ebooks');
      if (!ebooksDir.existsSync()) {
        ebooksDir.createSync(recursive: true);
      }

      // The serverUrl is already the direct download URL from PHP API
      final downloadUrl = cloudBook.serverUrl ?? '';
      print('Download URL: $downloadUrl');

      // Sanitize filename
      final safeFileName = cloudBook.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim();
      final pdfPath = '${ebooksDir.path}/$safeFileName.pdf';
      String? thumbnailPath;

      print('Saving to: $pdfPath');

      // Download PDF with progress tracking
      await _dio
          .download(
            downloadUrl,
            pdfPath,
            onReceiveProgress: (received, total) {
              print('Progress: $received / $total bytes');
              if (total != -1 && onProgress != null) {
                final progress = received / total;
                onProgress(progress);
              }
            },
            options: Options(
              receiveTimeout: const Duration(seconds: 120),
              sendTimeout: const Duration(seconds: 60),
            ),
          )
          .timeout(
            const Duration(minutes: 5),
            onTimeout: () {
              throw Exception('Download took too long');
            },
          );

      print('PDF downloaded successfully');

      // Download thumbnail if available
      if (cloudBook.coverImagePath != null &&
          cloudBook.coverImagePath!.isNotEmpty) {
        try {
          print('Downloading thumbnail: ${cloudBook.coverImagePath}');
          thumbnailPath = '${ebooksDir.path}/$safeFileName.jpg';
          await _dio
              .download(
                cloudBook.coverImagePath!,
                thumbnailPath,
                options: Options(receiveTimeout: const Duration(seconds: 60)),
              )
              .timeout(const Duration(minutes: 2));
          print('Thumbnail downloaded successfully');
        } catch (e) {
          print('Error downloading thumbnail: $e');
          thumbnailPath = null;
        }
      }

      // Get file size
      final file = File(pdfPath);
      final fileSize = await file.length();
      print('File size: ${fileSize ~/ (1024 * 1024)} MB');

      // Save to local database
      final localBook = Ebook(
        id: cloudBook.id,
        title: cloudBook.title,
        author: cloudBook.author,
        localPath: pdfPath,
        fileSize: fileSize,
        downloadedDate: DateTime.now(),
        grade: cloudBook.grade,
        category: cloudBook.category,
        coverImagePath: thumbnailPath,
        totalPages: 0,
        isDownloaded: true,
        serverUrl: cloudBook.serverUrl,
      );

      await _databaseService.insertEbook(localBook);
      print('Book saved to database');
      print('Download complete for: ${cloudBook.title}');
      return true;
    } catch (e) {
      print('Error downloading book: $e');
      return false;
    }
  }

  /// Delete a downloaded book
  Future<bool> deleteDownloadedBook(String bookId) async {
    try {
      final localBooks = await _databaseService.getAllEbooks();
      final bookIndex = localBooks.indexWhere((b) => b.id == bookId);

      if (bookIndex == -1) {
        print('Book not found in database: $bookId');
        return false;
      }

      final book = localBooks[bookIndex];

      // Delete PDF file if exists
      if (book.localPath != null && book.localPath!.isNotEmpty) {
        try {
          final pdfFile = File(book.localPath!);
          if (await pdfFile.exists()) {
            await pdfFile.delete();
            print('Deleted PDF: ${book.localPath}');
          }
        } catch (e) {
          print('Error deleting PDF file: $e');
        }
      }

      // Delete thumbnail if exists
      if (book.coverImagePath != null && book.coverImagePath!.isNotEmpty) {
        try {
          final thumbnailFile = File(book.coverImagePath!);
          if (await thumbnailFile.exists()) {
            await thumbnailFile.delete();
            print('Deleted thumbnail: ${book.coverImagePath}');
          }
        } catch (e) {
          print('Error deleting thumbnail: $e');
        }
      }

      // Remove from database (always do this even if file deletion fails)
      await _databaseService.deleteEbook(bookId);
      print('Removed from database: $bookId');
      return true;
    } catch (e) {
      print('Error deleting book: $e');
      return false;
    }
  }
}

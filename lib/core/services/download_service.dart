import 'dart:async';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:elimupepe/models/ebook.dart';
import 'package:elimupepe/core/services/database_service.dart';
import 'package:elimupepe/core/services/storage_service.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();

  factory DownloadService() {
    return _instance;
  }

  DownloadService._internal();

  static DownloadService get instance => _instance;

  final Dio _dio = Dio();
  final Map<String, StreamController<DownloadProgress>> _progressControllers =
      {};

  /// Download an ebook from server and save locally
  /// Returns true on success, false on failure
  Future<bool> downloadEbook({
    required Ebook ebook,
    required String serverUrl,
    required Function(double) onProgress,
  }) async {
    try {
      // Check if already downloaded
      if (ebook.isDownloaded) {
        throw Exception('Ebook already downloaded');
      }

      final storageDir = await StorageService.instance.getEbooksDirectory();
      final fileName = '${ebook.id}_${ebook.title.replaceAll(' ', '_')}.pdf';
      final filePath = path.join(storageDir.path, fileName);

      // Start download with progress tracking
      final response = await _dio.download(
        serverUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress);
          }
        },
      );

      if (response.statusCode == 200) {
        // Update ebook metadata in database
        final updatedEbook = ebook.copyWith(
          isDownloaded: true,
          localPath: fileName,
          downloadedDate: DateTime.now(),
        );

        await DatabaseService.instance.updateEbook(updatedEbook);

        return true;
      } else {
        throw Exception(
          'Download failed with status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Download error: ${e.toString()}');
    }
  }

  /// Cancel an ongoing download
  Future<void> cancelDownload(String ebookId) async {
    try {
      // Close the progress controller for this ebook
      if (_progressControllers.containsKey(ebookId)) {
        _progressControllers[ebookId]?.close();
        _progressControllers.remove(ebookId);
      }
    } catch (e) {
      throw Exception('Failed to cancel download: ${e.toString()}');
    }
  }

  /// Delete a downloaded ebook
  Future<bool> deleteDownloadedEbook(Ebook ebook) async {
    try {
      if (!ebook.isDownloaded ||
          ebook.localPath == null ||
          ebook.localPath!.isEmpty) {
        throw Exception('Ebook not downloaded or path not available');
      }

      // Delete from local storage
      await StorageService.instance.deleteEbookFile(ebook.localPath!);

      // Update database
      final updatedEbook = ebook.copyWith(
        isDownloaded: false,
        localPath: '',
        downloadedDate: null,
      );

      await DatabaseService.instance.updateEbook(updatedEbook);

      return true;
    } catch (e) {
      throw Exception('Failed to delete ebook: ${e.toString()}');
    }
  }

  /// Get download stream for an ebook
  Stream<DownloadProgress> getDownloadProgress(String ebookId) {
    if (!_progressControllers.containsKey(ebookId)) {
      _progressControllers[ebookId] =
          StreamController<DownloadProgress>.broadcast();
    }
    return _progressControllers[ebookId]!.stream;
  }

  /// Check if file exists locally
  Future<bool> isEbookAvailableLocally(Ebook ebook) async {
    if (ebook.localPath == null || ebook.localPath!.isEmpty) {
      return false;
    }
    return await StorageService.instance.ebookFileExists(ebook.localPath!);
  }

  /// Get list of downloaded ebooks
  Future<List<Ebook>> getDownloadedEbooks() async {
    try {
      return await DatabaseService.instance.getDownloadedEbooks();
    } catch (e) {
      throw Exception('Failed to fetch downloaded ebooks: ${e.toString()}');
    }
  }

  /// Get storage stats
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final usedStorage = await StorageService.instance.getUsedStorage();
      final downloadedEbooks = await getDownloadedEbooks();

      return {
        'totalSize': usedStorage,
        'totalEbooks': downloadedEbooks.length,
        'sizeInMB': (usedStorage / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      throw Exception('Failed to fetch storage stats: ${e.toString()}');
    }
  }
}

class DownloadProgress {
  final int received;
  final int total;
  final double percentage;

  DownloadProgress({
    required this.received,
    required this.total,
    required this.percentage,
  });
}

import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class AppPdfCacheManager {
  AppPdfCacheManager._();

  static final AppPdfCacheManager instance = AppPdfCacheManager._();

  static const String _cacheKey = 'appser_pdf_cache';
  static const Duration _stalePeriod = Duration(days: 30);

  final CacheManager _cacheManager = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: _stalePeriod,
      maxNrOfCacheObjects: 120,
    ),
  );

  final Map<String, Future<File>> _inFlightDownloads = <String, Future<File>>{};

  Future<File> getPdfFile({
    required String pdfUrl,
    required String pdfPath,
  }) async {
    final key = _entryKey(pdfPath);
    final cached = await getCachedPdfFile(pdfPath: pdfPath);
    if (cached != null) {
      return cached;
    }

    return _downloadAndCache(pdfUrl: pdfUrl, key: key);
  }

  Future<File?> getCachedPdfFile({required String pdfPath}) async {
    final key = _entryKey(pdfPath);
    final cached = await _cacheManager.getFileFromCache(key);

    if (cached != null && await cached.file.exists()) {
      return cached.file;
    }

    return null;
  }

  Future<void> prefetchPdf({
    required String pdfUrl,
    required String pdfPath,
  }) async {
    final key = _entryKey(pdfPath);
    final cached = await _cacheManager.getFileFromCache(key);
    if (cached != null && await cached.file.exists()) {
      return;
    }

    if (_inFlightDownloads.containsKey(key)) {
      return;
    }

    unawaited(_downloadAndCache(pdfUrl: pdfUrl, key: key));
  }

  Future<File> _downloadAndCache({
    required String pdfUrl,
    required String key,
  }) {
    final existing = _inFlightDownloads[key];
    if (existing != null) {
      return existing;
    }

    final downloadFuture = _cacheManager.downloadFile(pdfUrl, key: key).then(
      (downloaded) => downloaded.file,
    ).whenComplete(() {
      _inFlightDownloads.remove(key);
    });

    _inFlightDownloads[key] = downloadFuture;
    return downloadFuture;
  }

  String _entryKey(String pdfPath) {
    return pdfPath.trim().replaceAll('\\', '/');
  }
}
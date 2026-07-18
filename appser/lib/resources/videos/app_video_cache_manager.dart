import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

class AppVideoCacheManager {
  AppVideoCacheManager._();

  static final AppVideoCacheManager instance = AppVideoCacheManager._();

  static const String _cacheKey = 'appser_video_cache';
  static const Duration _stalePeriod = Duration(days: 14);
  static const int _maxCacheSizeBytes = 1024 * 1024 * 1024; // 1 GB

  final CacheManager _cacheManager = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: _stalePeriod,
      maxNrOfCacheObjects: 300,
    ),
  );
  final Map<String, Future<File>> _inFlightDownloads = <String, Future<File>>{};

  Future<File> getVideoFile({
    required String videoUrl,
    required String videoPath,
  }) async {
    final key = _entryKey(videoPath);
    final cached = await getCachedVideoFile(videoPath: videoPath);
    if (cached != null) {
      return cached;
    }

    return _downloadAndIndex(videoUrl: videoUrl, key: key);
  }

  Future<File?> getCachedVideoFile({required String videoPath}) async {
    final key = _entryKey(videoPath);
    final cached = await _cacheManager.getFileFromCache(key);

    if (cached != null && await cached.file.exists()) {
      await _touchAndIndex(key: key, file: cached.file);
      await _cleanupIfNeeded();
      return cached.file;
    }

    return null;
  }

  Future<void> prefetchVideo({
    required String videoUrl,
    required String videoPath,
  }) async {
    final key = _entryKey(videoPath);
    final cached = await _cacheManager.getFileFromCache(key);
    if (cached != null && await cached.file.exists()) {
      await _touchAndIndex(key: key, file: cached.file);
      await _cleanupIfNeeded();
      return;
    }

    if (_inFlightDownloads.containsKey(key)) {
      return;
    }

    unawaited(_downloadAndIndex(videoUrl: videoUrl, key: key));
  }

  Future<File> _downloadAndIndex({
    required String videoUrl,
    required String key,
  }) {
    final existing = _inFlightDownloads[key];
    if (existing != null) {
      return existing;
    }

    final downloadFuture = _cacheManager.downloadFile(videoUrl, key: key).then((downloaded) async {
      await _touchAndIndex(key: key, file: downloaded.file);
      await _cleanupIfNeeded();
      return downloaded.file;
    }).whenComplete(() {
      _inFlightDownloads.remove(key);
    });

    _inFlightDownloads[key] = downloadFuture;
    return downloadFuture;
  }

  String _entryKey(String videoPath) {
    return videoPath.trim().replaceAll('\\', '/');
  }

  Future<void> _touchAndIndex({
    required String key,
    required File file,
  }) async {
    final now = DateTime.now();
    final size = await file.length();

    try {
      await file.setLastAccessed(now);
    } catch (_) {
      // Alguns sistemas podem negar esse metadado; o indice abaixo ainda
      // guarda o ultimo acesso usado pela limpeza.
    }

    final entries = await _readIndex();
    entries[key] = _VideoCacheEntry(
      key: key,
      filePath: file.path,
      sizeBytes: size,
      lastAccessedMillis: now.millisecondsSinceEpoch,
    );
    await _writeIndex(entries);
  }

  Future<void> _cleanupIfNeeded() async {
    final entries = await _readIndex();
    if (entries.isEmpty) return;

    var changed = false;
    final now = DateTime.now();
    final staleBefore = now.subtract(_stalePeriod).millisecondsSinceEpoch;

    for (final entry in entries.values.toList(growable: false)) {
      if (entry.filePath.isEmpty) {
        entries.remove(entry.key);
        changed = true;
        continue;
      }

      final file = File(entry.filePath);
      final exists = await file.exists();
      final isStale = entry.lastAccessedMillis < staleBefore;

      if (!exists || isStale) {
        await _removeEntry(entry);
        entries.remove(entry.key);
        changed = true;
      } else {
        final actualSize = await file.length();
        if (actualSize != entry.sizeBytes) {
          entries[entry.key] = entry.copyWith(sizeBytes: actualSize);
          changed = true;
        }
      }
    }

    var totalSize = entries.values.fold<int>(
      0,
      (total, entry) => total + entry.sizeBytes,
    );

    if (totalSize > _maxCacheSizeBytes) {
      final oldestFirst = entries.values.toList(growable: false)
        ..sort(
          (a, b) => a.lastAccessedMillis.compareTo(b.lastAccessedMillis),
        );

      for (final entry in oldestFirst) {
        if (totalSize <= _maxCacheSizeBytes) break;

        await _removeEntry(entry);
        totalSize -= entry.sizeBytes;
        entries.remove(entry.key);
        changed = true;
      }
    }

    if (changed) {
      await _writeIndex(entries);
    }
  }

  Future<void> _removeEntry(_VideoCacheEntry entry) async {
    await _cacheManager.removeFile(entry.key);

    final file = File(entry.filePath);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {
        // Best-effort: o CacheManager tambem pode remover o arquivo depois.
      }
    }
  }

  Future<Map<String, _VideoCacheEntry>> _readIndex() async {
    final file = await _indexFile();
    if (!await file.exists()) return <String, _VideoCacheEntry>{};

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return <String, _VideoCacheEntry>{};
      }

      return decoded.map((key, value) {
        return MapEntry(
          key,
          _VideoCacheEntry.fromJson(
            key: key,
            json: value as Map<String, dynamic>,
          ),
        );
      });
    } catch (_) {
      return <String, _VideoCacheEntry>{};
    }
  }

  Future<void> _writeIndex(Map<String, _VideoCacheEntry> entries) async {
    final file = await _indexFile();
    final encoded = entries.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await file.writeAsString(jsonEncode(encoded), flush: true);
  }

  Future<File> _indexFile() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(
      '${supportDir.path}${Platform.pathSeparator}$_cacheKey',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}${Platform.pathSeparator}index.json');
  }
}

class _VideoCacheEntry {
  final String key;
  final String filePath;
  final int sizeBytes;
  final int lastAccessedMillis;

  const _VideoCacheEntry({
    required this.key,
    required this.filePath,
    required this.sizeBytes,
    required this.lastAccessedMillis,
  });

  factory _VideoCacheEntry.fromJson({
    required String key,
    required Map<String, dynamic> json,
  }) {
    return _VideoCacheEntry(
      key: key,
      filePath: (json['filePath'] ?? '').toString(),
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      lastAccessedMillis:
          (json['lastAccessedMillis'] as num?)?.toInt() ?? 0,
    );
  }

  _VideoCacheEntry copyWith({int? sizeBytes}) {
    return _VideoCacheEntry(
      key: key,
      filePath: filePath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      lastAccessedMillis: lastAccessedMillis,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'sizeBytes': sizeBytes,
      'lastAccessedMillis': lastAccessedMillis,
    };
  }
}

// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Downloads a file from a network URL into the app's Documents directory.
///
/// Returns only the filename (not the full path).
Future<String> downloadNetworkPath(String path) async {
  final uri = Uri.parse(path);

  // Derive filename from URL
  String filename = 'downloaded.bin';
  if (uri.pathSegments.isNotEmpty) {
    final last = uri.pathSegments.last;
    filename = (last.isEmpty) ? filename : last;
  }

  final docsDir = await getApplicationDocumentsDirectory();
  final filePath = '${docsDir.path}/$filename';
  final file = File(filePath);

  debugPrint('[Downloader] Target filename: $filename');
  debugPrint('[Downloader] Will be saved at: $filePath');

  final client = HttpClient()
    ..autoUncompress = true
    ..connectionTimeout = const Duration(seconds: 30);

  // HEAD to check remote size
  Future<int?> _remoteSize() async {
    try {
      final req = await client.openUrl('HEAD', uri);
      final resp = await req.close();
      if (resp.statusCode >= 200 && resp.statusCode < 400) {
        final lenStr = resp.headers.value(HttpHeaders.contentLengthHeader);
        if (lenStr != null) return int.tryParse(lenStr);
      }
    } catch (e) {
      debugPrint('[Downloader] HEAD request failed: $e');
    }
    return null;
  }

  int existing = 0;
  if (await file.exists()) {
    existing = await file.length();
    debugPrint('[Downloader] Existing partial file: $existing bytes');
  }

  int? remoteLen = await _remoteSize();
  if (remoteLen != null) {
    debugPrint('[Downloader] Remote file size: $remoteLen bytes');
  } else {
    debugPrint('[Downloader] Remote file size unknown');
  }

  if (remoteLen != null && existing > 0 && existing == remoteLen) {
    debugPrint('[Downloader] File already complete, skipping download');
    return filename;
  }

  HttpClientRequest req = await client.getUrl(uri);
  if (existing > 0) {
    req.headers.set(HttpHeaders.rangeHeader, 'bytes=$existing-');
    debugPrint('[Downloader] Requesting range: bytes=$existing-');
  }

  req.headers.set(HttpHeaders.userAgentHeader, 'FlutterFlow-Downloader/1.0');

  HttpClientResponse resp = await req.close();
  debugPrint('[Downloader] Server responded with: ${resp.statusCode}');

  if (resp.statusCode == 416) {
    debugPrint(
        '[Downloader] 416 Range Not Satisfiable — restarting from scratch');
    try {
      await file.delete();
    } catch (_) {}
    existing = 0;
    final retry = await client.getUrl(uri);
    retry.headers
        .set(HttpHeaders.userAgentHeader, 'FlutterFlow-Downloader/1.0');
    resp = await retry.close();
  }

  if (resp.statusCode != 200 && resp.statusCode != 206) {
    throw HttpException(
      'HTTP ${resp.statusCode} while downloading $path',
      uri: uri,
    );
  }

  final sink = file.openWrite(
      mode: existing > 0 && resp.statusCode == 206
          ? FileMode.append
          : FileMode.write);

  int downloaded = existing;
  final totalBytes =
      (resp.headers.value(HttpHeaders.contentLengthHeader) != null)
          ? int.tryParse(resp.headers.value(HttpHeaders.contentLengthHeader)!)
          : null;

  debugPrint('[Downloader] Starting stream write…');
  try {
    await for (final chunk in resp) {
      sink.add(chunk);
      downloaded += chunk.length;
      if (totalBytes != null) {
        final pct =
            (downloaded / (existing + totalBytes) * 100).toStringAsFixed(1);
        debugPrint('[Downloader] Progress: $downloaded bytes (${pct}%)');
      } else {
        debugPrint('[Downloader] Progress: $downloaded bytes');
      }
    }
  } catch (e) {
    debugPrint('[Downloader] Error during download: $e');
    await sink.flush();
    await sink.close();
    rethrow;
  }

  await sink.flush();
  await sink.close();
  client.close(force: true);

  debugPrint('[Downloader] Completed: $downloaded bytes written to $filePath');

  return filename;
}

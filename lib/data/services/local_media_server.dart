import 'dart:async';
import 'dart:io';

/// A tiny HTTP server that serves a single local file over the LAN so a
/// Chromecast can fetch it (Cast devices can't read file:// paths on the phone).
/// Supports HTTP Range requests, which Cast needs for seeking.
class LocalMediaServer {
  HttpServer? _server;
  String? _filePath;

  static const _mimeTypes = {
    '.mp4': 'video/mp4',
    '.m4v': 'video/mp4',
    '.mkv': 'video/x-matroska',
    '.webm': 'video/webm',
    '.mov': 'video/quicktime',
    '.avi': 'video/x-msvideo',
    '.3gp': 'video/3gpp',
    '.ts': 'video/mp2t',
  };

  String contentTypeFor(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return 'video/mp4';
    return _mimeTypes[path.substring(dot).toLowerCase()] ?? 'video/mp4';
  }

  /// Start serving [filePath]. Returns a URL reachable on the LAN, or null if
  /// no suitable network address was found.
  Future<String?> serve(String filePath) async {
    await stop();
    final file = File(filePath);
    if (!await file.exists()) return null;
    _filePath = filePath;

    final ip = await _lanAddress();
    if (ip == null) return null;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      _server!.listen(_handleRequest);
      return 'http://$ip:${_server!.port}/media';
    } catch (_) {
      // Don't leave a bound-but-unusable socket orphaned if listen() or
      // anything after bind() fails.
      await stop();
      return null;
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = _filePath;
    if (path == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    final file = File(path);
    if (!await file.exists()) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final length = await file.length();
    final contentType = contentTypeFor(path);
    final res = request.response;
    res.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
    res.headers.contentType = ContentType.parse(contentType);

    final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
    if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
      final range = rangeHeader.substring(6).split('-');
      final start = int.tryParse(range[0]) ?? 0;
      final end = (range.length > 1 && range[1].isNotEmpty)
          ? (int.tryParse(range[1]) ?? length - 1)
          : length - 1;
      final safeEnd = end >= length ? length - 1 : end;

      res.statusCode = HttpStatus.partialContent;
      res.headers.set(HttpHeaders.contentRangeHeader,
          'bytes $start-$safeEnd/$length');
      res.headers.set(HttpHeaders.contentLengthHeader, safeEnd - start + 1);
      try {
        await res.addStream(file.openRead(start, safeEnd + 1));
      } catch (_) {}
    } else {
      res.statusCode = HttpStatus.ok;
      res.headers.set(HttpHeaders.contentLengthHeader, length);
      try {
        await res.addStream(file.openRead());
      } catch (_) {}
    }
    await res.close();
  }

  /// Find a usable LAN IPv4 address (prefers private 192.168/10.x ranges).
  Future<String?> _lanAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      String? fallback;
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (ip.startsWith('192.168.') ||
              ip.startsWith('10.') ||
              ip.startsWith('172.')) {
            return ip;
          }
          fallback ??= ip;
        }
      }
      return fallback;
    } catch (_) {
      return null;
    }
  }

  Future<void> stop() async {
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
    _filePath = null;
  }
}

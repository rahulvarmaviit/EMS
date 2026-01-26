import 'dart:async';
import 'package:http/http.dart' as http;

class MultipartRequestWithProgress extends http.MultipartRequest {
  final void Function(int bytes, int totalBytes) onProgress;

  MultipartRequestWithProgress(
    super.method,
    super.url, {
    required this.onProgress,
  });

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final total = contentLength;
    int bytes = 0;

    final t = StreamTransformer.fromHandlers(
      handleData: (List<int> data, EventSink<List<int>> sink) {
        bytes += data.length;
        if (total > 0) {
          onProgress(bytes, total);
        }
        sink.add(data);
      },
    );

    final stream = byteStream.transform(t);
    return http.ByteStream(stream);
  }
}

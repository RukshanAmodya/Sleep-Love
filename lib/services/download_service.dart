import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  final Dio _dio = Dio();

  Future<String?> downloadSound(String url, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = "${dir.path}/$fileName";
      
      final file = File(path);
      if (await file.exists()) return path;

      await _dio.download(url, path);
      return path;
    } catch (e) {
      print("Download error: $e");
      return null;
    }
  }

  Future<void> deleteSound(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/$fileName");
    if (await file.exists()) {
      await file.delete();
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DownloadRecord {
  final String title, filename, location, sourceUrl;
  final DateTime completedAt;
  const DownloadRecord({required this.title, required this.filename,
    required this.location, required this.sourceUrl, required this.completedAt});

  Map<String, dynamic> toJson() => {
    'title': title, 'filename': filename, 'location': location,
    'source_url': sourceUrl, 'completed_at': completedAt.toIso8601String(),
  };

  factory DownloadRecord.fromJson(Map<String, dynamic> json) => DownloadRecord(
    title: json['title']?.toString() ?? '',
    filename: json['filename']?.toString() ?? '',
    location: json['location']?.toString() ?? '',
    sourceUrl: json['source_url']?.toString() ?? '',
    completedAt: DateTime.tryParse(json['completed_at']?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );
}

List<DownloadRecord> parseDownloadHistory(String content) {
  final data = jsonDecode(content);
  if (data is! List) throw const FormatException('Historico invalido');
  return data.whereType<Map<String, dynamic>>()
    .map(DownloadRecord.fromJson).take(100).toList();
}

class DownloadHistoryStore {
  Future<File> _file() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}downloads_history.json');
  }

  Future<List<DownloadRecord>> load() async {
    final file = await _file();
    if (!await file.exists()) return [];
    return parseDownloadHistory(await file.readAsString());
  }

  Future<void> save(List<DownloadRecord> records) async {
    final file = await _file();
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(records.take(100).map((e) => e.toJson()).toList()), flush: true);
    if (await file.exists()) await file.delete();
    await temp.rename(file.path);
  }
}

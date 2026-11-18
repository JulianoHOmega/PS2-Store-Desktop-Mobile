import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ps2_store/download_history.dart';

void main() {
  test('historico faz round-trip em JSON', () {
    final record = DownloadRecord(title: 'App', filename: 'app.elf',
      location: 'Downloads/app.elf', sourceUrl: 'https://example.org/app.elf',
      completedAt: DateTime.utc(2026, 11, 18));
    final decoded = parseDownloadHistory(jsonEncode([record.toJson()]));
    expect(decoded, hasLength(1));
    expect(decoded.single.filename, 'app.elf');
    expect(decoded.single.completedAt, DateTime.utc(2026, 11, 18));
  });
  test('historico vazio', () {
    expect(parseDownloadHistory('[]'), isEmpty);
  });
}

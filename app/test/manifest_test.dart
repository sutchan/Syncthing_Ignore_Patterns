import 'package:flutter_test/flutter_test.dart';
import 'package:syncthing_ignore_gui/models/manifest.dart';

void main() {
  test('StignoreRecord round-trips through JSON', () {
    const rec = StignoreRecord(
      path: r'C:\x\.stignore',
      size: 12,
      lastWriteUtc: '2026-01-01T00:00:00.000Z',
      foundAtUtc: '2026-01-02T00:00:00.000Z',
    );
    final back = StignoreRecord.fromJson(rec.toJson());
    expect(back.path, rec.path);
    expect(back.size, 12);
    expect(back.lastWriteUtc, rec.lastWriteUtc);
    expect(back.foundAtUtc, rec.foundAtUtc);
  });

  test('Manifest.fromJson tolerates missing fields and counts files', () {
    final m = Manifest.fromJson(const <String, dynamic>{});
    expect(m.version, '0.0.0');
    expect(m.roots, isEmpty);
    expect(m.files, isEmpty);
    expect(m.count, 0);
  });

  test('Manifest.toJson includes count, roots and records', () {
    final m = Manifest(
      version: '1.0.0',
      scannedAt: 'now',
      roots: const [r'C:\'],
      files: const [
        StignoreRecord(path: 'a', size: 1, lastWriteUtc: '', foundAtUtc: ''),
      ],
    );
    final json = m.toJson();
    expect(json['count'], 1);
    expect((json['files'] as List<dynamic>).length, 1);
    expect(json['roots'], [r'C:\']);
  });
}

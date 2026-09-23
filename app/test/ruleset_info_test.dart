// Ruleset header parsing and version ordering.
import 'package:flutter_test/flutter_test.dart';
import 'package:syncthing_ignore_gui/models/ruleset_info.dart';

void main() {
  test('parse reads the version and updated date from the header', () {
    const content = '//Syncthing Ignore Patterns Lists\r\n'
        '//Version: 1.18.5\r\n'
        '//Updated: 2026-09-22\r\n'
        '\r\n'
        '**/node_modules/\r\n';

    final info = RulesetInfo.parse(content);

    expect(info, isNotNull);
    expect(info!.version, '1.18.5');
    expect(info.updated, '2026-09-22');
  });

  test('parse tolerates a BOM, extra spaces and a missing updated line', () {
    final info = RulesetInfo.parse('\uFEFF  //  version :  2.0  \n**/x/\n');

    expect(info?.version, '2.0');
    expect(info?.updated, isNull);
  });

  test('parse returns null when no version header exists', () {
    expect(RulesetInfo.parse('**/node_modules/\n'), isNull);
    expect(RulesetInfo.parse(''), isNull);
  });

  test('compareRulesetVersions orders dotted numeric versions', () {
    expect(compareRulesetVersions('1.18.6', '1.18.5'), greaterThan(0));
    expect(compareRulesetVersions('1.18.5', '1.18.6'), lessThan(0));
    expect(compareRulesetVersions('1.18.5', '1.18.5'), 0);
    expect(compareRulesetVersions('1.19', '1.18.9'), greaterThan(0));
    expect(compareRulesetVersions('2', '1.99.99'), greaterThan(0));
    expect(compareRulesetVersions('1.19', '1.19.0'), 0);
    expect(compareRulesetVersions('x.y', '0.0'), 0);
  });
}

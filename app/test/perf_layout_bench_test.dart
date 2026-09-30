// ignore_for_file: avoid_print

/// First-frame build-count benchmark for the v1.28.0 layout change.
///
/// Pre-v1.28.0 the page was a SingleChildScrollView > Column containing two
/// nested fixed-height ListViews. Each inner viewport laid out its own window
/// of rows on the first frame even though both lists sat below the fold, so
/// both row sets were built eagerly-ish (two independent viewports).
///
/// Since v1.28.0 the page is one CustomScrollView whose result/log sections
/// are SliverList.builders: rows are built only when they intersect the real
/// viewport (plus its cache extent), and the two sections share one scroll
/// position.
///
/// Besides printing numbers for `docs/performance.md`, this test guards
/// against reintroducing off-screen row builds.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// More rows than could ever fit a viewport (like a very large sync tree).
  const resultRows = 10000;
  const logRows = 1000;

  /// Taller than the default 600 px test viewport, pushing both lists below
  /// the fold on first frame (as in the real app).
  const formHeight = 560.0;

  /// Fixed row heights keep counts platform-independent.
  const resultRowHeight = 24.0;
  const logRowHeight = 18.0;

  testWidgets('old nested-viewport layout builds both off-screen row windows',
      (tester) async {
    var resultBuilt = 0;
    var logBuilt = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: formHeight),
              SizedBox(
                height: 160,
                child: Card(
                  child: ListView.builder(
                    itemCount: resultRows,
                    itemBuilder: (_, __) => _CountingRow(
                      height: resultRowHeight,
                      onBuild: () => resultBuilt++,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 200,
                child: Card(
                  child: ListView.builder(
                    itemCount: logRows,
                    itemBuilder: (_, __) => _CountingRow(
                      height: logRowHeight,
                      onBuild: () => logBuilt++,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));

    print('BENCH old-layout first frame: result rows built = $resultBuilt, '
        'log rows built = $logBuilt, total = ${resultBuilt + logBuilt}');

    // Both inner viewports build their fixed window even off-screen.
    expect(resultBuilt, greaterThan(0));
    expect(logBuilt, greaterThan(0));
  });

  testWidgets('sliver layout builds only rows intersecting the real viewport',
      (tester) async {
    var resultBuilt = 0;
    var logBuilt = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          key: const Key('bench-scroll'),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: formHeight)),
            SliverList.builder(
              itemCount: resultRows,
              itemBuilder: (_, __) => _CountingRow(
                height: resultRowHeight,
                onBuild: () => resultBuilt++,
              ),
            ),
            SliverList.builder(
              itemCount: logRows,
              itemBuilder: (_, __) => _CountingRow(
                height: logRowHeight,
                onBuild: () => logBuilt++,
              ),
            ),
          ],
        ),
      ),
    ));

    print('BENCH new-layout first frame: result rows built = $resultBuilt, '
        'log rows built = $logBuilt, total = ${resultBuilt + logBuilt}');

    // The log section is thousands of rows below the fold: sliver layout
    // builds at most one boundary probe row (RenderSliverList lays out a
    // trailing child to estimate the scroll extent), never its viewport.
    expect(logBuilt, lessThanOrEqualTo(1));
    // Only a viewport-plus-cache slice of results exists, never the 10k list.
    expect(resultBuilt, lessThan(30));

    // Scrolling builds rows on demand; the log section is still far away.
    await tester.drag(
        find.byKey(const Key('bench-scroll')), const Offset(0, -500));
    await tester.pump();
    print('BENCH new-layout after 500px drag: result rows built = '
        '$resultBuilt, log rows built = $logBuilt');
    expect(logBuilt, lessThanOrEqualTo(1));
    expect(resultBuilt, lessThan(50));
  });
}

/// Fixed-height row that counts how many times the framework built it.
class _CountingRow extends StatelessWidget {
  const _CountingRow({required this.height, required this.onBuild});

  final double height;
  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    // Benchmark harness only: record that this row entered the tree.
    onBuild();
    return SizedBox(height: height, child: const Text('row'));
  }
}

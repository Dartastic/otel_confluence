// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_confluence/otel_confluence.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_confluence-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('page.create records CLIENT span', () async {
    await tracedConfluence<String>(
      resource: 'page',
      action: 'create',
      site: 'acme.atlassian.net',
      spaceKey: 'ENG',
      invoke: () async => 'page-id',
    );
    final a = attrsOf(spans.findSpanByName('confluence page.create')!);
    expect(a['confluence.resource'], 'page');
    expect(a['confluence.action'], 'create');
    expect(a['confluence.operation'], 'page.create');
    expect(a['confluence.site'], 'acme.atlassian.net');
    expect(a['confluence.space.key'], 'ENG');
  });

  test('suppression skips spans', () async {
    await runWithoutConfluenceInstrumentationAsync(() async {
      await tracedConfluence<String>(
        resource: 'page',
        action: 'create',
        site: 's',
        invoke: () async => 'p',
      );
    });
    expect(spans.findSpansStartingWith('confluence '), isEmpty);
  });
}

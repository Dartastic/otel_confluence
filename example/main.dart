// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_confluence/otel_confluence.dart';

/// Traces Confluence calls with OpenTelemetry.
///
/// `otel_confluence` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Confluence call in
/// [tracedConfluence]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'confluence-example');

  // Wraps any Confluence Cloud REST call in a CLIENT span.
  final confluenceId = await tracedConfluence<String>(
    resource: 'Order',
    action: 'example',
    site: 'example',
    spaceKey: 'orders/2026/inv-1042.pdf',
    pageId: 'page_8f3a2c',
    invoke: () async {
      // Make the Confluence call here, then report what it returned.
      return 'confluence_8f3a2c';
    },
  );
  OTelLog.info('tracedConfluence returned $confluenceId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutConfluenceInstrumentationAsync.
  await runWithoutConfluenceInstrumentationAsync(
    () => tracedConfluence<String>(
      resource: 'Order',
      action: 'example',
      site: 'example',
      spaceKey: 'orders/2026/inv-1042.pdf',
      pageId: 'page_8f3a2c',
      invoke: () async {
        return 'confluence_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}

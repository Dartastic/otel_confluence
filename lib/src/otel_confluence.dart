// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_confluence_suppression.dart';

const _tracerName = 'dartastic_otel_libs_confluence';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

/// Wraps any Confluence Cloud REST call in a CLIENT span.
Future<T> tracedConfluence<T>({
  required String resource,
  required String action,
  required String site,
  required Future<T> Function() invoke,
  String? spaceKey,
  String? pageId,
}) async {
  if (confluenceInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'confluence.resource': resource,
    'confluence.action': action,
    'confluence.operation': '$resource.$action',
    'confluence.site': site,
  };
  if (spaceKey != null) m['confluence.space.key'] = spaceKey;
  if (pageId != null) m['confluence.page.id'] = pageId;

  final span = _tracer().startSpan(
    'confluence $resource.$action',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

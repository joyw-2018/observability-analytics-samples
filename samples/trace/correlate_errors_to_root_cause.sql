-- Join traces and logs to inspect error details for a specific method.
-- Use Case 3: Correlate errors to root cause with combined views
-- Imagine seeing a spike in errors in your logs. With a combined log and trace
-- view, you can instantly filter for the traces associated with those errors.
-- This allows you to visualize the entire request path that led to the failure,
-- including the services involved, request parameters, and timing for each step,
-- dramatically reducing your mean time to resolution (MTTR).

SELECT
  t.trace_id,
  t.span_id,
  t.name AS method_name,
  t.duration_nano / 1000000 AS latency_ms,
  l.timestamp,
  l.severity,
  JSON_VALUE(l.json_payload.errorMessage) AS error_message
FROM
  `YOUR_PROJECT_ID.us._Trace.Spans._AllSpans` AS t
JOIN
  `YOUR_PROJECT_ID.us._Default._AllLogs` AS l
ON
  -- Extract trace_id from the full trace path in _AllLogs
  t.trace_id = SPLIT(l.trace, '/')[SAFE_OFFSET(3)]
  -- Match span_id (note camelCase spanId in _AllLogs)
  AND t.span_id = l.spanId
WHERE
  t.name = 'YourService.YourMethod'
  AND t.status.code = 2
  AND l.severity = 'ERROR'
ORDER BY
  l.timestamp DESC

-- Find all failed tool execution spans (where the status is not OK) and join
-- them with the agent logs to retrieve the exact LLM prompt and thought process
-- that triggered the failed tool call.

WITH failed_tool_calls AS (
  SELECT
    trace_id,
    span_id,
    -- Extract the tool name from the span attributes
    JSON_VALUE(attributes, '$."agent.tool.name"') AS tool_name,
    duration_nano / 1000000 AS latency_ms
  FROM
    `YOUR_PROJECT_ID.us._Trace.Spans._AllSpans`
  WHERE
    -- status.code = 2 indicates an error in OpenTelemetry
    status.code = 2
    -- Filter for spans that represent tool executions
    AND name = 'Agent.executeTool'
)
SELECT
  t.tool_name,
  t.latency_ms,
  l.timestamp,
  -- Retrieve the agent's thought process and the prompt from logs
  JSON_VALUE(l.json_payload.agent_thoughts) AS agent_reasoning,
  JSON_VALUE(l.json_payload.llm_prompt) AS prompt_sent_to_llm
FROM
  failed_tool_calls t
JOIN
  `YOUR_PROJECT_ID.us._Default._AllLogs` l
ON
  -- Join logs and traces on trace ID
  t.trace_id = SPLIT(l.trace, '/')[SAFE_OFFSET(3)]
  -- Match the exact span where the tool was executed
  AND t.span_id = l.spanId
WHERE
  -- Retrieve the log entry that captured the LLM context for this span
  JSON_VALUE(l.json_payload.event_type) = 'agent_llm_call'
ORDER BY
  l.timestamp DESC
LIMIT 50

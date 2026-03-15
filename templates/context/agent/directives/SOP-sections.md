
## 10. Pipeline Design

- Every pipeline stage must have explicit input/output type contracts
- Use structured logging at each pipeline stage boundary
- All pipeline stages must be independently testable
- Support dry-run mode for any destructive pipeline operations
- Pipeline state should be serializable for debugging and replay

## 11. Tool Registration

- All tools must be registered in a central registry
- Each tool must have: name, description, input schema, output schema
- Tool execution must be wrapped with error handling and timeout
- Tool results must be validated against their output schema
- Never expose raw tool errors to end users — wrap with actionable messages

## 12. Evaluation & Metrics

- Every agent capability must have at least one eval function
- Eval functions must return structured results (score, pass/fail, details)
- Track eval results over time to detect regressions
- Use deterministic test cases alongside LLM-judged evals
- Log all LLM calls with input/output for debugging

## 13. Autonomous Operation

- All API keys and credentials must come from environment variables
- Implement circuit breakers for external service calls
- Set hard limits on: max iterations, max tokens, max cost per run
- All autonomous loops must have a termination condition
- Log every decision point for auditability


## 10. Endpoint Design

- Use RESTful conventions or GraphQL schema-first design
- All endpoints must have explicit request/response schemas
- Use proper HTTP status codes (don't return 200 for errors)
- Version APIs when making breaking changes (e.g., `/api/v1/`, `/api/v2/`)
- Document all endpoints (OpenAPI/Swagger or equivalent)

## 11. Authentication & Authorization

- All non-public endpoints must require authentication
- Use middleware for auth checks — never inline auth logic in handlers
- Implement role-based access control (RBAC) or equivalent
- Token refresh must be handled gracefully
- Never log tokens, passwords, or session data

## 12. Rate Limiting & Security

- Apply rate limiting to all public endpoints
- Validate and sanitize all user input
- Use parameterized queries — never concatenate SQL strings
- Set proper CORS headers — never use `*` in production
- Implement request size limits to prevent abuse

## 13. Database Patterns

- Use an ORM or query builder — avoid raw SQL where possible
- All schema changes must be done through migrations
- Use database transactions for multi-step operations
- Index columns used in WHERE clauses and JOINs
- Never store plaintext passwords — use bcrypt/argon2

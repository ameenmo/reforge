
## 10. UI Components

- Use a component library (e.g., shadcn/ui, Radix, Ant Design) for consistency
- All components must be accessible (WCAG 2.1 AA minimum)
- No `dangerouslySetInnerHTML` unless explicitly approved and sanitized
- Use design tokens / CSS variables for theming — no hardcoded colors
- Component files should be self-contained: types, component, exports in one file
- Prefer composition over prop drilling — use context or state management where appropriate

## 11. Routing & Navigation

- Use file-based routing where supported (Next.js, TanStack Router, SvelteKit)
- All routes must have proper error boundaries
- Protected routes must check auth before rendering
- Use proper loading states for async route data

## 12. State Management

- Keep server state and client state separate
- Use the framework's data fetching primitives (React Query, SWR, loader functions)
- Minimize global client state — prefer local state and derived values
- Never store sensitive data (tokens, secrets) in client-side state

## 13. Deployment

- Build artifacts must be deterministic and reproducible
- All environment-specific config comes from environment variables
- Static assets should be served from a CDN
- Enable proper cache headers for static assets
- Health check endpoint must exist for monitoring

# Security

This is a **public repository**. Do not commit real API keys, tokens, passwords, or other credentials.

## Guidelines

- **Never commit secrets.** Use environment variables or a local `.env` file for any API keys, tokens, database credentials, or other sensitive configuration.
- **Never commit `.env`.** Only commit `.env.example` (or similar) templates with placeholder variable names and no real values. See [templates/env/.env.example](templates/env/.env.example) for the recommended template.
- **Keep credentials out of source.** If you need to test or run tools that require keys, set them in your environment or in a local `.env` that is not tracked (the root [.gitignore](.gitignore) excludes `.env`).

If you discover a credential that was committed, rotate it immediately and remove it from history (e.g. with a force-push after amending or rebasing, or by using GitHub’s secret scanning and revocation tools where applicable).

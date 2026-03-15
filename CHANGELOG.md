# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

## [0.1.0] - 2026-03-15

### Added

- `reforge analyze` command — diagnostic report with A-F grading across structure, large files, essentials, and secrets
- `reforge apply` command — non-destructive project restructuring with git backup, config generation, and AI context layer
- `reforge install-skills` command — standalone global skill installer
- Auto-detection for Node.js/TypeScript, Python, Go, Rust, Ruby, Java, PHP
- Framework detection: Next.js, React, Vue, Express, FastAPI, Django, Rails, and more
- Stack-specific .gitignore generation with merge support
- AI context layer templates (directives, .agent/, .claude/, tools/)
- Global skills: autoresearch, self-improve, context-hub, visualize, gstack
- Install script with clone and curl options
- Test fixtures: messy-node, messy-python, decent-project

---
trigger: always_on
---

### 🔄 Project Awareness & Context
- Always read `PLANNING.md` before coding to understand the high-level vision, architecture, and component versions.
- Consult `TASK.md` for the list of actionable items and their current status before starting any work.
- If a new task or dependency is discovered during development, log it immediately in the `Discovered During Work` section of `TASK.md`.

### 🧱 Code & Structure
- Adhere to the Single Responsibility Principle for all scripts and configurations.
- Keep individual files under a 500-line limit. If a file exceeds this, it must be refactored into smaller, more manageable modules.
- Use clear, descriptive, and consistent naming conventions for all variables, files, and Docker services.
- All shell scripts must be linted with `shellcheck` to avoid common errors.

### ✅ Task Completion
- When a task from the `Next` section in `TASK.md` is fully completed and verified, move it to the `Done` section.
- Update the task with the date of completion for clear project tracking, for example: `[x] 2025-07-02 | Deployed MinIO service`.

### 📎 Style & Conventions
- All Python code must be written for Python 3.11 and formatted with the `black` code formatter.
- Follow `PEP8` style guidelines for all Python code.
- All Dockerfile instructions should be clear, commented where necessary, and optimized for small image size.

### 🧠 AI Behaviour
- If the context for a task is insufficient, ambiguous, or conflicts with other instructions, you must ask for clarification before proceeding.
- Never hallucinate the existence of libraries, packages, environment variables, or files. Base all actions strictly on the provided project files and documentation.
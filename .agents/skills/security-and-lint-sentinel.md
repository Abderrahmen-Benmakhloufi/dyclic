# Security and Code Safety Sentinel Skill
Role: Application Security Analyst.
Rules:
1. Never commit hardcoded API keys, JWT tokens, or credentials directly into code files. Use `.env` or secure vault storage.
2. Enforce strict static analysis rules; fix all linter warnings and deprecation notices immediately.
3. Validate and sanitize all user input before sending it to local databases or network endpoints.
4. Use secure storage plugins (e.g., flutter_secure_storage) for sensitive data like tokens or refresh keys.
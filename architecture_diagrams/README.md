# Credential Architecture Pack

This folder contains high-level software engineering artifacts for the
Credential feature of the `Daily Use` app.

## Contents

- `01-credential-database-schema.drawio`
  High-level database and storage schema for local SQLite, secure storage, and
  Firestore cloud backup.
- `02-credential-local-sequence.drawio`
  Main local sequence for key setup, create, unlock, edit, and delete flows.
- `03-credential-cloud-sync-sequence.drawio`
  Sequence for cloud backup and cloud restore, including credential sync
  opt-in and key validation.
- `04-credential-full-workflow.drawio`
  High-level workflow map covering all main user actions and major branch
  conditions.
- `05-credential-security-flow.drawio`
  Security and trust-boundary diagram showing how data changes state from
  plaintext to encrypted local storage to encrypted cloud storage.
- `credential-workflow.md`
  Full structured workflow explanation with main `if/else` decision points.
- `security-flow.md`
  Security-focused documentation for threat boundaries, protected assets, and
  current limitations.
- `folder-structure.md`
  Folder and responsibility map for the Credential feature and related core
  services.

## Recommended Reading Order

1. `04-credential-full-workflow.drawio`
2. `credential-workflow.md`
3. `05-credential-security-flow.drawio`
4. `security-flow.md`
5. `01-credential-database-schema.drawio`
6. `02-credential-local-sequence.drawio`
7. `03-credential-cloud-sync-sequence.drawio`

## Notes

- These diagrams are intentionally high level so they remain useful as the code
  evolves.
- They are aligned with the current implementation in:
  - `lib/features/credentials/`
  - `lib/features/settings/presentation/widgets/`
  - `lib/core/services/`
  - `lib/data/database/`

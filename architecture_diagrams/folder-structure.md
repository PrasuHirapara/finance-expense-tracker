# Folder Structure and Responsibility Map

## Root-Level Documentation Folder

This architecture pack lives in:

```text
architecture_diagrams/
```

## Main Runtime Structure

```text
lib/
  app.dart
  core/
  data/
  features/
  shared/
```

## Credential Feature Structure

```text
lib/features/credentials/
  data/
    repositories/
      credential_repository.dart
    services/
      credential_service.dart
  domain/
    models/
      credential_models.dart
  presentation/
    pages/
      credential_module_page.dart
      credential_detail_page.dart
      credential_editor_page.dart
      credential_settings_page.dart
    widgets/
      credential_auth_dialog.dart
      credential_export_panel.dart
      credential_key_entry_dialog.dart
      credential_key_setup_dialog.dart
```

## Responsibility by Layer

### Domain

- `credential_models.dart`
- stable business data objects

### Data Repository

- `credential_repository.dart`
- SQLite CRUD and title search

### Data Service

- `credential_service.dart`
- business orchestration, encryption, decryption, key rotation

### Presentation

- UI, validation, dialogs, secure rendering

## Core Cross-Cutting Services

```text
lib/core/services/
  credential_crypto_service.dart
  credential_security_service.dart
  cloud_sync_service.dart
  cloud_sync_payload_service.dart
  firestore_cloud_sync_store_service.dart
```

## Local Data Storage Structure

```text
DbCredentials
  id
  title
  encryptedPayload
  saltBase64
  nonceBase64
  createdAt
  updatedAt
```

## Settings Integration

```text
lib/features/settings/presentation/widgets/
  cloud_sync_settings_section.dart
  credential_settings_section.dart
```

## Security Policy Artifacts

```text
firestore.rules
firebase.json
```

# Credential Security Flow

## Security Objectives

Primary goals:
- protect credential field values at rest on device
- protect credential titles and fields in cloud backup when credential sync is enabled
- ensure only the correct user account can access their Firestore backup
- preserve usability for list/search and unlock flows

## Protected Assets

High sensitivity:
- credential field values
- encryption key
- exported credential files
- cloud credential payload

Medium sensitivity:
- credential titles
- metadata such as updated timestamps

Current implementation choice:
- local titles are visible in SQLite
- cloud titles are encrypted before upload

## Trust Boundaries

### Boundary 1: UI to Application Logic

User input enters through:
- credential editor
- key setup dialog
- unlock/auth dialog
- cloud sync settings

### Boundary 2: Application Logic to Secure Storage

Encryption key is stored in OS-backed secure storage.

### Boundary 3: Application Logic to Local SQLite

Credential secure fields are never stored as plaintext in SQLite.

Stored values:
- encrypted payload
- salt
- nonce
- plaintext title

### Boundary 4: Application Logic to Firestore

When credential cloud backup is enabled:
- encrypted field payload is uploaded
- title is encrypted separately before upload

When credential cloud backup is disabled:
- credential cloud document is deleted

## Cryptographic Flow

1. User provides encryption key.
2. Key is stored in secure storage.
3. On save, fields are serialized to JSON.
4. PBKDF2 derives an AES key using the user key and per-record salt.
5. AES-GCM encrypts the payload using a per-record nonce.
6. Encrypted payload, salt, and nonce are stored.

## Authentication Flow

### Key-Based Unlock

1. User enters encryption key.
2. App compares input against secure-storage key.
3. If match, decrypt target record.
4. Else reject.

### Biometric Unlock

1. User enables biometric unlock in Credential settings.
2. User requests secure operation.
3. App performs biometric authentication.
4. On success, app reads stored key from secure storage.
5. App uses that key to decrypt.

## Key Rotation Security Behavior

Key rotation must preserve decryptability.

Implemented behavior:
- decrypt every credential using old key
- re-encrypt every credential using new key
- update stored key
- if cloud credential backup enabled, upload fresh cloud copy

## Restore Fault Tolerance

Restore path:

1. Download remote bundle.
2. Build local rollback snapshot.
3. Attempt restore.
4. If restore fails, restore local rollback snapshot.

## Known Limitation

Local title is plaintext in SQLite.

Tradeoff:
- better usability for search/list
- weaker privacy against direct database inspection

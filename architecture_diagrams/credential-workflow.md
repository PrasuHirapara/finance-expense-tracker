# Credential Workflow

## 1. Entry Point

The Credential module starts from the Credential tab UI.

Main screen:
- `CredentialModulePage`

Related services:
- `CredentialService`
- `CredentialSecurityService`
- `CredentialCryptoService`
- `CredentialRepository`

## 2. First-Time Tab Open

When the user opens the Credential tab:

1. Check whether an encryption key already exists in secure storage.
2. If the key exists:
   - allow normal Credential tab usage
   - show credential list and search
3. Else:
   - block normal usage
   - show the key setup prompt

Decision:

```text
IF secure storage has encryption key
  THEN open module normally
ELSE
  force key setup before credential operations
```

## 3. Set Encryption Key

The user must enter:
- encryption key
- confirmation key

Decision:

```text
IF key is empty OR confirmation is empty
  THEN reject
ELSE IF key != confirmation
  THEN reject
ELSE
  save key into secure storage
  allow Credential module usage
```

## 4. Create Credential

User inputs:
- title
- one or more key/value secure fields

Validation:

```text
IF title is empty
  THEN reject
ELSE IF all secure rows are empty
  THEN reject
ELSE IF any row has only key or only value
  THEN reject
ELSE
  continue
```

Create flow:

1. Read encryption key from secure storage.
2. Serialize secure fields to JSON.
3. Generate random salt.
4. Generate random nonce.
5. Derive encryption secret from user key using PBKDF2.
6. Encrypt field payload using AES-GCM.
7. Save record to local SQLite.

Saved locally:
- `title`
- `encryptedPayload`
- `saltBase64`
- `nonceBase64`
- timestamps

## 5. List and Search Credentials

The list screen shows:
- credential title
- lock icon
- secure view action

Search behavior:

```text
IF search query is empty
  THEN return all credential rows ordered by updatedAt desc
ELSE
  filter by title LIKE query
```

Important:
- secure field values are never shown in list view
- decryption does not happen for list rendering

## 6. Unlock and View Credential

When the user taps `View Securely`:

1. Load credential row by id.
2. Ask user to authenticate.

Authentication options:
- encryption key
- biometrics, only if enabled and supported

Decision:

```text
IF record not found
  THEN show not found
ELSE IF user cancels auth
  THEN close detail flow
ELSE IF key auth succeeds
  THEN decrypt
ELSE IF biometric auth succeeds
  THEN fetch stored key and decrypt
ELSE
  reject access
```

## 7. Edit Credential

Edit starts only after the credential has already been unlocked.

Decision:

```text
IF user updates title or fields and passes validation
  THEN re-encrypt field payload with current stored key
  update SQLite row
ELSE
  reject save
```

Important:
- local title stays searchable and visible in list
- secure fields are re-encrypted on every save

## 8. Delete Credential

Single record delete:

```text
IF user confirms delete
  THEN remove local row
ELSE
  do nothing
```

Bulk delete:

```text
IF user confirms delete all
  AND authentication succeeds
  THEN remove all local credential rows
  attempt cloud credential cleanup
ELSE
  do nothing
```

## 9. Change Encryption Key

This is a re-encryption flow, not a simple key replacement.

Decision:

```text
IF old key authentication fails
  THEN reject
ELSE IF new key invalid or mismatch
  THEN reject
ELSE
  decrypt every local credential with old key
  re-encrypt every credential with new key
  update local secure-storage key
  IF credential cloud backup is enabled
    rewrite cloud credential backup with new key context
```

## 10. Export Credential Data

Export requires authentication first.

Decision:

```text
IF authentication succeeds
  THEN decrypt selected credentials
  export plaintext output
ELSE
  reject export
```

Security note:
- exported files are sensitive plaintext material

## 11. Import Credential Data

Import requires:
- file selection
- authentication
- row validation

Decision:

```text
IF file missing
  THEN stop
ELSE IF authentication fails or user cancels
  THEN stop
ELSE IF any import row is invalid
  THEN reject entire import
ELSE
  encrypt imported field values
  store valid records locally
```

## 12. Cloud Sync

Cloud Sync has two independent controls:

- `cloudSync.enabled`
- `cloudSync.syncCredentials`

### Upload Decision Tree

```text
IF cloud sync disabled
  THEN reject upload
ELSE IF no internet
  THEN reject upload
ELSE IF no signed-in Firebase user
  THEN reject upload
ELSE IF credential sync disabled
  THEN upload manifest + expense + task only
       delete existing cloud credential doc
ELSE
  require valid credential key
  verify key against local encrypted record
  encrypt titles for cloud
  upload manifest + credential + expense + task
```

### Restore Decision Tree

```text
IF cloud sync disabled
  THEN reject restore
ELSE IF no internet
  THEN reject restore
ELSE IF no backup exists
  THEN reject restore
ELSE IF local data newer AND forceOverwrite == false
  THEN warn user
ELSE
  build rollback snapshot
  restore expense and task
  IF cloud backup contains credential data
    THEN require correct key to decrypt cloud titles
         restore credentials
  ELSE
    preserve existing local credentials
```

## 13. Firestore Access Control

Cloud access policy:

```text
Only authenticated user {uid}
can read/write:
  /users/{uid}
  /users/{uid}/cloud_sync/{manifest|credential|expense|task}
```

## 14. Current Security Position

Protected well:
- secure field payloads
- secure key storage
- biometric gate
- encrypted credential titles in cloud backup
- per-user Firestore access restriction

Current limitation:
- local credential `title` remains plaintext in SQLite so that list/search
  remain simple and fast

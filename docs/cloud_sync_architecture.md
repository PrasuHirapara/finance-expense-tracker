# Cloud Sync Architecture

## Architecture Diagram

```text
+------------------------------+
| Settings / Module Screens    |
| - Sync Now                   |
| - Restore from Cloud         |
| - Auto Backup toggle/time    |
| - Delete local/module data   |
+--------------+---------------+
               |
               v
+------------------------------+
| CloudSyncService             |
| - uploadDataToDrive()        |
| - downloadDataFromDrive()    |
| - deleteDriveFolder()        |
| - scheduleAutoBackup()       |
+-------+-----------+----------+
        |           |           
        |           +----------------------+
        |                                  |
        v                                  v
+----------------------+       +--------------------------+
| CloudSyncPayload     |       | CloudSyncScheduler       |
| - buildBackupBundle  |       | - Workmanager schedule   |
| - restoreBundle      |       | - background task policy |
| - encryptCredential  |       +--------------------------+
+----------+-----------+
           |
           +------------------+
           |                  |
           v                  v
+------------------+  +------------------------+
| AppDatabase      |  | TaskCategoryRepository |
| Credential/      |  | task_categories.json   |
| Expense/Task DB  |  +------------------------+
+------------------+

+-------------------------+      +--------------------------+
| GoogleDriveAuthService  | ---> | GoogleDriveApiService    |
| google_sign_in          |      | Drive folders/files HTTP |
+-------------------------+      +--------------------------+
```

## Manual Sync Flow

```text
User taps "Sync Now"
  -> Google Sign-In account/auth
  -> Build local snapshot
  -> Encrypt credential backup only
  -> Ensure Daily Use/ subfolders in Drive
  -> Upload manifest + credential + expense + task files
  -> Save last sync timestamp/account locally
```

## Restore Flow

```text
User taps "Restore from Cloud"
  -> Read Drive manifest
  -> Compare remote backup timestamp vs local latest change timestamp
  -> If local newer: warn before overwrite
  -> Download all three domain files
  -> Build local rollback snapshot
  -> Restore database + task category file
  -> If anything fails: rollback to pre-restore snapshot
```

## Background Flow

```text
App start
  -> Workmanager initialized
  -> If Cloud Sync + Auto Backup enabled
     -> periodic work scheduled

Workmanager background callback
  -> recreate repositories/services in background isolate
  -> check feature enabled + backup due for today
  -> attempt lightweight Google auth
  -> upload latest backup
```

## Retry and Error Policy

- Local storage is always primary. Cloud failures do not delete local data.
- Drive HTTP requests retry up to 3 times for timeouts, socket failures, HTTP 408, HTTP 429, and 5xx responses.
- Restore is transactional at the service level:
  - remote payload is fully downloaded first
  - current local snapshot is staged as rollback
  - restore runs
  - rollback is applied if restore throws
- If Cloud Sync is disabled:
  - no authentication is attempted
  - auto backup is canceled
  - background work is canceled

## OAuth Setup Notes

- Google OAuth client configuration is still required outside the codebase.
- `google_sign_in` is initialized from Dart defines:
  - `GOOGLE_DRIVE_CLIENT_ID`
  - `GOOGLE_DRIVE_IOS_CLIENT_ID`
  - `GOOGLE_DRIVE_SERVER_CLIENT_ID`
- iOS background processing is registered with:
  - `com.prasu.daily.use.cloud_sync.auto_backup`

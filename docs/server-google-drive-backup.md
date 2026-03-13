# Google Drive database backup

The production WAVE instance currently stores its live database in:

- `/opt/wave-messenger/data/db.json`

The backup workflow in `scripts/server/backup-wave-db-to-gdrive.sh` is designed for the production VPS and does the following:

1. Copies the JSON database into a temporary file.
2. Validates the snapshot with `node` to avoid uploading a partial write.
3. Compresses the snapshot to `wave-db-YYYYMMDD-HHMMSS.json.gz`.
4. Uploads the timestamped archive and `latest.json.gz` to a configured Google Drive folder through `rclone`.
5. Keeps local and remote timestamped archives for `RETENTION_DAYS`.

## Expected server files

- Script: `/usr/local/bin/backup-wave-db-to-gdrive.sh`
- Config: `/etc/wave-db-backup.env`
- rclone config: `/root/.config/rclone/rclone.conf`
- Local backup cache: `/root/deploy-backups/wave-db`
- Log file: `/var/log/wave-db-backup.log`

## One-time Google Drive authorization

The VPS needs an `rclone` remote named `gdrive`.

Typical headless flow:

1. Install `rclone` on the VPS.
2. Run `rclone config` on the VPS and create a `drive` remote named `gdrive`.
3. Complete the Google OAuth step from a browser.
4. Run the backup script once manually.
5. Enable the cron job.

## Suggested cron schedule

The setup is intended to run daily at 03:15 in `Asia/Yekaterinburg`:

```cron
CRON_TZ=Asia/Yekaterinburg
15 3 * * * /usr/local/bin/backup-wave-db-to-gdrive.sh
```

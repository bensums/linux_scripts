# linux_scripts

## Backup

On machine to be backed up (*source* machine):

1. Ensure borg backup is installed
1. Switch to root.
1. Make a password-less SSH key
1. Create `bin/backup/vars.sh` according to instructions in `bin/backup/backup.sh`
1. Save passphrase somewhere safe and secure, e.g. LastPass

On target machine:

1. Make sure borg backup is installed.
1. Make sure there's a dedicated user for borg backup
1. Add the following line to borg backup user's `.ssh/authorized_keys`

```bash
command="/usr/local/bin/borg serve --restrict-to-path [repo_path]",no-pty,no-agent-forwarding,no-port-forwarding,no-X11-forwarding,no-user-rc [key]
```

Back on source machine:

1. Source `bin/backup/vars.sh` and run `borg init -e repokey-blake2`
1. Schedule `bin/backup.sh` hourly.

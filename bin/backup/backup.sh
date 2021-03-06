#!/bin/bash
# System Backup Script for BorgBackup
# Before running this script, make sure vars are set in vars.sh:
# export BORG_REPO='borg-user@host:absolute_path_to_repo'
# export BORG_PASSPHRASE='a nice passphrase'
# export BORG_RSH='ssh -i ~/.ssh/id_rsa -o BatchMode=yes -o VerifyHostKeyDNS=yes'
# Then init the repo with
# borg init -e repokey-blake2
# repokey mode means the encryption key will be stored in the repo, but will be protected by our passphrase.
# repokey-blake2 is faster than the default SHA256 HMAC mode

# Setup environment variables
BASE_DIR=$(dirname "$0")
export BORG_RSH='ssh -i ~/.ssh/id_rsa -o BatchMode=yes -o VerifyHostKeyDNS=yes -o ServerAliveInterval=10 -o ServerAliveCountMax=30'
source $BASE_DIR/vars.sh

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*" >&2; }
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM

info "Starting backup"

# Backup the most important directories into an archive named after
# the machine this script is currently running on:

borg create                           \
    --remote-path /usr/local/bin/borg \
    --debug                           \
    --filter AME                      \
    --list                            \
    --stats                           \
    --show-rc                         \
    --compression lz4                 \
    --exclude-caches                  \
    --exclude '/dev/*'                \
    --exclude '/lost+found'           \
    --exclude '/mnt/*'                \
    --exclude '/media/*'              \
    --exclude '/proc/*'               \
    --exclude '/run/*'                \
    --exclude '/sys/*'                \
    --exclude '/.snapshots/*'         \
    --exclude '*/tmp/*'               \
    --exclude '/swapfile'             \
    --exclude '/timeshift/*'          \
    ::'{hostname}-{now:%Y-%m-%d}'     \
    /

backup_exit=$?

info "Pruning repository"

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The '{hostname}-' prefix is very important to
# limit prune's operation to this machine's archives and not apply to
# other machines' archives also:

borg prune                          \
    --list                          \
    --prefix '{hostname}-'          \
    --show-rc                       \
    --keep-daily    7               \
    --keep-weekly   4               \
    --keep-monthly  12              \
    --keep-yearly   99999           \

prune_exit=$?

# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

if [ ${global_exit} -eq 1 ];
then
    info "Backup and/or Prune finished with a warning"
fi

if [ ${global_exit} -gt 1 ];
then
    info "Backup and/or Prune finished with an error"
fi

exit ${global_exit}

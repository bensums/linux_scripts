#!/bin/bash
set -e
shopt -s extglob
BASE_DIR=$(dirname "$0")
DATE=$(date --iso-8601)
DATE_FILE=/backup/last_backup
PID_FILE=/backup/pid
ACL_DIR=/backup/acls/

if [ -f ${DATE_FILE} ] && [ $(cat ${DATE_FILE}) == ${DATE} ]; then
	echo 'already backed up today. exiting.'
	exit
fi

if [ -f ${PID_FILE} ] && ps -p $(cat ${PID_FILE})>/dev/null; then
	echo 'already running. exiting.'
	exit
fi

## Save PID
mkdir -p $(dirname ${PID_FILE})
echo $$ > ${PID_FILE}
## Save ACLs
echo Saving ACLs
# To restore: # setfacl --restore=${ACL_FILE}
mkdir -p ${ACL_DIR}
rm -rf ${ACL_DIR}*
for f in /!(dev|proc|sys|tmp|run|mnt|media|lost+found|swapfile); do
	ACL_FILE=${ACL_DIR}${f}.acls
	echo $f -\> $ACL_FILE
	getfacl -n -p -R $f > ${ACL_FILE}
done
echo done ACLs

## Backup
echo 'Starting backup in 10s'
sleep 10s
echo Backing up

$BASE_DIR/backup/backup.sh

# Save date
mkdir -p $(dirname ${DATE_FILE})
echo ${DATE} > ${DATE_FILE}
rm ${PID_FILE}

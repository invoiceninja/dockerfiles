#!/bin/bash
trap 'echo "Exit"; exit 1' 2
BAK_DATE=`date +"%Y-%m-%d-%H-%M-%S"`
BAK_DUMP=`printf "ninja.%s.sql" $BAK_DATE`
TGZ_FILE=`printf "ninja.%s.tgz" $BAK_DATE`
echo Create dumpfile $BAK_DUMP
docker-compose exec db mysqldump -u backup ninja -pninja > $BAK_DUMP
tar cvzf $TGZ_FILE $BAK_DUMP
rm $BAK_DUMP
echo remove old backup files
find . -name "*.tgz" -type f -mtime +30 -exec rm -f {} \;

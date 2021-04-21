#!/bin/bash
# Databases that you wish to be backed up by this script. You can have any number of databases specified; encapsilate each database name in single quotes and separate each database name by a space.
#
# Example:
# databases=( '__DATABASE_1__' '__DATABASE_2__' )
databases=( 'jiejiang' 'jiejiang-2-0' 'yatoo-bicycle' 'yatoo-charging' 'jiejiang-admin' 'charging-pile-yongl' 'charging-pile-teny' )

# The host name of the MySQL database server; usually 'localhost'
db_host=$(curl whatismyip.akamai.com)

# The port number of the MySQL database server; usually '3306'
db_port="3000"

# The MySQL user to use when performing the database backup.
db_user="root"

# The password for the above MySQL user.
db_pass="R9xxzmspqhKhJ7R"

# Directory to which backup files will be written. Should end with slash ("/").
backups_dir="/backup/"

volume_dir="/mnt/jjcx/mysql/volume/backup/"

backups_user="root"

# Date/time included in the file names of the database backup files.
datetime=$(date +'%Y-%m-%d-%H:%M:%S')


# Create database backup and compress using gzip.

for db_name in ${databases[@]}; do
        # Create database backup and compress using gzip.
        docker exec -i mysql bash <<EOF
        mkdir -p $backups_dir
        rm -rf backups_dir*
        mysqldump -u $db_user -h $db_host -P $db_port --password=$db_pass $db_name | gzip -9 > $backups_dir$db_name.sql.gz
        exit
EOF
done

# 导出所有数据库
docker exec -i mysql bash <<EOF
        mysqldump -u $db_user -h $db_host -P $db_port --password=$db_pass --all-databases | gzip -9 > $backups_dir'all.sql.gz'
        exit
EOF

# /mnt/mysql/volume/backup
mkdir -p $volume_dir$(date +%Y%m%d)
rm -rf $volume_dir$(date +%Y%m%d)/*
docker cp mysql:$backups_dir $volume_dir$(date +%Y%m%d)
cp -rf $volume_dir$(date +%Y%m%d)/backup/*  $volume_dir$(date +%Y%m%d)
rm -rf $volume_dir$(date +%Y%m%d)/backup
rm -rf $volume_dir$(date +"%Y%m%d" -d "-1month")

# /backup
mkdir -p /backup/mysql
rm -rf /backup/mysql/*
cp -rf $volume_dir/../* /backup/mysql

# Log
echo $(date "+%Y-%m-%d___%H:%M:%S")
echo '删除文件夹: '$volume_dir$(date +"%Y%m%d" -d "-1month");
echo '备份成功: '$volume_dir$(date +"%Y%m%d");
echo -e "------------------------------------------------\n"

# Set appropriate file permissions/owner.
chown -R $backups_user:$backups_user $volume_dir
chown -R $backups_user:$backups_user /backup
# chmod 0400 $backups_dir*--$datetime.sql


# 解压 gzip -dr all.sql.gz
# https://man.linuxde.net/gzip

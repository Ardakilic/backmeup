#!/usr/bin/env bash

#Add paths for the script to work better on cron
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

echo '-------------------------------------------------'
echo "  ____             _    __  __      _    _       "
echo " |  _ \           | |  |  \/  |    | |  | |      "
echo " | |_) | __ _  ___| | _| \  / | ___| |  | |_ __  "
echo " |  _ < / _, |/ __| |/ / |\/| |/ _ \ |  | | '_ \ "
echo " | |_) | (_| | (__|   <| |  | |  __/ |__| | |_) |"
echo " |____/ \__,_|\___|_|\_\_|  |_|\___|\____/| .__/ "
echo "                                          | |    "
echo "                                          |_|    "
echo '-------------------------------------------------'
echo ''
echo '-------------------------------------------------'
echo '| Author: Arda Kilicdagi'
echo '| https://github.com/Ardakilic/backmeup/'
echo '-------------------------------------------------'
echo ''



########################################################
# DO NOT EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!
########################################################

# Configuration parameters
# If no configuration file is found, let's download and create one.
if [[ ! -f "$HOME/.backmeuprc" ]];
then
    curl -s https://raw.githubusercontent.com/Ardakilic/backmeup/master/.backmeuprc -o $HOME/.backmeuprc
    chmod 400 $HOME/.backmeuprc # This file must have least permissions as possible.
fi

# Let's Source the configuration file
source $HOME/.backmeuprc

# Check the shell
if [[ -z "$BASH_VERSION" ]];
then
    echo -e "Error: this script requires the BASH shell!"
    exit 1
fi

# Let's get arguments and overwrite config if required
while [[ $# > 1 ]]
do
key="$1"

case $key in
    -tz|--timezone)
    TIMEZONE="$2"
    shift # past argument
    ;;
    -dbh|--database-host)
    DBHOST="$2"
    shift # past argument
    ;;
    -dbu|--database-user)
    DBUSER="$2"
    shift # past argument
    ;;
    -dbpass|--database-password)
    DBPASSWORD="$2"
    shift # past argument
    ;;
    -dbp|--database-port)
    DBPORT="$2"
    shift # past argument
    ;;
    -f|--files-root)
    FILESROOT="$2"
    shift # past argument
    ;;
    -b|--base-folder)
    BASEFOLDER="$2"
    shift # past argument
    ;;
    -bf|--backup-folder)
    BACKUPFOLDER="$2"
    shift # past argument
    ;;
    -m|--method)
    METHOD="$2"
    shift # past argument
    ;;
    -c|--compression)
    COMPRESSION="$2"
    shift # past argument
    ;;
    -7zcp|--7-zip-compression-password)
    SEVENZIP_COMPRESSION_PASSWORD="$2"
    shift # past argument
    ;;
    -gdrv|--gdrive-remote)
    RCLONE_REMOTE="$2"
    shift # past argument
    ;;
    -s3bn|--s3-bucket-name)
    S3_BUCKET_NAME="$2"
    shift # past argument
    ;;
    -s3sc|--s3-storage-class)
    S3_STORAGE_CLASS="$2"
    shift # past argument
    ;;
    -wdu|--webdav-user)
    WEBDAV_USER="$2"
    shift # past argument
    ;;
    -wdp|--webdav-password)
    WEBDAV_PASSWORD="$2"
    shift # past argument
    ;;
    -webdav|--webdav)
    WEBDAV_ENDPOINT="$2"
    shift # past argument
    ;;
esac
shift # past argument or value
done
# END Arguments

# Cleanup Function
function cleanup {
    rm -rf $1/backmeup* #Database dump folder for the time being
}

# Needed for file and folder names
THEDATE=`TZ=$TIMEZONE date +%Y-%m-%d_%H.%M.%S`

INSTALLABLE="yes"
ERRORMSGS=()
if ! [[ -x "$(command -v curl)" ]];
then
    INSTALLABLE="nope"
    ERRORMSGS+=('| You must install curl to run this script')
fi

if [[ "$COMPRESSION" == "tar" ]];
then
    if ! [[ -x "$(command -v tar)" ]];
    then
        INSTALLABLE="nope"
        ERRORMSGS+=('| You must install tar to run this script if compression is set as tar')
    fi
fi
if [[ "$COMPRESSION" == "7zip" ]];
then
    if ! [[ -x "$(command -v 7z)" ]];
    then
        INSTALLABLE="nope"
        ERRORMSGS+=('| You must install 7z to run this script if compression is set as 7-zip')
    fi
fi
if ! [[ -x "$(command -v mysql)" ]];
then
    INSTALLABLE="nope"
    ERRORMSGS+=('| You must install mysql to run this script')
fi
if ! [[ -x "$(command -v mysqldump)" ]];
then
    INSTALLABLE="nope"
    ERRORMSGS+=('| You must install mysqldump to run this script')
fi
if [[ "$METHOD" == "s3" ]];
then
    if ! [[ -x "$(command -v aws)" ]];
        then
        INSTALLABLE="nope"
        ERRORMSGS+=('| You must install aws cli to run this script to upload backups to Amazon S3')
    fi
fi

if [[ "$METHOD" == "mega" ]];
then
    if ! [[ -x "$(command -v mega-put)" ]];
        then
        INSTALLABLE="nope"
        ERRORMSGS+=('| You must install MegaCMD cli to run this script to upload backups to Mega.nz')
    fi
fi

if [[ "$METHOD" == "gdrive" ]];
then
    if ! [[ -x "$(command -v rclone)" ]];
        then
        INSTALLABLE="nope"
        ERRORMSGS+=('| You must install rclone cli to run this script to upload backups to Google Drive')
    fi
fi


# Let's check whether the script is installable
if [[ "$INSTALLABLE" == "yes" ]];
then
    
    # pre-cleanup
    cleanup $BASEFOLDER
    # folder for new backup
    SQLFOLDER=backmeup-databases-$THEDATE
    SQLFOLDERFULL="$BASEFOLDER/db/$SQLFOLDER"
    mkdir "$BASEFOLDER/db/" > /dev>null # to ensure the subfolder exists
    mkdir $SQLFOLDERFULL

    # First, let's create the backup file regardless of the provider:
    echo '|'
    echo '| Dumping Databases...'
    echo '|'
    # Let's start dumping the databases
    databases=$(mysql -h$DBHOST -u"$DBUSER" -p"$DBPASSWORD" -P"$DBPORT" -e "SHOW DATABASES;" | tr -d "| " | grep -v Database)
    for db in $databases; do
        if [[ "$db" != "information_schema" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != "mysql" ]] && [[ "$db" != _* ]];
        then
            echo "| Dumping database: $db"
            mysqldump -h"$DBHOST" -u"$DBUSER" -p"$DBPASSWORD" -P"$DBPORT" $db > $SQLFOLDERFULL/$THEDATE.$db.sql
        fi
    done
    echo '|'
    echo '| Done!'
    echo '|'

    # Now let's create the backup file and compress
    echo '| Now compressing the backup...'

    if [[ "$COMPRESSION" == "tar" ]];
    then
        FILENAME="backmeup-$THEDATE.tar.gz"
        tar -zcf "$BASEFOLDER/$FILENAME" -C "$FILESROOT" . -C "$SQLFOLDERFULL/" > /dev/null
    elif [[ "$COMPRESSION" == "7zip" ]];
    then
        FILENAME="backmeup-$THEDATE.7z"
        if [[ "$SEVENZIP_COMPRESSION_PASSWORD" != "" ]];
        then
            # https://askubuntu.com/a/928301/107722
            7z a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -mhe=on -p"$SEVENZIP_COMPRESSION_PASSWORD" "$BASEFOLDER/$FILENAME" "$FILESROOT" "$SQLFOLDERFULL" > /dev/null
        else
            7z a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on "$BASEFOLDER/$FILENAME" "$FILESROOT" "$SQLFOLDERFULL" > /dev/null
        fi
    fi

    echo '|'
    echo "| Done! The backup's name is: $FILENAME"
    echo '|'
    # Create backup END

    # If uploading method is set as Dropbox
    if [[ "$METHOD" == "dropbox" ]];
        then
        # Now let's fetch Dropbox Uploader
        # https://github.com/andreafabrizi/Dropbox-Uploader
        # to make sure it's always the newest version, first let's delete and fetch it
        # cd $HOME # not needed
        echo '| Fetching the newest Dropbox-Uploader from repository...'
        rm -rf /usr/local/bin/dropbox_uploader
        curl -s https://raw.githubusercontent.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.sh -o /usr/local/bin/dropbox_uploader
        echo '| Done!'
        echo '-------------------------------------------------'
        # make it executable
        chmod +x /usr/local/bin/dropbox_uploader

        # Is Dropbox-Uploader configured?
        if [[ ! -f "$HOME/.dropbox_uploader" ]];
        then
            echo '| You must configure the Dropbox first!'
            echo '| Please run dropbox_uploader as the user which will run this script and follow the instructions.'
            echo '| After that, re-run this script again'
        else
            # Now, let's upload to Dropbox:
            echo '| Creating the directory and uploading to Dropbox...'
            dropbox_uploader mkdir "$BACKUPFOLDER"
            dropbox_uploader upload "$BASEFOLDER/$FILENAME" "$BACKUPFOLDER"
            echo '|'
            echo '| Done!'
            echo '|'
        fi
    elif [[ "$METHOD" == "s3" ]];
    then
        # If uploading method is set to AWS S3
        echo '| Creating the directory and uploading to Amazon S3...'
        aws s3 cp --storage-class $S3_STORAGE_CLASS $FILENAME s3://$S3_BUCKET_NAME/$BACKUPFOLDER/ 
        echo '|'
        echo '| Done!'
        echo '|'
    elif [[ "$METHOD" == "mega" ]];
    then
        # If uploading method is set to Mega
        echo '| Creating the directory and uploading to Mega.nz...'
        aws mega-put $FILENAME /$BACKUPFOLDER/ -c
        echo '|'
        echo '| Done!'
        echo '|'
    fi

    # If uploading method is set to OwnCloud
    if [[ "$METHOD" == "webdav" ]];
    then
        # https://doc.owncloud.org/server/9.0/user_manual/files/access_webdav.html#accessing-files-using-curl
        echo '| Creating the directory and uploading to Owncloud...'
        curl -u "$WEBDAV_USER":"$WEBDAV_PASSWORD" -X MKCOL "$WEBDAV_ENDPOINT$BACKUPFOLDER"
        curl -u "$WEBDAV_USER":"$WEBDAV_PASSWORD" -X PUT -T "$BASEFOLDER/$FILENAME" "$WEBDAV_ENDPOINT$BACKUPFOLDER/$FILENAME"
        echo '|'
        echo '| Done!'
        echo '|'
    fi

    # If uploading method is set to Google Drive
    if [[ "$METHOD" == "gdrive" ]];
    then
        if [[ ! -f "$HOME/.config/rclone/rclone.conf" ]];
        then
            echo '| You must configure the rclone first!'
            echo '| Please run rclone config as the user which will run this script and follow the instructions.'
            echo '| After that, re-run this script again'
        fi
        # https://rclone.org/drive/
        echo '| Creating the directory and uploading to Google Drive...'
        rclone mkdir "$RCLONE_REMOTE$BACKUPFOLDER"
        rclone copy "$BASEFOLDER/$FILENAME" "$RCLONE_REMOTE$BACKUPFOLDER/$FILENAME"
        echo '|'
        echo '| Done!'
        echo '|'
    fi

    echo '| Cleaning up...'
    # Now let's cleanup
    rm -r $FILENAME
    cleanup $BASEFOLDER
    echo '|'
    echo "| Done! You should now see your backup '$FILENAME' inside the '$BACKUPFOLDER' in your Backup Solution"

else
    echo '| ERROR:'
    for i in "${ERRORMSGS[@]}"
        do
           echo $i
        done
fi

echo '-------------------------------------------------'

# Let's clean up just in case
cleanup $BASEFOLDER

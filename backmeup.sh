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
if [ ! -f $HOME/.backmeuprc ];
    then
    curl -s https://raw.githubusercontent.com/Ardakilic/backmeup/master/.backmeuprc -o $HOME/.backmeuprc
    chmod 400 $HOME/.backmeuprc # This file must have least permissions as possible.
fi

# Let's Source the configuration file
source $HOME/.backmeuprc

# Check the shell
if [ -z "$BASH_VERSION" ]; then
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
    -dbu|--database-user)
    DBUSER="$2"
    shift # past argument
    ;;
    -dbpass|--database-password)
    DBPASSWORD="$2"
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
    -s3bn|--s3-bucket-name)
    S3_BUCKET_NAME="$2"
    shift # past argument
    ;;
    -s3sc|--s3-storage-class)
    S3_STORAGE_CLASS="$2"
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
if ! which curl > /dev/null;
    then
    INSTALLABLE="nope"
    ERRORMSGS+=('| You must install curl to run this script')
fi
if ! which tar > /dev/null;
    then
    INSTALLABLE="nope"
    ERRORMSGS+=('| You must install tar to run this script')
fi
if ! which mysql > /dev/null;
    then
    INSTALLABLE="nope"
    ERRORMSGS+=('| You must install mysql to run this script')
fi
if ! which mysqldump > /dev/null;
    then
    INSTALLABLE="nope"
    ERRORMSGS+=('| You must install mysqldump to run this script')
fi
if [[ "$METHOD" == "s3" ]]
    then
    if ! which aws > /dev/null;
        then
        INSTALLABLE="nope"
        ERRORMSGS+=('| You must install aws cli to run this script to upload backups to Amazon S3')
    fi
fi


# Let's check whether the script is installable
if [[ "$INSTALLABLE" == "yes" ]]
then
    
    # pre-cleanup
    cleanup $BASEFOLDER
    # folder for new backup
    SQLFOLDER=backmeup-databases-$THEDATE
    SQLFOLDERFULL=$BASEFOLDER/$SQLFOLDER
    mkdir $SQLFOLDERFULL

    # First, let's create the backup file regardless of the provider:
    echo '|'
    echo '| Dumping Databases...'
    echo '|'
    # Let's start dumping the databases
    databases=`mysql --user=$DBUSER -p$DBPASSWORD -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`
    for db in $databases; do
        if [[ "$db" != "information_schema" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != "mysql" ]] && [[ "$db" != _* ]] ; then
            echo "| Dumping database: $db"
            mysqldump -u$DBUSER -p$DBPASSWORD $db > $SQLFOLDERFULL/$THEDATE.$db.sql
        fi
    done
    echo '|'
    echo '| Done!'
    echo '|'

    # Now let's compress
    FILENAME="backmeup-$THEDATE.tar.gz"
    echo '| Now compressing the backup...'
    tar -zcf $FILENAME -C $FILESROOT . -C $BASEFOLDER $SQLFOLDER/ > /dev/null
    echo '|'
    echo "| Done! The backup's name is: $FILENAME"
    echo '|'
    # Create backup END

    # If uploading method is set as Dropbox
    if [[ "$METHOD" == "dropbox" ]]
        then
        # Now let's fetch Dropbox Uploader
        # https://github.com/andreafabrizi/Dropbox-Uploader
        # to make sure it's always the newest version, first let's delete and fetch it
        cd $HOME
        echo '| Fetching the newest Dropbox-Uploader from repository...'
        rm -rf /usr/local/bin/dropbox_uploader
        curl -s https://raw.githubusercontent.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.sh -o /usr/local/bin/dropbox_uploader
        echo '| Done!'
        echo '-------------------------------------------------'
        # make it executable
        chmod +x /usr/local/bin/dropbox_uploader

        # Is Dropbox-Uploader configured?
        if [ ! -f $HOME/.dropbox_uploader ];
            then
            echo '| You must configure the Dropbox first!'
            echo '| Please run dropbox_uploader as the user which will run this script and follow the instructions.'
            echo '| After that, re-run this script again'
        else
            # Now, let's upload to Dropbox:
            echo '| Creating the directory and uploading to Dropbox...'
            dropbox_uploader mkdir $BACKUPFOLDER
            dropbox_uploader upload $FILENAME $BACKUPFOLDER
            echo '|'
            echo '| Done!'
            echo '|'
        fi
    fi

    # If uploading method is set to AWS S3
    if [[ "$METHOD" == "s3" ]]
        then
        echo '| Creating the directory and uploading to Amazon S3...'
        aws s3 cp --storage-class $S3_STORAGE_CLASS $FILENAME s3://$S3_BUCKET_NAME/$BACKUPFOLDER/ 
        echo '|'
        echo '| Done!'
        echo '|'
    fi

    echo '| Cleaning up..'
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

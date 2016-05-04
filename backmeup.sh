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
echo '| https://github.com/ardakilic/backmeup/'
echo '-------------------------------------------------'
echo ''


#CONFIGURATION PARAMETERS
TIMEZONE="Europe/Istanbul" #Your timezone, for a better timestamp in archived filenames
DBUSER="root" #MySQL user that can dump all databases
DBPASSWORD="" #MySQL password
FILESROOT="/var/www" #root of your (virtual) hosting files, E.g: For apache, it is /var/www, for nginx, it's /usr/share/nginx/html "WITHOUT THE END TRAILING SLASH"
BASEFOLDER="/tmp" #Temporary folder to create database dump folder (a subfolder will be created to this folder upon dumping)
DROPBOXFOLDER="backmeup" #your backup folder that'll be created on Dropbox

########################################################
# DO NOT EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!
########################################################

#Cleanup Function
function cleanup {
    rm -rf $1/$DROPBOXFOLDER*
}

#rm "$OUTPUTDIR/*gz" > /dev/null 2>&1

#needed for file and folder names
THEDATE=`TZ=$TIMEZONE date +%Y-%m-%d_%H.%M.%S`

INSTALLABLE="yes"
DROPBOX_CONFIGURED="yes"
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



if [[ "$INSTALLABLE" == "yes" ]]
then
    
    #pre-cleanup
    cleanup $BASEFOLDER
    #folder for new backup
    SQLFOLDER=backmeup-databases-$THEDATE
    SQLFOLDERFULL=$BASEFOLDER/$SQLFOLDER
    mkdir $SQLFOLDERFULL

    #Now let's fetch Dropbox Uploader
    #https://github.com/andreafabrizi/Dropbox-Uploader
    #to make sure it's always the newest version, first let's delete and fetch it
    cd $HOME
    echo '| Fetching the newest Dropbox-Uploader from repository...'
    rm -rf dropbox_uploader.sh
    curl -s https://raw.githubusercontent.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.sh -o dropbox_uploader.sh
    echo '| Done!'
    echo '-------------------------------------------------'
    #make it executable
    chmod +x dropbox_uploader.sh

    #Is Dropbox-Uploader configured?
    if [ ! -f $HOME/.dropbox_uploader ]; 
        then
        echo '| You must configure the Dropbox first!'
        echo '| Please run ./dropbox_uploader.sh and follow the instructions.'
        echo '| After that, re-run this script'
    else
        #everything okay, now let's start dumping
        echo '| Dumping Databases...'
        echo '|'
        #Let's start dumping the databases
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

        #Now let's compress
        FILENAME="backmeup-$THEDATE.tar.gz"
        echo '| Now compressing the backup...'
        tar -zcvf $FILENAME -C $FILESROOT . -C $BASEFOLDER $SQLFOLDER/ > /dev/null
        echo '|'
        echo "| Done! The backup's name is: $FILENAME"
        echo '|'

        #Now, let's upload to Dropbox:
        echo '| Creating the directory and uploading to Dropbox...'
        ./dropbox_uploader.sh mkdir $DROPBOXFOLDER
        ./dropbox_uploader.sh upload $FILENAME $DROPBOXFOLDER
        echo '|'
        echo '| Done!'
        echo '|'

        echo '| Cleaning up..'
        #Now let's cleanup
        rm -r $FILENAME
        cleanup $BASEFOLDER
        echo '|'
        echo "| Done! You should now see your backup '$FILENAME' inside the '$DROPBOXFOLDER' in your Dropbox"

    fi

else
    echo '| ERROR:'
    for i in "${ERRORMSGS[@]}"
        do
           echo $i
        done
fi

echo '-------------------------------------------------'

#Let's clean up just in case
cleanup $BASEFOLDER

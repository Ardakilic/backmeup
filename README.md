BackMeUp
=========

BackMeUp is an automated MySQL databases and files backup solution on Linux Machines using Dropbox as remote service.


```
  ____             _    __  __      _    _       
 |  _ \           | |  |  \/  |    | |  | |      
 | |_) | __ _  ___| | _| \  / | ___| |  | |_ __  
 |  _ < / _, |/ __| |/ / |\/| |/ _ \ |  | | '_ \ 
 | |_) | (_| | (__|   <| |  | |  __/ |__| | |_) |
 |____/ \__,_|\___|_|\_\_|  |_|\___|\____/| .__/ 
                                          | |    
                                          |_|    
```

Why?
--------------
I'm managing my own server, and I wanted to have a simple and easy tool to backup my database and all VirtualHost files, and to save them into a remote server with cron.

What This Script Does
--------------
This script does some simple tasks:
* The script dumps all of your MySQL databases individually.
* The script backs up all of your Web files (e.g: root of all of your virtual hosts).
* The script compresses your web-root and databases to a single archive.
* The script uploads the compressed archive into a folder in your Dropbox or Amazon S3 account.
* If the provider is Dropbox, The script makes sure that you always have the newest Dropbox-uploader script.
* After the upload, the script cleans the temporary files (dumps, the archive itself).

You may easily add this script to your crontab, and just forget about it :smile:


Requirements
--------------
* `curl` - To download the dropbox-uploader script and to upload the backup to Dropbox.
* `mysql-cli` - To list databases.
* `mysqldump` - To dump databases (in most cases, it comes with `mysql-cli`).
* [aws-cli](https://github.com/aws/aws-cli) must be installed and configured if the service is set as `aws`


Don't Have a Dropbox Account?
--------------
Don't worry :)

Just click on [this link](https://db.tt/A4QRGuD) to start Dropbox with a bonus space. With my referral, we both earn bonus space.


Configuration Values
--------------
After downloading the script, before running, you must edit your configuration values:

```sh
TIMEZONE="Europe/Istanbul" #Your timezone, for a better timestamp in archived filenames
DBUSER="root" #MySQL user that can dump all databases
DBPASSWORD="" #MySQL password
FILESROOT="/var/www" #root of your (virtual) hosting files, E.g: For apache, it is /var/www, for nginx, it's /usr/share/nginx/html "WITHOUT THE END TRAILING SLASH"
BASEFOLDER="/tmp" #Temporary folder to create database dump folder (a subfolder will be created to this folder upon dumping)
BACKUPFOLDER="backmeup" #your backup folder that'll be created on Backup provider
METHOD="dropbox" #Method name, can be "dropbox" or "s3". More providers soon
S3_BUCKET_NAME="my-aws-bucket" #AWS S3 Bucket name
```

On-the-fly Configuration
--------------
You can set various configuration values on the fly. Here are some full featured examples:

```
backmeup -tz "Europe/Istanbul" -dbu root -dbpass rootpass -f "/usr/share/nginx/html" -b "/tmp" -bf=my_backups -m s3 -s3bn my-aws-bucket
```

Or like this:

````
backmeup --timezone="Europe/Istanbul" --database-user="root" --database-password="rootpass" --files-root="/usr/share/nginx/html" --base-folder="/tmp" --backup-folder=my-remote-backup-folder
```

None of these are mandatory, you can just use any of these however you want, and even mix together!

Installation
--------------

* Run this command first:

  ```
  curl https://raw.githubusercontent.com/Ardakilic/backmeup/master/backmeup.sh -O backmeup.sh
  ```
* Now, edit the configuration values as stated [here](#configuration-values)
* Make the file executable and only accessible by your root user and group (or the user you'd like the script to run):

  ```
  chown root:root backmeup.sh #or any user and group who will run the script
  chmod +x backmeup.sh
  ```
* (Suggested) Copy or move the script into one of the `PATH`s as stated [here](#additional-notes)

Usage
--------------

* Execute the configured script:

  ```
  ./backmeup.sh
  ```
* If this is the first attempt to running and `method` is set to `dropbox`, Dropbox-Uploader will ask for an APP key and secret. You should create an appliction, provide these values and click on provided authorization link (Don't worry, the Dropbox-uploader has a nice wizard which guides you, can't be easier). After you've authorized, re-run the script using `.backmeup.sh`
* If everything went well, in a couple of minutes, you should see your database and files copied into the remote server.

Important Notice
--------------
This script saves MySQL Root password inside, but it's only accessible by root. In any ways, use it at your own risk. I'm not holding any responsibilities for any damage that this script may do (which shouldn't).

Additional Notes
--------------
* You can also copy the script to one of your PATHS, such as `/usr/local/bin/backmeup` and run from there directly. **This is suggested**

Screenshots
--------------
![](https://i.imgur.com/CimiNjc.png)


Special Thanks
--------------
[@andreafabrizi](https://github.com/andreafabrizi/) for maintaining the [Dropbox-Uploader](https://github.com/andreafabrizi/Dropbox-Uploader) script.

TODOs
--------------
* Tests on CentOS, Arch etc.
* Mega.nz integration
* ~~~Copy.com integration~~~
* ~~~AWS S3 integration~~~
* Increased security?
* Read configuration from an external file

Version History
--------------
###1.0.0
* Amazon S3 support (using official [aws-cli](https://github.com/aws/aws-cli))
* The code is optimised to use in cron
* Arguments and options support. You can pass the arguments and options to the script on-the-fly
###0.1.1
* Defined PATHs to the script so that it should work better on cron withot needing to define before running.
###0.1.0
* Initial Release

License
--------------

MIT
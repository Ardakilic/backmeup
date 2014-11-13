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
* The script dumps all of your MySQL databases as separate files.
* The script backs up all of your Web files (e.g: root of all of your virtual hosts).
* The script compresses your web-root and databases to a single archive.
* The script uploads the compressed archive into a folder in Dropbox.
* After the upload, the script cleans the temporary files (dumps, the archive itself). 
* The script makes sure that you always have the newest Dropbox-uploader script.

You may easily add this script to your crontab, and just forget about it :smile:

Version
--------------

0.1

Requirements
--------------
* `curl` - To download the dropbox-uploader script and to upload the backup to Dropbox.
* `mysql-cli` - To list databases.
* `mysqldump` - To dump databases (in most cases, it comes with `mysql-cli`).


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
FILESROOT="/var/www" #root of your (virtual) hosting files, E.g: For apache, it is /var/www, for nginx, it's /usr/share/nginx/html "WITHOUT TRAILING SLASH"
BASEFOLDER="/tmp" #Temporary folder to create database dump folder
DROPBOXFOLDER="backmeup" #your backup folder that'll be created on Dropbox
```

Installation
--------------

* Run this command first:

  ```
  curl https://raw.githubusercontent.com/Ardakilic/backmeup/master/backmeup.sh -O backmeup.sh
  ```
* Now, edit the configuration values as stated [here](#configuration-values)
* Make the file executable and only accessible by root:

  ```
  chown root:root backmeup.sh
  chmod 700 backmeup.sh
  ```

Usage
--------------

* Execute the configured script:

  ```
  ./backmeup.sh
  ```
* If this is the first attempt to running, Dropbox-Uploader will ask for an APP key and secret. You should create an appliction, provide these values and click on provided authorization link (Don't worry, the Dropbox-uploader has a nice wizard which guides you, can't be easier). After you've authorized, re-run the script using `.backmeup.sh`
* If everything went well, in a couple of minutes, you should see your database dumped into the 

Important Notice
--------------
This script saves MySQL Root password inside, but it's only accessible by root. In any ways, use it at your own risk. I'm not holding any responsibilities for any damage that this script may do (which shouldn't).

Special Thanks
--------------
[@andreafabrizi](https://github.com/andreafabrizi/) for maintaining the [Dropbox-Uploader](https://github.com/andreafabrizi/Dropbox-Uploader) script.

TODO
--------------
* Tests on CentOS, Arch etc.
* Copy.com integration
* Increased security?

License
--------------

MIT

BackMeUp
=========

BackMeUp is an automated MySQL databases and files backup solution on Linux Machines using Amazon S3, Dropbox, Mega.nz and WebDAV (NextCloud etc.) as remote storage.


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
I'm managing my own server, and I wanted to have a simple and easy tool to backup my database and all VirtualHost files, and to save them into a remote server with cronjob.

What This Script Does
--------------
This script does some simple tasks:
* The script dumps all of your MySQL databases individually.
* The script backs up all of your Web files (e.g: root path of all of your virtual hosts).
* The script compresses your web-root and databases to a single archive.
* The script uploads the compressed archive into a folder in your Dropbox account, Amazon S3 bucket, Mega.nz or to a WebDav solution such as OrnCloud/NextCloud Server.
* If the `method` is set to `dropbox`, The script makes sure that you always have the newest Dropbox-Uploader script.
* After the upload, the script cleans up the temporary files (dumps, the archive itself).

You may easily add this script to your crontab, and just forget about it :smile:


Requirements
--------------
* `curl` - To download the .backmeuprc file, Dropbox-uploader script and to upload the backup to Dropbox or to WebDAV.
* `mysql` (cli) - To list databases.
* `7z` (cli) - To list compress backup if `compression` is set as 7zip, or `tar` (cli) if `compression` is set as `tar`.
* `mysqldump` - To dump databases (in most cases, it comes with `mysql` cli).
* [aws-cli](https://github.com/aws/aws-cli) must be installed and configured if the `method` is set as `s3`.
* [mega-cmd](https://mega.nz/cmd) (the `mega-put` command is used that comes with the package) must be installed and configured if the `method` is set as `mega`.

Installation
--------------

* Run these commands first:

  ```bash
  curl -s https://raw.githubusercontent.com/Ardakilic/backmeup/master/backmeup.sh -o backmeup.sh
  curl -s https://raw.githubusercontent.com/Ardakilic/backmeup/master/.backmeuprc -o ~/.backmeuprc
  chmod 600 ~/.backmeuprc
  ```
* Now, edit the configuration values as stated [here](#configuration-values).
* Make the files secure, executable and only accessible by your root user and group (or the user you'd like the script to run):

  ```bash
  chown root:root backmeup.sh #or any user and group who will run the script or with cron
  chown root:root ~/.backmeuprc #or any user and group who will run the script manually or with cron
  chmod 400 ~/.backmeuprc #Only readable by owner, and is read-only. To make it writable, change to 600 on demand
  chmod +x backmeup.sh
  ```
* (Suggested) Copy or move the script into one of the `PATH`s as stated [here](#additional-notes).


Configuration Values
--------------
After downloading the script, before running, you must edit your configuration values found in [~/.backmeuprc](./.backmeuprc).

On-the-fly Configuration
--------------
You can set various configuration values on the fly. Here are some full featured examples:

```bash
backmeup -tz "Europe/Istanbul" -dbh localhost -dbu root -dbpass "rootpass" -dbp 3306 -f "/usr/share/nginx/html" -b "/tmp" -bf=my_backups -c 7z -7zcp "p4ssw0rd" -m s3 -s3bn my-aws-bucket -wdu "webdav-user" -wdp "webdav-password" -webdav "https://nextcloud-host.com/remote.php/webdav/"
```

Or like this:

```bash
backmeup --timezone="Europe/Istanbul" --database-host="localhost" --database-user="root" --database-password="rootpass" --database-port="3306" --files-root="/usr/share/nginx/html" --base-folder="/tmp" --compression="7z" --7-zip-compression-password="p4ssw0rd" --backup-folder="my-remote-backup-folder" --webdav-user="webdav-user" --webdav-password="webdav-password" --webdav="https://nextcloud-host.com/remote.php/webdav/"
```

None of these are mandatory, you can just use any of these however you want, and even mix together!

Usage
--------------

* Execute the configured script:

  ```bash
  ./backmeup.sh #or "backmeup" directly if it's in your PATH.
  ```
* If this is the first attempt to running and `method` is set to `dropbox`, Dropbox-Uploader will ask for an APP key and secret. You should create an application, provide these values and click on provided authorization link (Don't worry, the Dropbox-uploader has a nice wizard which guides you, can't be easier). After you've authorized, re-run the script using `./backmeup.sh`
* If everything went well, in a couple of minutes, you should see your database and files copied into the remote server.

Important Notice
--------------
This script saves MySQL password (any user which can show and dump (all) databases will suffice actually) inside, but it's only accessible by its owner and cannot be read by anyone else. In any ways, use it at your own risk. I'm not holding any responsibilities for any damage that this script may do (which shouldn't).

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
* ~~WebDAV (Owncloud etc.) Integration~~
* ~~AWS S3 integration~~
* ~~Increased security? (backup is encrypted with a password now for 7zip archives)~~
* ~~Reading configuration from an external file~~
* Postgres support
* Option to dump only the database(s) or only Virtualhost files
* Multiple Virtualhost folder support

Version History
--------------

### 1.4.0

* Mega.nz integration implemented

### 1.3.0

* 7-zip archive support
* Encryption support for 7-zip archives.

### 1.2.0

* WebDAV (Owncloud etc.) Integration: You can now upload your backup files to your WebDAV server using WebDAV bridge and curl. You can refer to updated `.backmeuprc` and update if necessary.

### 1.1.0

* You can now define "Database Host" and "Database Port" parameters, so you may even get dumps from remote services such as Amazon RDS. `DBHOST` and `DBHOST` values should be added in `.backmeuprc`
* The version numbers will follow Semantic Versioning from now on.

### 1.0.1

* External configuration file support. Now you can update backmeup hassle-free! The file's located at: `~/.backmeuprc`
* Amazon S3 Storage Class Support: Now you can set how the backup will be stored ([Normal or Infrequent Access](https://aws.amazon.com/s3/storage-classes/) or [Reduced Redundancy](https://aws.amazon.com/s3/reduced-redundancy/) for lesser storage costs).
* An issue with Dropbox-uploader download path is fixed.

### 1.0.0

* Amazon S3 support (using official [aws-cli](https://github.com/aws/aws-cli))
* The code is optimised to use in cron
* Arguments and options support. You can pass the arguments and options to the script on-the-fly

### 0.1.1

* Defined PATHs to the script so that it should work better on cron withot needing to define before running.


### 0.1.0

* Initial Release

Buy me a coffee or beer!
--------

Donations are kindly accepted to help develop my projects further.

BTC: 1QFHeSrhWWVhmneDBkArKvpmPohRjpf7p6

ETH / ERC20 Tokens: 0x3C2b0AC49257300DaB96dF8b49d254Bb696B3458

NEO / Nep5 Tokens: AYbHEah5Y4J6BV8Y9wkWJY7cCyHQameaHc

License
--------------

MIT
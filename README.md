# RFLink-update
shell script to update RFLink

# Installation

You need to have Python 2.7 installed
On debian/ubuntu platform:

    apt-get install python python2.7
    
On Fedora/Centos platform:

    yum install python27 

On Windows platform:

 get latest msi file from https://www.python.org/downloads/release/python-2713/
 
Download latest version:

    wget https://github.com/roondar/RFLink-update/archive/master.zip
    unzip master.zip
    RFLink-update-master/
    cp settings.ini.tpml settings.ini
    chmod 755 update_RFLink.py

Edit settings.ini with your own variables

# How to schedule automatic update

 We'll use crond for this
 
     echo "0 12 * * * root /root/RFLink-update-master/update_RFLink.py" >> /etc/crontab

You can use this website to generate a crontab http://crontab-generator.org/

# Extra variables
you need need to install pip https://pip.pypa.io/en/stable/installing/

* If you want to have pushbullet notification

you can edit settings.ini and add your pushbullet api key

    pip install pushbullet.py

* If you are note sure about domoticz port

  
    pip install psutil
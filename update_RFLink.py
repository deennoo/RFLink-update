#!/usr/bin/python2
import ConfigParser
import hashlib
import json
import os
import shlex
import shutil
import subprocess
import sys
import urllib
import urllib2
import xml.etree.ElementTree as ET
from distutils import spawn


def find_domoticz_port():
    import psutil
    for pid in psutil.pids():
        p = psutil.Process(pid)
        if "domoticz" in p.name():
            args = p.cmdline()
            return args[args.index('-www')+1]


config = ConfigParser.ConfigParser()
current_dir = os.path.dirname(os.path.realpath(__file__))
config_file = os.path.join(current_dir, 'settings.ini')
config.readfp(open(config_file))

ip = config.get('general', 'ip')
if config.has_option('general', 'port'):
    port = config.get('general', 'port')
else:
    port = find_domoticz_port()

schema = config.get('general', 'schema')
dry_run = config.getboolean('general', 'dry_run')

if config.has_option('general', 'pushbullet_key'):
    pushbullet_key = config.get('general', 'pushbullet_key')
    from pushbullet import Pushbullet

    pushbullet = Pushbullet(pushbullet_key)

url = "%s://%s:%s/json.htm?" % (schema, ip, port)


def enable_harware(status=True):
    data = { 'type':'command',
            'param':'updatehardware',
            'htype':46,
            'port': serial_port,
            'extra': '',
            'name': name,
            'enabled': str(status).lower(),
            'idx': idx,
            'datatimeout': datatimeout,
            'Mode1':0,
            'Mode2':0,
            'Mode3':0,
            'Mode4':0,
            'Mode5':0,
            'Mode6':0, }
    urllib2.urlopen(url+urllib.urlencode(data))


def flash_device(serial_port, filename):
     avrdude =  spawn.find_executable('avrdude')
     if not avrdude:
         raise Exception('avrdude command not found')
         sys.exit(1)
     cmd = '%s -v -v -v -p atmega2560 -c wiring -D -P %s -b 115200 -U flash:w:%s:i' % ( avrdude, serial_port, filename)
     notify('Executing: %s' % cmd)
     if not dry_run:
         subprocess.check_call(shlex.split(cmd))


def get_data(parameters):
    response = urllib2.urlopen(url+parameters)
    data = json.load(response)
    if data.has_key("result"):
        return data['result']


def notify(text):
    print text
    urllib2.urlopen(
        url + "type=command&param=addlogmessage&message=" + urllib.quote("--- RFLINK UPDATE --- %s" % (text)))


for hardware in get_data("type=hardware"):
    if hardware.has_key('Type') and hardware['Type'] == 46:
        serial_port =  hardware['SerialPort']
        idx = hardware['idx']
        name = hardware['Name']
        version = hardware['version']
        datatimeout = hardware['DataTimeout']
        notify("Your %s hardware has idx %s in version %s on port %s" % (name, idx, version, serial_port))

if version == "":
    notify("Error when retrieving RFlink version")
version = "34"
root = ET.parse(urllib2.urlopen("http://www.nemcon.nl/blog2/fw/update.jsp?ver=1.1&rel=%s" % version.split('.')[0])).getroot()

value = root.findall('Value')[0].text
if value == "0":
    notify("You have the latest rflink version")
elif value == "":
    notify("Error when retrieving last rflink version")
else:
    notify("Download the latest rflink version")
    url_file = root.findall('Url')[0].text
    md5 = root.findall('MD5')[0].text
    filename = urllib.urlretrieve(url_file)
    if hashlib.md5(open(filename[0], 'rb').read()).hexdigest() == md5:
        shutil.copy(filename[0], "RFLink.cpp.hex")
        notify('Disabling RFLink Hardware')
        enable_harware(False)
        notify('Flashing RFLink Hardware')
        try:
            flash_device(serial_port, 'RFLink.cpp.hex')
            notify('Flashing was successful')
        except Exception as e:
            notify('ERROR: %s' % e)
        finally:
            notify('Enabling RFLink Hardware')
            enable_harware()
        os.unlink('RFLink.cpp.hex')

        notify('Update Done, Thanks using RFLink')
        if "pushbullet" in globals():
            pushbullet.push_note("Domoticz", "Upgrade DONE")
    else:
        notify("ERROR: MD5 checksum unmatched")
        sys.exit(1)
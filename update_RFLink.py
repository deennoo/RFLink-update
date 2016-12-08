#!/usr/bin/python2
import urllib2
import shlex, subprocess
import urllib
from distutils import spawn
import os
import sys
import json
import xml.etree.ElementTree as ET
import hashlib
import shutil
import platform


#ip="192.168.1.254"
ip="127.0.0.1"
default_port="8080"
schema="http"
dry_run = False
def find_domoticz_port():
    for pid in psutil.pids():
        p = psutil.Process(pid)
        if "domoticz" in p.name():
            args = p.cmdline()
            return args[args.index('-www')+1]
try:
    import psutil
    port = find_domoticz_port()
except Exception as e:
    port = default_port

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
     if platform.system() == 'Windows':
        cmd = '%s -v -v -v -p atmega2560 -c stk500v2 -D -P %s -b 115200 -U flash:w:%s:i' % ( avrdude, serial_port, filename)
     else:
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
  urllib2.urlopen(url+"type=command&param=addlogmessage&message="+urllib.quote("--- RFLINK UPDATE --- %s" % (text)))


for hardware in get_data("type=hardware"):
    if hardware.has_key('Type') and hardware['Type'] == 46:
        serial_port =  hardware['SerialPort']
        idx = hardware['idx']
        name = hardware['Name']
        version = hardware['version']
        datatimeout = hardware['DataTimeout']
        notify("Your %s hardware has idx %s in version %s on port %s" % (name, idx, version, serial_port))


if platform.system() == 'Windows':
    root = ET.parse(urllib2.urlopen("http://www.nemcon.nl/blog2/fw/dcz/update.jsp?ver=1.1&rel=%s" % version.split('.')[0])).getroot()
else:
    root = ET.parse(urllib2.urlopen("http://www.nemcon.nl/blog2/fw/update.jsp?ver=1.1&rel=%s" % version.split('.')[0])).getroot()

value = root.findall('Value')[0].text
if value == "0":
    notify("You have the lastest rflink version")
else:
    notify("Download the lastest rflink version")
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

        notify('Update Done, Thanks using RFLink')
    else:
        notify("ERROR: MD5 checksum unmatch")
        sys.exit(1)


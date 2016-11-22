#!/bin/bash
#
#this script have to update RFLInk FW
RED='\033[0;31m'
NC='\033[0m' # No Color
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# #WELCOME MESSAGE
curl -s 'http://127.0.0.1:8080/json.htm?type=command&param=addlogmessage&message=---%20RFLINK%20UPDATE%20---%20STARTING' > /dev/null
echo -e "${YELLOW}Welcome to RFLink Update Script${NC}"
# read ok
# echo -e "${YELLOW}OK Done ? Lets' GO !${NC}"

# #Create RFLink update dir on tmp
echo -e "${YELLOW}Create RFLink dir on /tmp${NC}"
sudo mkdir /tmp/RFLink &> /dev/null
curl -s 'http://127.0.0.1:8080/json.htm?type=command&param=addlogmessage&message=---%20RFLINK%20UPDATE%20---%20CREATE%20RFLINK%20DIR%20ON%20TMP'   > /dev/null

# #download last fw, and copy to /tmp/RFLink > /dev/null
echo -e "${YELLOW}DOWNLOADING LAST RFLINK FW${NC}"
curl -s 'http://127.0.0.1:8080/json.htm?type=command&param=addlogmessage&message=---%20RFLINK%20UPDATE%20---%20DOWNLOADING%20LAST%20RFLINK%20FW'  > /dev/null
cd /tmp/RFLink
sudo rm -f /tmp/RFLink/RFLink.cpp.hex
sudo wget http://www.nemcon.nl/blog2/fw/44/RFLink.cpp.hex &> /dev/null

# #check and install avrdude & jq, if avrdudue & jq are already here do nothing, if not install it
echo -e "${YELLOW}INSTALLING DEPENDENCIE${NC}"
sudo apt-get install avrdude -y  > /dev/null
sudo apt-get install jq -y  > /dev/null
curl -s 'http://127.0.0.1:8080/json.htm?type=command&param=addlogmessage&message=---%20RFLINK%20UPDATE%20---%20INSTALLING%20DEPENDENCY'  > /dev/null

#get RFLink IDX hardware
idx=$(curl -s http://127.0.0.1:8080/json.htm?type=hardware | jq '.result[] | select(.Type == 46)'| jq '.idx?')
IDX="${idx%\"}"
IDX="${IDX#\"}"
echo -e "${YELLOW}Your RFLink Hardware IDX is == ${NC}${RED}$IDX${NC}"

#get RFLink serial port
SerialPort=$(curl -s http://127.0.0.1:8080/json.htm?type=hardware | jq '.result[] | select(.Type == 46)'| jq '.SerialPort?')
SERIAL="${SerialPort%\"}"
SERIAL="${SERIAL#\"}"
echo -e "${YELLOW}Your RFLink Hardware serial port is == ${NC}${RED}$SERIAL${NC}"

#get RFLink hardwareName
Name=$(curl -s http://127.0.0.1:8080/json.htm?type=hardware | jq '.result[] | select(.Type == 46)'| jq '.Name?')
NAME="${Name%\"}"
NAME="${NAME#\"}"
echo -e "${YELLOW}Your RFLink Hardware Name is == ${NC}${RED}$NAME${NC}"

#get RFLink version
Version=$(curl -s http://127.0.0.1:8080/json.htm?type=hardware | jq '.result[] | select(.Type == 46)'| jq '.version?')
VERSION="${Version%\"}"
VERSION="${VERSION#\"}"
echo -e "${YELLOW}Your RFLink version is == ${NC}${RED}$VERSION${NC}"

#disable RFLink hardware
echo -e "${YELLOW}Disabling RFLink Hardware${NC}"
curl --silent -s -i -H  "Accept: application/json" "http://127.0.0.1:8080/json.htm?type=command&param=updatehardware&htype=46&port=$SERIAL&extra=&name=$NAME&enabled=false&idx=$IDX&datatimeout=0&Mode1=0&Mode2=0&Mode3=0&Mode4=0&Mode5=0&Mode6=0"  > /dev/null

#update rflink with last FW
echo -e "${YELLOW}UPDATING YOUR RFLINK ${NC}${RED} CAN TAKES TIME BE PATIENT PLEASE ${NC}"
sudo /usr/bin/avrdude -v -v -v -p atmega2560 -c wiring -D -P $SERIAL -b 115200 -U flash:w:/tmp/RFLink/RFLink.cpp.hex:i  &> /dev/null
curl -s 'http://127.0.0.1:8080/json.htm?type=command&param=addlogmessage&message=---%20RFLINK%20UPDATE%20---%20IN%20PROGRES%20---'  > /dev/null

#enable RFLink hardware
echo -e "${YELLOW}Enabling RFLink Hardware${NC}"
curl --silent -s -i -H  "Accept: application/json" "http://127.0.0.1:8080/json.htm?type=command&param=updatehardware&htype=46&port=$SERIAL&extra=&name=$NAME&enabled=true&idx=$IDX&datatimeout=0&Mode1=0&Mode2=0&Mode3=0&Mode4=0&Mode5=0&Mode6=0"  > /dev/null
curl -s 'http://127.0.0.1:8080/json.htm?type=command&param=addlogmessage&message=---%20RFLINK%20UPDATE%20---%20FINISHED%20---'  > /dev/null

#print thx to users and don't forget to reactivate RFLink on Domoticz
echo -e "${YELLOW}Update Done, Thanks using RFLink${NC}"

echo -e "${RED} _____    _____   _       _   __   _   _   _   ${NC}" 
echo -e "${RED}|  _  \  |  ___| | |     | | |  \ | | | | / /  ${NC}" 
echo -e "${RED}| |_| |  | |__   | |     | | |   \| | | |/ /   ${NC}" 
echo -e "${RED}|  _  /  |  __|  | |     | | | |\   | | |\ \   ${NC}"
echo -e "${RED}| | \ \  | |     | |___  | | | | \  | | | \ \  ${NC}"
echo -e "${RED}|_|  \_\ |_|     |_____| |_| |_|  \_| |_|  \_\ ${NC}"

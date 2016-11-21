#!/bin/bash
#
#this script have to update RFLInk FW
RED='\033[0;31m'
NC='\033[0m' # No Color
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#WELCOME MESSAGE
curl -s 'http://127.0.0.1:8080/json.htm?type=command&param=addlogmessage&message=---%20RFLINK%20UPDATE%20---%20STARTING' > /dev/null
echo -e "${YELLOW}Welcome to RFLink Update Script, please unactive RFLink on Domoticz Hardware Panel,${NC} ${RED}type ok + enter when done${NC}"
read ok
echo -e "${YELLOW}OK Done ? Lets' GO !${NC}"

#creatE RFLink update dir on tmp
echo -e "${YELLOW}Create RFLink dir on /tmp${NC}"
sudo mkdir /tmp/RFLink &> /dev/null
curl -s 'http://127.0.0.1:8080/json.htm?type=command&param=addlogmessage&message=---%20RFLINK%20UPDATE%20---%20CREATE%20RFLINK%20DIR%20ON%20TMP' > /dev/null

#download last fw, and copy to /tmp/RFLink
echo -e "${YELLOW}DOWNLOADING LAST RFLINK FW${NC}"
curl -s 'http://127.0.0.1:8080/json.htm?type=command&param=addlogmessage&message=---%20RFLINK%20UPDATE%20---%20DOWNLOADING%20LAST%20RFLINK%20FW' > /dev/null
cd /tmp/RFLink
sudo rm -f /tmp/RFLink/RFLink.cpp.hex
sudo wget http://www.nemcon.nl/blog2/fw/44/RFLink.cpp.hex &> /dev/null

#check and install avrdude, if avrdudue is already here do nothing, if not install it
echo -e "${YELLOW}INSTALLING DEPENDENCIE${NC}"
sudo apt-get install avrdude -y
curl -s 'http://127.0.0.1:8080/json.htm?type=command&param=addlogmessage&message=---%20RFLINK%20UPDATE%20---%20INSTALLING%20DEPENDENCY' > /dev/null

#ask to user which ttyusb is use for rflink or take it from domoticz db ?
echo -e "${YELLOW}Please add your RFLink adress ${NC}${RED}ex :  /dev/ttyUSB0 ? /!\ don't forget to unactive RFLink on Domoticz hardware panel${NC}"
read usbgateway
echo -e "${YELLOW}We will use ${RED}$usbgateway${NC}${YELLOW} as communication port${NC}"
curl -s 'http://127.0.0.1:8080/json.htm?type=command&param=addlogmessage&message=---%20RFLINK%20UPDATE%20---%20COMMUNICATION%20PORT%20SET' > /dev/null


#update rflink with last FW
echo -e "${YELLOW}UPDATING YOUR RFLINK ${NC}${RED} CAN TAKES TIME BE PATIENT PLEASE ${NC}"
sudo /usr/bin/avrdude -v -v -v -p atmega2560 -c wiring -D -P $usbgateway -b 115200 -U flash:w:/tmp/RFLink/RFLink.cpp.hex:i &> /dev/null
curl -s 'http://127.0.0.1:8080/json.htm?type=command&param=addlogmessage&message=---%20RFLINK%20UPDATE%20---%20FINISHED%20---%20PLEASE%20REACTIVATE%20YOUR%20RFLINK%20ON%20HARDWARE%20PANEL' > /dev/null

#print thx to users and don't forget to reactivate RFLink on Domoticz
echo -e "${YELLOW}Update Done, Thanks using RFLink${NC}"
echo -e "${YELLOW}Please Active your RFlink on Domoticz Hardware Panel${NC}"
echo -e "${RED} _____    _____   _       _   __   _   _   _   ${NC}" 
echo -e "${RED}|  _  \  |  ___| | |     | | |  \ | | | | / /  ${NC}" 
echo -e "${RED}| |_| |  | |__   | |     | | |   \| | | |/ /   ${NC}" 
echo -e "${RED}|  _  /  |  __|  | |     | | | |\   | | |\ \   ${NC}"
echo -e "${RED}| | \ \  | |     | |___  | | | | \  | | | \ \  ${NC}"
echo -e "${RED}|_|  \_\ |_|     |_____| |_| |_|  \_| |_|  \_\ ${NC}"

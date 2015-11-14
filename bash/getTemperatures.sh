#!/bin/bash

DATESTRING=`date`
TEMPSTRING=`sensors | grep temp1`
CORETEMP=${TEMPSTRING:13:7}
echo "$DATESTRING -- Temperatura del core:  " $CORETEMP ";"
TEMPSTRING=`/usr/sbin/hddtemp /dev/sda`
HDDTEMP=${TEMPSTRING:34:4}
echo "$DATESTRING -- Temperatura del disco: " $HDDTEMP ";" 
echo ""
exit 0

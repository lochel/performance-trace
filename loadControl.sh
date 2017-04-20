#!/bin/bash
# ******************************************************************
# * simTimeMSL                                                     *
# * ==========                                                     *
# * Called from "simTimeMSL.sh".                                   *
# * Script to control the server load.                             *
# * Loops until server is not busy anymore.                        *
# *                                                                *
# * author: ptaeuber                                               *
# ******************************************************************

# Parameters
loadAllowed=$1

echo Load Control activated!

load=`uptime | sed s/".*load average: \(.*\..*\), \(.*\..*\), \(.*\..*\)/\1/"`
toobusy=`echo "$load > $loadAllowed" | bc`

while [ $toobusy -eq 1 ]
  do
    echo The Server is too busy to simulate the model. Allowed load is $loadAllowed. Average load is $load.
    sleep 30
    load=`uptime | sed s/".*load average: \(.*\..*\), \(.*\..*\), \(.*\..*\)/\1/"`
    toobusy=`echo "$load > $loadAllowed" | bc`
done

echo "Now we can start!"

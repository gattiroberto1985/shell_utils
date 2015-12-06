#!/bin/bash

echo "Chiamo il setter di frequenza della CPU (setCPUFreq@sid)..."
cpufreq-set -c 0 -u 1100000
cpufreq-set -c 1 -u 1100000
echo "OK, entrambe le CPU al massimo a 1,10 GHZ... Consultare cpufreq-set"
exit 0


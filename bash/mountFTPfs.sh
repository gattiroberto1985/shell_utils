#!/bin/bash

FILEPW="/home/elbobehi/.user.info"
MOUNTDIR="/media/sitoBob"

# Controllo che il comando sia stato eseguito da root
if [[ $EUID -ne 0 ]]; then
 echo "ERRORE: script da eseguire come root!" 1>&2
 exit 1
fi
echo "Ok, script eseguito da utente root; controllo file di info..."

if [[ ! -e $FILEPW ]]; then
 echo "ERRORE: file di input inesistente. Controllare"
 echo "** il file deve contenere una singola riga in questo formato:"
 echo "** <user>:<password>"
 echo "**"
 exit 2
fi
read INFO < $FILEPW
echo "Ok, file user - pw trovato; controllo directory di mount..."

if [[ ! -d $MOUNTDIR ]]; then
 echo "ERRORE: directory di mount inesistente. Controllare"
 exit 3
fi
echo "Ok, directory esistente; controllo se disponibile per il mount..."
if [[ "$(ls -A $MOUNTDIR)" ]]; then
 echo "ERRORE: directory di mount non vuota. Controllare"
 exit 4
fi

echo "Ok, directory di mount esistente e disponibile per il mount. Ricerco binario..."
#ok, l'utente e' root; ricerco il binario di curlftpfs

IFS=$':'
for i in $PATH
do
 if [[ ! -e "$i/curlftpfs" ]]; then
  echo "Ok, curlftpfs trovato in $i"
  break
 fi
done

unset IFS
echo "Ok, tutto a posto! procedo con il mount..."
curlftpfs -o allow_other ftp://$INFO@bob85.altervista.org $MOUNTDIR

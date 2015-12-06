#!/bin/bash

SCRIPT_NAME="clean_dropbox.sh"
VERSION="0.1"
DROPBOX_HOME=""
MY_DEFAULT_DROPBOX_HOME="/mnt/storage/Documenti/Dropbox/"
TIMESTAMP=$(date +'%d%m%Y_%H%M%S')
TMPDIR="/tmp/$SCRIPT_NAME.$TIMESTAMP/"
TMPFILE="$TMPDIR/$SCRIPT_NAME.$TIMESTAMP.log"

# Metodo per il print di un messaggio di log
# Stampa un messaggio di log nella forma:
# timestamp @@ livello_warning @@ messaggio
function write_log
{
 MESSAGE="$1 @@ "
 if [[ $# -eq 3 ]]
 then 
  if [[ $3 -ne 0 ]]; then MESSAGE=$MESSAGE" |"; fi
  index=0
  indent_level=$3
  while [[ $index -lt $indent_level ]]
  do
   MESSAGE=$MESSAGE"--"
   index=$(($index +1))
  done
 fi
 MESSAGE=$MESSAGE" $2"
 echo -e "[$(date +'%d-%m-%Y %H:%M:%S')] @@ $MESSAGE"
}


############################### MAIN PROGRAM ##################################

write_log "I" "Inizializzazione script: $SCRIPT_NAME, versione $VERSION" 0

write_log "I" "Check parametri in input..." 1

if [[ $# -eq 1 ]]
then
 #read -p "argomenti in input = $# = 1 : $1"
 write_log "I" "Passato un parametro, setto la home della dropbox a: $1" 2
 DROPBOX_HOME=$1
 #read -p "path settato: $DROPBOX_HOME"
else
 write_log  "I" "Num. $# parametri -- Non considerati " 2
 #read -p "argomenti in input = $# > 1"
 DROPBOX_HOME=$MY_DEFAULT_VALUE
 #read -p "path settato: $DROPBOX_HOME"
fi

write_log "I" "Controllo l'esistenza del path..." 1

if [[ ! -d $DROPBOX_HOME ]]; then ( write_log "E" " *** ERRORE: path $DROPBOX_HOME non esistente! esco!" 2 && exit 1); fi

write_log "I" "Ok, parametri a posto. Home di dropbox settata alla cartella esistente $DROPBOX_HOME" 1

write_log "I" "Sposto la lista di file con conflitti dalla dropbox a $TMPDIR..." 1
if [[ ! -d $TMPDIR ]]; then (write_log "W" "Attenzione: creo cartella temporanea $TMPDIR" 2 && ( mkdir -p $TMPDIR 2>&1 || exit 1)); fi

write_log "I" " ********* INIZIO LISTA FILE ********* " 1

write_log "I" "\n$(find $DROPBOX_HOME -iname '*conflicted copy*' -o -iname '*copia in conflitto*' -type f)" 1

write_log "I" " ********* FINE LISTA FILE ********* " 1

find $DROPBOX_HOME -iname '*conflicted copy*' -o -iname '*copia in conflitto*' -type f -exec mv {} $TMPDIR \;
write_log "I" "File rimossi dalla dropbox, creo archivio e carico in /tmp su DropBox..." 1

if [[ ! -d $DROPBOX_HOME/tmp ]]; then ( write_log "I" "Attenzione: creo tmp su drobpox..." && mkdir $DROPBOX_HOME/tmp); fi
write_log "I" "Ok cartella temporanea sistemata, posso procedere..." 0
if [[ -z $(ls -A $TMPDIR) ]]
then
 write_log "I" "Directory vuota, nessun file trovato. " 1
else
 write_log "I" "Creazione archivio..." 1
 tar cvf $DROPBOX_HOME/tmp/conflicts.$TIMESTAMP.tar $TMPDIR 2>&1 
 cd $DROPBOX_HOME/tmp && ( gzip $DROPBOX_HOME/tmp/conflicts.$TIMESTAMP.tar 2>&1 || echo "gzip: rc a $?")
 write_log "I" "Rimuovo i temporanei..."
 rm -rf $TMPDIR
 write_log "I" "Ok, fatto tutto" 1
fi

write_log "I" "Esco... Ciao Ciao!" 0
exit 0
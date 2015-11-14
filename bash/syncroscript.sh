#!/bin/bash

### Lo script esegue la sincronizzazione dei dati tra due cartelle

#Controllo dei parametri di input
function checkInput
{
 if [[ ! -d $1 ]]; then
  echo "| ERRORE: directory di input $1 non esistente."
  exit 1
 else
  echo "| Ok, \"$1\" esistente..." 
 fi
 if [[ ! -d $2 ]]; then
  echo "| WARNING: directory di output $2 non esistente; Procedo con la creazione"
  mkdir $2
 else
  echo "| Ok, \"$2\" esistente..."
 fi
}

# Stampa l'help per l'utilizzo del comando
function print_help
{
 echo "Utilizzo: syncroscipt.sh IN_DIR OUT_DIR [-i FILE_SYSTEM_IN] "
 echo "                         [-o FILE_SYSTEM_OUT]"
}

# Controllo parametri
if (( $# < 2)); then
 echo "WARNING: numero argomenti non valido. Entro in modalita interattiva..."
else
 echo "- Controllo parametri..."
 checkInput $1 $2
fi
echo "Ok, parametri corretti. Procedo con la sincronizzazione..."
rsync -avri --no-perms $1 $2

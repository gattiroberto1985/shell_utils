#!/bin/bash

function welcome
{
 echo "                                                                      "
 echo "**********************************************************************"
 echo "****************     Script di ricerca programma     *****************"
 echo "----------------------------------------------------------------------"
}

function print_help
{
 echo "** Inserire il nome dei programmi da ricercare nella variabile PATH"
 echo "** ESEMPIO: findPathOfProgram.sh cp mv rmdir mkdir javac"
}

if [[ $# < 1 ]]
then
 echo "ERRORE: specificare almeno un programma!"
 print_help
 exit 1
fi

welcome

TMPIFS=$IFS
IFS=":"

PROGFOUND=0

for PROGRAM in $@
do
 for SUBPATH in $PATH
 do
  if [[ -f $SUBPATH/$PROGRAM ]]
  then
   echo "Programma $PROGRAM trovato in $SUBPATH;"
   echo "----------------------------------------------------------------------"
   PROGFOUND=1
   break
  fi 
 done
 if [[ $PROGFOUND = 0 ]]; then
  echo "Programma $PROGRAM non trovato nella variabile PATH;"
  echo "----------------------------------------------------------------------"
 else 
  PROGFOUND=0
 fi
done
echo ""
IFS=$TMPISF
exit 0


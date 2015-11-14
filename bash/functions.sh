###############################################################################
#                        UTILITIES PER SHELL SCRIPTING                        #
###############################################################################

###############################################################################
#                                  CHANGELOGS                                 #
#                                                                             #
# 2014.06.03 -- bob -- Inserita funzione breakpoint, per simulare un          #
#                      breakpoint durante l'applicazione                      #
###############################################################################
export LOG_NESTED_LEVEL=0
export DEFAULT_LOG_LEVEL="INFO"
export DEFAULT_TEMP_DIR="/tmp/bob/"
export DEBUG_FLAG=N
export SCRIPT_NAME=""




# Metodo per il logging degli script. Esempi di chiamate:
# log "I" "messaggio da loggare" 0 --> stampa [ <timestamp> ] @@ I @@ livello base
# log "I" "messaggio da loggare" 1 --> stampa [ <timestamp> ] @@ I @@ -- primo livello
# log "I" "messaggio da loggare" 2 --> stampa [ <timestamp> ] @@ I @@ ---- secondo livello
# log "I" "messaggio da loggare" 1 --> stampa [ <timestamp> ] @@ I @@ -- primo livello
function log
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






#  Esegue il logging dell'applicazione se il flag di debug e' attivo.
function dlog
{
    if [[ "$DEBUG_FLAG" == 'Y' ]]
    then
        log "$@"
    fi
}


function pipe_log
{
    while read line
    do
        log 'I' "$line" $1
    done
}


function dpipe_log
{
    while read line
    do
        dlog 'D' "$line" $1
    done
}

#####  La funzione simula un breakpoint in fase di esecuzione
##### (attiva solo in caso di debug abilitato)
function breakpoint
{
    [ "$DEBUG_FLAG" == "Y" ] && {
        dlog "$*" 
        read 
    }
}


# La funzione esce dallo script.
function my_exit
{
  myrc=$2
  message=$1
  log_level="I"
  [ $myrc -eq 0 ] || 
  {
    message="ERRORE: $message"
    log_level="E"
    log "$log_level" "$message" 0
    [ -n "$TMPDIR" ] && log "$log_level" "The temporary files are avaiable under $TMPDIR" 0
  }
  end_script $myrc
}



# Funzione di inizializzazione script.
function init_script
{
    log "I" "" 0
    log "I" "###############################################################################" 0
    log "I" " Initializing script $SCRIPT_NAME                                              " 0
    log "I" " ------------------------------------------------------------------------------" 0
    log "I" " Date        : $(date +'%d-%m-%Y %H:%M:%S')                                    " 0
    log "I" " Process PID : $$                                                              " 0
    log "I" " User        : $(whoami)                                                       " 0
    log "I" " Active debug: $DEBUG_FLAG                                                     " 0
    log "I" "###############################################################################" 0
    log "I" "" 0
}
    
    

# Funzione di chiusura script.
function end_script
{
    message=""
    [ $1 -eq 0 ] && {
        [[ "$DEBUG_FLAG" == "N" && -n "$TMPDIR" ]] && {
            log 'I' "Removing temporary files..." 1
            if [[ "$TMPDIR" =~ "^[\/]tmp\/$(whoami)\/.*" ]]
            then
                log 'I' "rm -rf $TMPDIR" 0
                rm -rf $TMPDIR
            fi
        } || {
            log 'D' "ACTIVE DEBUG FLAG: i don't remove the files under directory '$TMPDIR'..." 1
        }
        log "I" "Ok, script completed! Exiting with rc 0..." 0
    }
    log "I" "" 0
    log "I" "###############################################################################" 0
    log "I" " ending script $SCRIPT_NAME                                                    " 0
    log "I" " ------------------------------------------------------------------------------" 0
    log "I" " Date        : $(date +'%d-%m-%Y %H:%M:%S')                                    " 0
    log "I" " Process PID : $$                                                              " 0
    log "I" " User        : $(whoami)                                                       " 0
    log "I" " Return code : $1                                                              " 0
    log "I" "###############################################################################" 0
    log "I" "" 0
    exit $1
}
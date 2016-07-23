#!/bin/bash

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
export DEFAULT_TEMP_DIR="/tmp/"
export DEBUG_FLAG=N
export SCRIPT_NAME=""


# Metodo per il logging degli script. Esempi di chiamate:
# log "I" "messaggio da loggare" 0 --> stampa [ <timestamp> ] @@ I @@ livello base
# log "I" "messaggio da loggare" 1 --> stampa [ <timestamp> ] @@ I @@ -- primo livello
# log "I" "messaggio da loggare" 2 --> stampa [ <timestamp> ] @@ I @@ ---- secondo livello
# log "I" "messaggio da loggare" 1 --> stampa [ <timestamp> ] @@ I @@ -- primo livello
function log {
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
function dlog {
    if [[ "$DEBUG_FLAG" == 'Y' ]]
    then
        log "$@"
    fi
}


function pipe_log {
    while read line
    do
        log 'I' "$line" $1
    done
}


function dpipe_log {
    while read line
    do
        dlog 'D' "$line" $1
    done
}

#####  La funzione simula un breakpoint in fase di esecuzione
##### (attiva solo in caso di debug abilitato)
function breakpoint {
    [ "$DEBUG_FLAG" == "Y" ] && {
        dlog "$*" 
        read 
    }
}


# La funzione esce dallo script.
function my_exit {
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
function init_script {
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
function end_script {
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


function onSignal {
    rc=$?
    log 'E' " ***** Signal received $rc"
    my_exit 1
}

function setAndCheck {
var3=$3
case "$1" in
    "-d")
        # Verifica che la directory specificata esista
        [[ -d "$var3" ]] || { hLog "$2: Unable to find directory '$var3'"; return 1; }
        ;;
    "-f")
        # Verifica che il file specificato esista
        [[ -f "$var3" ]] || { hLog "$2: Unable to find file '$var3'"; return 1; }
        ;;
    "-n")
        # Verifica che il valore specificato sia un numero
        [[ -n "$var3" && "$var3" = *([[:digit:]]) ]] || { hLog "$2: Invalid number '$var3'"; return 1; }
        ;;
    "-s"|"-S")
        #verifica che la stringa specificata non sia vuota
        [[ -n "$var3" ]] || { hLog "$2: Specified string is null!"; return 1; }
        [[ "$1" = "-S" ]] && var3=$(echo $var3|tr '[:lower:]' '[:upper:]')
        ;;
    "-b")
        #verifica che la stringa valga 'true o 'false'
        [[ "$var3" = "true" || "$var3" = "false" ]] || { hLog "$2: Invalid boolean '$var3' (only 'true' or 'false' are allowed)"; return 1; }
        ;;
    *)	
        hLog "$2: Invalid test specified: '$1'"
        return 1
        ;;
    esac
    eval "export $2='${var3}'" || return 1
    return 0
}             


# Il funzionamento è uguale alla setAndCheck
# salvo che in caso di errore esegue una exit.
function xSetAndCheck {
    [[ "$FNDBG" = *(?)${0##*/}*(?) ]] && set -x #put script/function name into FNDBG to enable debug
    setAndCheck "$1" "$2" "$3"
    rc=$?
    [[ $rc -eq 0 ]] || myExit $rc
    return 0
}


#trasforma gli elementi di un array valutando l'espressione passata come secondo parametro
# nell'espressione CUR_VAL rappresenta il valore dell'elemento corrente
# eventuali apici dovranno essere protetti con backslash
# NON VIENE ESEGUITO NESSUN CONTROLLO SULLA SEMANTICA DELL' ESPRESSIONE DA VALUTARE!!
function __MAP_ARRAY {
    [[ "$FNDBG" =  *(?)${0##*/}*(?) ]] && set -x #put script/function name into FNDBG to enable debug
    setAndCheck -s REF_ARRAY_NAME $1 || return 1
    [[ -n "$2" ]] || return 2
    typeset -n REF_ARRAY=$REF_ARRAY_NAME
    typeset -i IMAX=${#REF_ARRAY[*]}
    typeset -i IDX=0
    while [[ $IDX -lt $IMAX ]]
    do
        CUR_VAL="${REF_ARRAY[$IDX]}"
        eval "REF_ARRAY[$IDX]=${2//CUR_VAL/$CUR_VAL}" || return 3
        ((IDX++))
    done
    return 0
}

#trasforma un array in una stringa , separando i vari elementi con uno o piu' caratteri
function __JOIN_ARRAY {
    [[ "$FNDBG" =  *(?)${0##*/}*(?) ]] && set -x #put script/function name into FNDBG to enable debug
    setAndCheck -s REF_ARRAY_NAME $1 || return 1
    setAndCheck -s REF_VAL_NAME $2 || return 2
    setAndCheck -s SEP "$3" || return 3
    typeset -n REF_ARRAY=$REF_ARRAY_NAME
    typeset -n REF_VAL=$REF_VAL_NAME
    typeset -i IMAX=${#REF_ARRAY[*]}
    typeset -i IDX=0
    while [[ $IDX -lt $IMAX ]]
    do
        if [[ $IDX -eq 0 ]]
        then
            REF_VAL="${REF_ARRAY[$IDX]}"
        else
            REF_VAL="${REF_VAL}${SEP}${REF_ARRAY[$IDX]}"
        fi
        ((IDX++))
    done
    return 0
}

#trasforma una stringa in un array, separando i vari elementi con uno o piu' caratteri

function __SPLIT_ARRAY {
    [[ "$FNDBG" =  *(?)${0##*/}*(?) ]] && set -x #put script/function name into FNDBG to enable debug
    setAndCheck -s REF_ARRAY_NAME "$1" || return 1
    setAndCheck -s REF_VAL_NAME "$2" || return 2
    setAndCheck -s SEP "$3" || return 3
    typeset -n REF_VAL=$REF_VAL_NAME
    #uso la tokenize di ShellFunctions.funct
    tokenize "$REF_ARRAY_NAME" "$REF_VAL" "$SEP" || return 4
    return 0
}

#riduce un array tenendo solamente gli elementi univoci
#prende in input il nome della variabile che contiene l'array da ridurre 
function __UNIQUE_ARRAY {
    [[ "$FNDBG" =  *(?)${0##*/}*(?) ]] && set -x #put script/function name into FNDBG to enable debug
    setAndCheck -s REF_ARRAY_NAME $1 || return 1
    typeset -n REF_ARRAY=$REF_ARRAY_NAME
    typeset -i IMAX=${#REF_ARRAY[*]}
    typeset -i IDX=0
    typeset -i JDX=0
    typeset -i JMAX=0
    set -A TEMP_ARRAY
    while [[ $IDX -lt $IMAX ]]
    do
        SEEN=0
        CURR_VAL=${REF_ARRAY[$IDX]}
        JMAX=${#TEMP_ARRAY[*]}
        JDX=0
        while [[ $JDX -lt $JMAX ]]
        do
            [[ "${TEMP_ARRAY[$JDX]}" == "$CURR_VAL" ]] && SEEN=1
            ((JDX++))
        done
        [[ $SEEN -eq 0 ]] && TEMP_ARRAY[$JMAX]=$CURR_VAL
        ((IDX++))
    done
    typeset IFS=$'\n'
    REF_ARRAY=(${TEMP_ARRAY[*]})
    return 0
}

#inserisce all'ultimo posto di un array una stringa
function __PUSH_ARRAY {
    [[ "$FNDBG" =  *(?)${0##*/}*(?) ]] && set -x #put script/function name into FNDBG to enable debug
    setAndCheck -s REF_ARRAY_NAME $1 || return 1
    setAndCheck -s REF_VAR_NAME $2 || return 2
    typeset -n REF_ARRAY=$REF_ARRAY_NAME
    typeset -n REF_VAR=$REF_VAR_NAME
    typeset -i IMAX=${#REF_ARRAY[*]}
    REF_ARRAY[$IMAX]=$REF_VAR
    return 0
}

# rimuove l'ultimo elemento da un array e (opzionalmente) lo ritorna nella variabile passata come secondo argomento
function __POP_ARRAY {
    [[ "$FNDBG" =  *(?)${0##*/}*(?) ]] && set -x #put script/function name into FNDBG to enable debug
    setAndCheck -s REF_ARRAY_NAME $1 || return 1
    if [[ -n "$2" ]]
    then 
        RETURN_VAL=1
    else
        RETURN_VAL=0
    fi 
    typeset -n REF_ARRAY=$REF_ARRAY_NAME
    [[ $RETURN_VAL -eq 1 ]] && typeset -n REF_VAL=$2
    typeset -i IMAX=$((${#REF_ARRAY[*]}-1))
    [[ $RETURN_VAL -eq 1 ]]  && REF_VAL=${REF_ARRAY[$IMAX]}
    unset REF_ARRAY[$IMAX]
}

#inserisce il valore della stringa passato come secondo argomento come primo elemento dell'array
function __SHIFT_ARRAY {
    [[ "$FNDBG" =  *(?)${0##*/}*(?) ]] && set -x #put script/function name into FNDBG to enable debug
    setAndCheck -s REF_ARRAY_NAME $1 || return 1
    setAndCheck -s REF_VAR_NAME $2 || return 2
    typeset -n REF_ARRAY=$REF_ARRAY_NAME
    typeset -n REF_VAR=$REF_VAR_NAME
    set -A TEMP_ARRAY
    typeset IFS=$'\n'
    TEMP_ARRAY=(${REF_ARRAY[*]})
    REF_ARRAY=(${REF_VAR} ${TEMP_ARRAY[*]})
    return 0
}

# rimuove il primo elemento da un array e (opzionalmente) lo ritorna nella variabile passata come secondo argomento
function __UNSHIFT_ARRAY {
    [[ "$FNDBG" =  *(?)${0##*/}*(?) ]] && set -x #put script/function name into FNDBG to enable debug
    setAndCheck -s REF_ARRAY_NAME $1 || return 1
    if [[ -n "$2" ]]
    then 
        RETURN_VAL=1
    else
        RETURN_VAL=0
    fi 
    typeset -n REF_ARRAY=$REF_ARRAY_NAME
    [[ $RETURN_VAL -eq 1 ]] && typeset -n REF_VAL=$2
    typeset -i IDX=0
    
    typeset -i IMAX=${#REF_ARRAY[*]}
    [[ $RETURN_VAL -eq 1 ]] && REF_VAL=${REF_ARRAY[0]}
    while [[ $IDX -lt $((IMAX-1)) ]]
    do
        REF_ARRAY[$IDX]=${REF_ARRAY[$((++IDX))]}
    done
    unset REF_ARRAY[$IDX]
    return 0
}


function __PARSE_CHECKED_ARGS {
    [[ "$FNDBG" = *(?)${0##*/}*(?) ]] && set -x #put script/function name into FNDBG to enable debug
    typeset IFS=$'\n'
    typeset -x CUR_LINE=''
    [[ -n "$CHECKED_ARGS" ]] || return 1
    setAndCheck -s LOC_SWITCHES_ARRAY_NAME $1 || return 2
    setAndCheck -s LOC_PARAM_ARRAY_NAME $2 || return 3
    setAndCheck -s LOC_OPTPAR_ARRAY_NAME $3 || return 4
    
    for CUR_LINE in $(printf "%s" "$CHECKED_ARGS")
    do
        TRIM_CUR_LINE="${CUR_LINE//[[:space:]]/}"
        if [[ -n "$TRIM_CUR_LINE" ]]
        then
            OPT_NAME=${CUR_LINE%%=*}
            OPT_EXPL=${CUR_LINE#*=}
            case ${TRIM_CUR_LINE:0:1} in
                '-')
                    #rimuovo il - dagli switch
                    OPT_NAME=${OPT_NAME#-}
                    #controllo che la definizione dello switch sia di un solo carattere nel range [A-Za-z0-9]
                    [[ ${#OPT_NAME} -eq 1 ]] || return 5
                    [[ -n "${OPT_NAME//[^[:alnum:]]/}" ]] || return 6
                    CUR_LINE="${OPT_NAME}=${OPT_EXPL}"
                    __PUSH_ARRAY $LOC_SWITCHES_ARRAY_NAME CUR_LINE || return 7
                    ;;
                '[')
                    #rimuovo le parentesi quadre dai parametri opzionali
                    OPT_NAME=${OPT_NAME#[}
                    OPT_NAME=${OPT_NAME%]}
                    CUR_LINE="${OPT_NAME}=${OPT_EXPL}"
                    
                    __CHECK_PARAM_DEF "${CUR_LINE}" || {
                        printf "\- ERRORE: il parametro opzionale\n\n\t\t\"%s\"\n\n  non e' correttamente definito, controllare la variabile CHECKED_ARGS\n\n" "${CUR_LINE}" |hPipeLog
                        return 8
                    }
                    __PUSH_ARRAY $LOC_OPTPAR_ARRAY_NAME CUR_LINE || return 9
                    ;;
                *)
                    __CHECK_PARAM_DEF "${CUR_LINE}" || {
                        printf "\- ERRORE: il parametro\n\n\t\t\"%s\"\n\n  non e' correttamente definito, controllare la variabile CHECKED_ARGS\n\n" "${CUR_LINE}" |hPipeLog 
                        return 10
                    }
                    __PUSH_ARRAY $LOC_PARAM_ARRAY_NAME CUR_LINE || return 11
                    ;;
            esac
        fi
    done
    
    return 0
}

function __PRINT_USAGE_ARRAY {
    [[ "$FNDBG" = *(?)${0##*/}*(?) ]] && set -x #put script/function name into FNDBG to enable debug
    setAndCheck -s OPT_TYPE "$1" || return 1
    setAndCheck -s REF_ARRAY_NAME $2 || return 2
    typeset -n REF_ARRAY=$REF_ARRAY_NAME
    typeset -i IDX=0
    typeset -i IMAX=${#REF_ARRAY[*]}
    printf "\n\n$OPT_TYPE:\n" | hPipeLog
    while [[ $IDX -lt $IMAX ]]
    do 
        CUR_OPT=${REF_ARRAY[$IDX]}
        OPT_NAME=${CUR_OPT%%=*}
        OPT_EXPL=${CUR_OPT#*=}
        printf "\n\t=> %s\n\t\t%s\n" "$OPT_NAME" "$OPT_EXPL"| hPipeLog
        ((IDX++))
    done
}

function __USAGE {
    [[ "$FNDBG" = *(?)${0##*/}*(?) ]] && set -x #put script/function name into FNDBG to enable debug
    [[ -n "$MY_NAME" && -n "$CHECKED_ARGS" ]] || myExit 128 '- ERRORE: Variabili $MY_NAME o $CHECKED_ARGS non definite' 
    set -A USAGE_SWITCHES_ARRAY
    set -A USAGE_PARAMS_ARRAY
    set -A USAGE_OPT_PARAMS_ARRAY
    SWITCHES_LBL='SWITCHES'
    PARAMS_LBL='PARAMS'
    OPT_PARAMS_LBL='OPT_PARS'
    OVERRIDES_LBL='OVERRIDES'
    ARGS_LBL='ARGS'
    ARGS_SINTAX_LBL="${ARGS_LBL}"
    
    __PARSE_CHECKED_ARGS USAGE_SWITCHES_ARRAY USAGE_PARAMS_ARRAY USAGE_OPT_PARAMS_ARRAY || myExit 128 "- ERRORE: la funzione __PARSE_CHECKED_ARGS ha restituito RC=$?";
    
    [[ -n "$USAGE_SWITCHES_ARRAY[0]" ]] && typeset ADD_SWITCHES=" [${SWITCHES_LBL}]"  
    [[ -n "$USAGE_PARAMS_ARRAY[0]" ]] && typeset ADD_PARAMS=" ${PARAMS_LBL}"
    [[ -n "$USAGE_OPT_PARAMS_ARRAY[0]" ]] && typeset ADD_OPT_PARAMS=" [${OPT_PARAMS_LBL}]"  
    
    if [[ "$HELP_ON_NO_ARGS" -eq 1 ]]
    then
        [[ -n "${HELP_SWITCHES//[-\|[:space:]]/}" ]] && HELP_SWITCHES=" [$HELP_SWITCHES] " || HELP_SWITCHES=' '
        [[ -z "$ADD_PARAMS" ]] || ARGS_SINTAX_LBL="[${ARGS_LBL}]"
    else
        [[ -n "${HELP_SWITCHES//[-\|[:space:]]/}" ]] && HELP_SWITCHES=" $HELP_SWITCHES " || unset HELP_SWITCHES
        [[ -n "$ADD_PARAMS" ]] && ARGS_SINTAX_LBL="[${ARGS_LBL}]"
    fi
    if    [[ -n "$USAGE_SUMMARY" ]]
    then
        printf '\n%s\n\n' "$MY_NAME" |hPipeLog
        typeset IFS=$'\n'
        typeset USAGE_SUMMARY_LINE
        for USAGE_SUMMARY_LINE in $(printf "%s" "$USAGE_SUMMARY")
        do
            printf '\t\t%s\n' "$USAGE_SUMMARY_LINE" |hPipeLog
        done
        hLog ""
    fi
    printf '\nSINTASSI:\n' |hPipeLog
    [[ -n "${HELP_SWITCHES}" ]] && printf '\n\t%s%s(visualizza questo messaggio)\n\n\t\toppure\n' "$MY_NAME" "$HELP_SWITCHES"| hPipeLog
    
    printf '\n\t%s%s%s%s [%s] [--] %s\n\n\ndove:\n' "$MY_NAME" "$ADD_SWITCHES" "$ADD_PARAMS" "$ADD_OPT_PARAMS" "$OVERRIDES_LBL" "${ARGS_SINTAX_LBL}" |hPipeLog 
    
    [[ -n "$ADD_SWITCHES" ]] && __PRINT_USAGE_ARRAY "$(printf '%s\t(preceduti da \"-\",  attivano i comportamenti opzionali)' ${SWITCHES_LBL})" USAGE_SWITCHES_ARRAY
    [[ -n "$ADD_PARAMS" ]] && __PRINT_USAGE_ARRAY "$( printf '%s\t(espressioni, nella forma CHIAVE=VALORE, da fornire sempre. Viene effettuato il controllo del tipo)' ${PARAMS_LBL})" USAGE_PARAMS_ARRAY
    [[ -n "$ADD_OPT_PARAMS" ]] && __PRINT_USAGE_ARRAY "$(printf '%s\t(espressioni opzionali, nella forma CHIAVE=VALORE, che sovrascrivono i default. Viene effettuato il controllo del tipo)' ${OPT_PARAMS_LBL})" USAGE_OPT_PARAMS_ARRAY
    printf '\n\n%s\t(espressioni opzionali, nella forma CHIAVE=VALORE, che sovrascrivono i default. Senza controllo del tipo)\n' "${OVERRIDES_LBL}" | hPipeLog
    printf "\n\n--\t(forza il termine dell'esame degli elementi precedenti, utilizzabile nel caso in cui la linea di comando contenga espressioni che non si desidera processare)\n"| hPipeLog
    printf '\n\n%s\t(argomenti da passare allo script, diventeranno le variabili $1, $2, ecc.)\n' "${ARGS_LBL}" | hPipeLog
    hLog ""
    [[ $1 -eq 0 ]] || printf '\n***********************************************\n\n' | hPipeLog
    
    unset USAGE_SWITCHES_ARRAY
    unset USAGE_PARAMS_ARRAY
    unset USAGE_OPT_PARAMS_ARRAY
    
    myExit $1 "$2"
}

function __GET_PARAMS {
    [[ "$FNDBG" = *(?)${0##*/}*(?) ]] && set -x #put script/function name into FNDBG to enable debug
    
    #se HELP_ON_NO_ARGS vale 1 e lo script e' invocato senza argomenti, stampa il messasggio di utilizzo ed esce 
    [[ "$HELP_ON_NO_ARGS" -eq 1 && $# -eq 0 ]] && __USAGE 0 ""
    
    #se la variabile HELP_SWITCHES contiene qualcosa e lo script e' stato invocato con un unico argomento
    #si verifica se si deve visualizzare il messaggio di aiuto
    
    if [[ -n "${HELP_SWITCHES//[-\|[:space:]]/}" && $# -eq 1 ]]
    then
        #se l'unico argomento fornito e' compreso in HELP_SWITCHES, stampa il messagio di utilizzo ed esce
        [[ "$1" = ${HELP_SWITCHES} ]] && __USAGE 0
    fi
    
    [[ -n "$CHECKED_ARGS" ]] || myExit 128 '- ERRORE: Variabile $CHECKED_ARGS non definita' 
    
    set -A CHK_ARGS_SWITCHES_ARRAY
    set -A CHK_ARGS_PARAMS_ARRAY
    set -A CHK_ARGS_OPT_PARAMS_ARRAY

    typeset -A PARAMS_ARRAY
    typeset -A OPT_PARAMS_ARRAY
    
    typeset -i IMAX=0
    typeset -i IDX=0
    
    typeset DOUBLE_DASH_SEEN=0 #vale 1 se l'argomento "--" e' stato passato in input
    typeset VALID_SWITCHES=''
    
    
    set -A GET_PARAMS_FOUND_SWITCHES #esportata 
    
    GET_PARAMS_ARGS_SHIFTED=0 #esportata
    
    
    #--------- FASE 1: eleborazione della sintassi del comando --------#
    
    __PARSE_CHECKED_ARGS CHK_ARGS_SWITCHES_ARRAY CHK_ARGS_PARAMS_ARRAY CHK_ARGS_OPT_PARAMS_ARRAY || myExit 128 "- ERRORE: la funzione __PARSE_CHECKED_ARGS ha restituito RC=$?";
    
    #ulteriori elaborazioni sulla definizione della sintassi
    #determino la lista degli switch validi, da passare alla getopts
    IMAX=${#CHK_ARGS_SWITCHES_ARRAY[*]}
    while [[ $IDX -lt $IMAX ]]
    do
        CUR_SWITCH="${CHK_ARGS_SWITCHES_ARRAY[$IDX]}"
        VALID_SWITCHES="${VALID_SWITCHES}${CUR_SWITCH%=*}"
        ((IDX++))
    done
    
    #rielaboro la lista dei parametri obbligatori
    IDX=0
    IMAX=${#CHK_ARGS_PARAMS_ARRAY[*]}
    while [[ $IDX -lt $IMAX ]]
    do
        typeset CUR_PARAM="${CHK_ARGS_PARAMS_ARRAY[$IDX]}"
        typeset PARAM_NAME=${CUR_PARAM%%=*}
        typeset PARAM_TYPE=${CUR_PARAM#*=}
        PARAM_TYPE=${PARAM_TYPE%%\)[[:space:]]*}
        PARAM_TYPE=${PARAM_TYPE#\(}
        PARAMS_ARRAY[$PARAM_NAME]=$PARAM_TYPE
        ((IDX++))
    done
    
    #rielaboro la lista dei parametri opzionali
    IDX=0
    IMAX=${#CHK_ARGS_OPT_PARAMS_ARRAY[*]}
    while [[ $IDX -lt $IMAX ]]
    do
        typeset CUR_OPT_PARAM="${CHK_ARGS_OPT_PARAMS_ARRAY[$IDX]}"
        typeset OPT_PARAM_NAME=${CUR_OPT_PARAM%%=*}
        typeset OPT_PARAM_TYPE=${CUR_OPT_PARAM#*=}
        OPT_PARAM_TYPE=${OPT_PARAM_TYPE%%\)[[:space:]]*}
        OPT_PARAM_TYPE=${OPT_PARAM_TYPE#\(}
        OPT_PARAMS_ARRAY[$OPT_PARAM_NAME]=$OPT_PARAM_TYPE
        ((IDX++))
    done
    
    
    #-------- FASE 2: parsing degli argomenti passati in input --------#
    
    #gestione degli SWITCH
    if [[ -n "$VALID_SWITCHES" ]]
    then
        #IDX qui serve per tenere traccia del numero di volte che getopts è stata eseguita.
        #alla fine del ciclo si effettua il confronto con OPTIND per verificare
        #se l'argomento "--" e' stato passato in input e processato da getopts
        #il manuale di getopts dice di guardare la variabile OPTARG ma dice il falso!
        IDX=1
        while getopts ":$VALID_SWITCHES" SWITCH_NAME
        do
            case ${SWITCH_NAME} in
                '?')
                    hLog "- ERRORE: Rilevato SWITCH non valido [-$OPTARG]!" 
                    return 1
                    ;;
                *)
                    __PUSH_ARRAY GET_PARAMS_FOUND_SWITCHES SWITCH_NAME
                    ;;
                esac
            ((IDX++))
        done
        [[ $IDX -eq $OPTIND ]] || DOUBLE_DASH_SEEN=1
        ((GET_PARAMS_ARGS_SHIFTED=OPTIND-1))
        shift $((GET_PARAMS_ARGS_SHIFTED))
    fi
    
    #gestione di parametri obbligatori, opzionali e override, se l'opzione '--' non e' gia' stata processata da getopts
    if  [[ $DOUBLE_DASH_SEEN -eq 0 ]]
    then
        #il loop termina:
        #se viene trovato l'argomento speciale "--"
        #al primo argomento trovato che non sia nella forma CHIAVE=VALORE
        #alla fine degli argomenti forniti
        typeset PARAMS_KEYS="${!PARAMS_ARRAY[*]}"
        typeset OPT_PARAMS_KEYS="${!OPT_PARAMS_ARRAY[*]}"
        while [[ $# -ge 1 ]]
        do
            typeset CUR_ARG=$1
            typeset EQUAL_TRIMMED_CUR_ARG=${CUR_ARG//=/} #rimuovo tutte le occorrenze del carattere '=' per verificare che l'argomento corrente sia nella forma CHIAVE=VALORE
            typeset -i LEN_CUR_ARG=${#CUR_ARG}
            typeset -i LEN_EQUAL_TRIMMED_CUR_ARG=${#EQUAL_TRIMMED_CUR_ARG}            
            if [[ "$CUR_ARG" = "--" ]] #argomento speciale '--'
            then
                ((GET_PARAMS_ARGS_SHIFTED++)) # salta l'argomento '--' ed esce dal loop
                break
            elif [[ ${LEN_CUR_ARG} -eq ${LEN_EQUAL_TRIMMED_CUR_ARG} ]] #argomento in forma diversa da CHIAVE=VALORE
            then
                break #esce dal loop
            else
                #verifico che vi sia uno ed un solo carattere '=' nell'argomento
                [[ $((LEN_CUR_ARG-LEN_EQUAL_TRIMMED_CUR_ARG)) -eq 1 ]] || { hLog "- ERRORE: Rilevato ARGOMENTO [$CUR_ARG] in forma non valida!"; return 2; }
                typeset CUR_KEY=${CUR_ARG%=*}
                typeset -x CUR_VALUE=${CUR_ARG#*=}
                typeset -i PARAM_SEEN=0
                typeset -i OPT_PARAM_SEEN=0
                typeset -i MULTI_VALUE=0
                typeset ARG_TYPE
                #controllo degli array di parametri definiti dalla variabile CHECKED_ARGS, sia obbligatori che opzionali
                #verifico se la chiave corrente e' contenuta in uno dei due array di parametri
                [[ -n "$PARAMS_KEYS" && "${PARAMS_KEYS}" = @(${CUR_KEY}|${CUR_KEY} *|* ${CUR_KEY} *|* ${CUR_KEY}) ]] && PARAM_SEEN=1
                [[ -n "$OPT_PARAMS_KEYS" && "${OPT_PARAMS_KEYS}" = @(${CUR_KEY}|${CUR_KEY} *|* ${CUR_KEY} *|* ${CUR_KEY}) ]] && OPT_PARAM_SEEN=1
                
                [[ $PARAM_SEEN -eq 1 && $OPT_PARAM_SEEN -eq 1 ]] && { hLog "- ERRORE: Rilevato ARGOMENTO [$CUR_ARG] definito sia come parametro obbligatorio che opzionale! Verificare la sintassi del comando dichiarata nella variable CHECKED_ARGS!"; return 3; }
                
                if [[ $PARAM_SEEN -eq 1 ]] #se il parametro e' presente nella lista dei parametri obbligatori, provo a verificare se è del tipo corretto
                then
                    ARG_TYPE=${PARAMS_ARRAY[$CUR_KEY]}
                elif [[ $OPT_PARAM_SEEN -eq 1 ]] #se il parametro e' presente nella lista dei parametri opzionali, provo a verificare se è del tipo corretto
                then
                    ARG_TYPE=${OPT_PARAMS_ARRAY[$CUR_KEY]}
                else #il parametro e' un override, provo a settare la variabile come stringa
                    ARG_TYPE="s"
                fi
                
                if [[ ${#ARG_TYPE} -eq 2 && "${ARG_TYPE:0:1}" = 'm' ]]
                then
                    MULTI_VALUE=1
                    ARG_TYPE="${ARG_TYPE:1}"
                fi
                #provo ad impostare tramite setAndCheck per verificare l'argomento
                #se setAndCheck non ritorna errore, l'argomento  e' corretto dal punto di vista semantico
                setAndCheck "-${ARG_TYPE}" "TEMP_${CUR_KEY}" "$CUR_VALUE" || { hLog "- ERRORE: Impossibile impostare la variabile corrispondente all'ARGOMENTO [$CUR_ARG]"; return 4; }
                
                #imposto la variabile definitiva
                if [[ $MULTI_VALUE -eq 1 ]]
                then
                    __PUSH_ARRAY "${CUR_KEY}" CUR_VALUE
                    export "${CUR_KEY}"
                else
                    export "${CUR_KEY}"="$CUR_VALUE"
                fi
                unset "TEMP_${CUR_KEY}"
                ((GET_PARAMS_ARGS_SHIFTED++))
                
            fi
            #se ho altri argomenti da processare
            shift
        done
    fi
    #verifica della presenza di tutti i parametri obbligatori
    typeset IFS=$' '
    typeset CUR_PARAM_KEY
    typeset -i UNSEEN_PARAMETERS=0
    for CUR_PARAM_KEY in ${!PARAMS_ARRAY[*]}
    do
        typeset -n LOOP_VAR=${CUR_PARAM_KEY}
        if [[ -z "${LOOP_VAR}" ]]
        then        
            hLog "- ERRORE: Il parametro obbligatorio [$CUR_PARAM_KEY] non e' stato impostato!"
            ((UNSEEN_PARAMETERS++))
        fi
    done
    [[ $UNSEEN_PARAMETERS -eq 0 ]] || { SUFFIX='o'; [[ $UNSEEN_PARAMETERS -gt 1 ]] && SUFFIX='i'; hLog "- ERRORE: $UNSEEN_PARAMETERS parametr${SUFFIX} richiest${SUFFIX} non impostat${SUFFIX}!"; return 5; }    
    
    #cleanup    
    unset CHK_ARGS_SWITCHES_ARRAY
    unset CHK_ARGS_PARAMS_ARRAY
    unset CHK_ARGS_OPT_PARAMS_ARRAY


    return 0
}










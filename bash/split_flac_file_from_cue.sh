#!/bin/bash

function usage
{   
        log 'I' "Parametri in input:" 1
        log 'I' "INPUT_DIR: directory di input da analizzare" 2
        log 'I' "[OUTPUT_CODEC: formato di output" 2
}


INPUT_DIR=""


. ${HOME}/bin/functions.sh 2>&1 || exit 1 

# Checking debug option...
while getopts ":Dd" o; do
    case "${o}" in
        [Dd])
            DEBUG_FLAG=Y
            ;;
        *)
            my_exit "Opzione non riconosciuta: '$o' -- '$OPTARG'" 1
            ;;
    esac
done
shift $((OPTIND-1))

# Initializing script...
init_script

log 'I' "Controllo parametri di ingresso" 1

# [ $# -eq 1 ] || my_exit "necessario un parametro (la cartella root da cui recuperare i file cue)" 1

INPUT_DIR=""
FILES_TO_SEARCH="flac ape"
OUTPUT_CODEC=""

case $# in
    0) 
        __usage
        my_exit "necessario un parametro (la cartella root da cui recuperare i file cue)" 1
        ;;
    1)  
        INPUT_DIR="$1"
        OUTPUT_CODEC=""
        ;;
    2)
        INPUT_DIR="$1"
        OUTPUT_CODEC="$2"
        ;;
    *)
        __usage
        my_exit "Troppi parametri inseriti!" 1
esac


[ -n "$INPUT_DIR" ] || my_exit "Directory $INPUT_DIR con nome vuoto!" 2

[ -d "$INPUT_DIR" ] || my_exit "Directory $INPUT_DIR non esistente!" 3

[ -z "$(echo $INPUT_DIR | grep ' ')" ] || {
    log 'W' 'Attenzione: la stringa contiene spazi, li devo sostituire con "_". Procedo (o annullo)? [Y/N]' 1
    answer=""
    read answer
    case $answer in
        [yYsS])
            NEW_INPUT_DIR="$(echo $INPUT_DIR | sed 's@ @_@g')"
            mv "$INPUT_DIR" "$NEW_INPUT_DIR" || my_exit "Impossibile rinominare la directory!" 4
            INPUT_DIR="$NEW_INPUT_DIR"
            log 'I' "Ok, stringa modificata in '$INPUT_DIR'" 2
            ;;
        [nN])
            my_exit "Ok, allora esco..." 0
            ;;
        *)  
            my_exit "Scelta non valida: $answer. Esco..." 5
            ;;
    esac
}

log 'I' "Imposto l'internal field separator al caporiga..." 1
IFS="
"

log 'I' "Recupero i file .cue da $INPUT_DIR da leggere per splittare i .flac..." 1

for file in $(find "$INPUT_DIR" -type f -name "*.cue")
do
    log 'I' "File .cue rilevato: $file" 2
    filedir="$(dirname $file)" #  | sed 's@\([(,)\! ]\)@\\\1@g')"
    filename="$(basename $file)" # | sed 's@\([(,)\! ]\)@\\\1@g')"
    
    #breakpoint "Filedir: $filedir \nfilename: $filename"
    
    # cerco file con traccia unica
    filesnum=0
    for fileext in $(echo $FILES_TO_SEARCH | sed ' s/ /\n/g')
    do
        log 'I' "Cerco file con estensione '$fileext'..." 3
        filesnum=$(find "$filedir" -type f -name "*.$fileext" | wc -l)
        #breakpoint ""
        [ $filesnum -eq 0 ] && {
            log 'I' " nessun file *.$fileext identificato!" 4
            continue
        } || break
    done
    # Controllo che ci siano file
    case $filesnum in
        0) 
            log 'I' " nessun file con estensione valida ('$FILES_TO_SEARCH') identificato!" 2
            log 'I' "Passo al successivo file cue da elaborare" 2
            continue
            ;;
        1)  
            file2split=$(find "$filedir" -type f -name "*.$fileext") #  | sed 's@\([(,) ]\)@\\\1@g')
            log 'I' "Ok, rilevato un file da dividere: '$file2split'" 2
            ;;
        *)
            log 'W' "ATTENZIONE: rilevati piu' file nella cartella indicata:" 2
            find "$filedir" -type f -name "*.$fileext" | pipe_log 2
            log 'W' "            probabilmente il file e' gia' diviso!" 2
            break
        ;;
    esac
    
    breakpoint "Filedir: '$filedir' \n file2split: '$file2split' \n cuefile: '$filename'"

    log 'I' "Procedo con lo splitting..." 2
    cd "$filedir" && dlog 'D' "Sono in $(pwd)" 3 || my_exit "Impossibile accedere alla directory ${filedir} !" 6
    dlog 'D' "Segue un listing dei file nella directory: " 2
    ls -l | pipe_log 2
    breakpoint
    shntool split -o $OUTPUT_CODEC -f "$filename" "$(basename $file2split)" || {
        my_exit "Conversione fallita! Consulta il log per dettagli!" 7 
    }
    
done

my_exit "Ok, script eseguito con successo!" 0
#!/bin/bash

# COMMON VARIABLES
SCRIPT_NAME="$(basename $0)"              # Script Name
VERSION="1"                               # Script Version
TIMESTAMP=$(date +'%d%m%Y_%H%M%S')        # Timestamp string
TMPDIR="/tmp/$SCRIPT_NAME.$TIMESTAMP/"    # Temporary directory

# CONSTANTS AND OTHER DEFINITIONS
DEB_PACKAGE_EXTRACTOR="$(which ar)"       # Programma per disarchiviazione pacchetto deb
DEB_PACKAGE_EXTRACTOR_FLAGS="x"           # Flag di estrazione pacchetto
DEB_PACKAGE_CREATOR="$(which dpkg)"       # Programma di generazione pacchetto deb
DEB_PACKAGE_CREATOR_FLAGS="-b"            # Flag per generazione pacchetto deb

# SCRIPT VARIABLES
SOURCE_PACKAGE=""                         # Path completo del package da estrarre
SOURCE_DIR=""                             # Directory del package estratto da rigenerare


# Importing common functions
. ${HOME}/bin/shell/functions.sh 2>&1 || exit 1 

# Help Function
function usage {   
        log 'I' "Parametri/Opzioni in input:" 1
        log 'I' " |-- -e SOURCE_PACKAGE: file .deb di partenza da estrarre"
        log 'I' " |-- -r SOURCE_DIR    : directory da cui partire per ripacchettizzare"
}

function repackage_folder {
    echo "CIAO"
}

function extract_package {

    OUTDIR="/tmp"
    log 'I' "Extracting package phase"

    log 'I' " Checking source package existence " 2
    [ -f ${SOURCE_PACKAGE} ] || {
        log 'E' " ***** ERROR: source package '${SOURCE_PACKAGE}' not found!"
        return 1
    }

    log 'I' "File exists, setting the extract temporary dir..." 2
    filename="$(basename ${SOURCE_PACKAGE})"
    OUTDIR="/tmp/extract_${filename}"
    
    mkdir ${TMPDIR}          || return 2
    mkdir ${TMPDIR}/log      || return 2
    mkdir ${OUTDIR}          || return 2

    log 'I' "Checking for deb extractor program (ar) ... " 2
    [ -z "${DEB_PACKAGE_EXTRACTOR}" ] && {
        log 'E' " ***** ERROR: no program 'ar' to extract .deb file found!" 
        return 4
    }

    log 'I' "Extracting files ... " 2
    cd ${TMPDIR} || return 3
    EXTRACT_LOG_FILE=${TMPDIR}/log/ar.log
    ${DEB_PACKAGE_EXTRACTOR} x ${SOURCE_PACKAGE} 1>${EXTRACT_LOG_FILE} 2>&1
    RC=$?
    [ $RC -ne 0 ] && {
        log 'E' " ***** ERROR: an error occurred on extracting package! This is the log file:"
        cat ${EXTRACT_LOG_FILE} | pipe_log ' [ EXTRACT_PACKAGE_LOG ] ' 
        return $RC
    }

    log 'I' "Extracted root package, moving to inner archives..." 2
    mkdir ${TMPDIR}/control || return 2
    mkdir ${TMPDIR}/data    || return 2
    mkdir ${DEBIAN}         || return 2

    CONTROL_TARGZ="$(ls -1 ${TMPDIR}/control.tar.gz)"
    DATA_TARGZ="$(ls -1 ${TMPDIR}/data.tar.gz)"

    [ -f ${CONTROL_TARGZ} ] || {
        log 'E' " ***** ERROR: unable to find control.tar.gz ! Check the extract log in ${EXTRACT_LOG_FILE}!"
        return 5
    }

    [ -f ${DATA_TARGZ} ] || {
        log 'E' " ***** ERROR: unable to find data.tar.gz ! Check the extract log in ${EXTRACT_LOG_FILE}!"
        return 5
    }
    
    tar xvf ${DATA_TARGZ} -C ${TMPDIR}/data/       || return 6
    tar xvf ${CONTROL_TARGZ} -C ${TMPDIR}/control/ || return 6

    log 'I' "Package extacted! Copying in OUTDIR ..." 2

    cp -r ${TMPDIR}/data ${TMPDIR}/control ${OUTDIR}/ || return 7

    return 0
}


# Checking debug option...
while getopts ":Dd" o; do
    case "${o}" in
        [Dd])
            DEBUG_FLAG=Y
            ;;
        -e) 
            shift
            if test $# -gt 0
            then
                SOURCE_PACKAGE=$1
            else
                log 'E' " ***** ERROR: no package specified! "
                function_usage
                my_exit " No source package specified!" 1
            fi
            ;;
        -r)
            shift 
            if test $# -gt 0
            then
                SOURCE_DIR=$1
            else
                log 'E' " ***** ERROR: no source dir of the package specified!"
                function_usage
                my_exit " No source dir specified!" 1
            fi
            ;;
        *)
            my_exit "Opzione non riconosciuta: '$o' -- '$OPTARG'" 1
            ;;
    esac
done

# Initializing script...
init_script

#[ -z "${SOURCE_DIR}" ] && {
#    repackage_folder 
#    RC=$?
#} || {
#    extract_package
#    RC=$?
#}

my_exit "Script eseguito, esco con RC ${RC}" $RC


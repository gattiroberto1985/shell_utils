#!/bin/bash

[ $# -eq 0 ] && {
    echo "|- Recupero i dati dal file standard"
} || {
    echo "|- ***** ERRORE: non ancora implentata....... "
}

# testing network and eventually mounting netfs (@altervista.org)
ping -c 1 www.google.it 1>/dev/null 2>&1
rc=$?
netfs_list="$HOME/.netfs_logon_params"
if [[ $rc -eq 0 ]]
then
    [ -f $netfs_list ] || {
        echo "|-- File di credenziali $netfs_list non trovato"
        return
    }

    echo "|-- Carico i dati dal file di credenziali di rete"
    while read line
    do
        FS_SERVER=$(echo $line | cut -d ';' -f1)
        FS_MOUNTPOINT=$(echo $line | cut -d ';' -f2)
        FS_USER=$(echo $line | cut -d ';' -f3)
        FS_PWD=$(echo $line  | cut -d ';' -f4)
        [ -z ${FS_SERVER} ] && {
            echo "     Server nullo, esco"
            return
        }
        echo "|---- Monto fs ${FS_SERVER} su ${FS_MOUNTPOINT}..."
        CMD="curlftpfs -o user=${FS_USER}:${FS_PWD} ${FS_SERVER} ${FS_MOUNTPOINT}"
        echo "|---- ** Comando: $CMD"
        eval $CMD
    done < ${netfs_list}
else
    echo "|-- Rete non disponibile, non monto i fs di rete"
fi


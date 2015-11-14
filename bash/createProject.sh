#!/bin/bash


ARGC=2              ## Numero di argomenti di input dello script
PROJNAME=""         ## Nome del progetto
SRC_PATH=""         ## Path del progetto (cartella $PROJNAME sotto SRC_PATH)
ISWEBAPP=1          ## flag che indica se l'applicazione è web o meno (0 true)
LIST="S s Y y N n"  ## Lista valori accettabili per gli input

function print_help
{
 cat << EOF
-------------------------------------------------------------------------------
- I parametri da passare in input allo script sono i seguenti:
- 
-  - PROJNAME: Nome del progetto;
-  - SRC_PATH: path dove posizionare la root del progetto
-
- Il progetto sara' creato sotto SRC_PATH/PROJNAME
-------------------------------------------------------------------------------
EOF
}


function check_root_folder_existence
{
 echo "Controllo folder root del progetto: $ROOT_PRJ"
 if [[ -d $ROOT_PRJ ]]
 then
  read -p "Directory $ROOT_PRJ esistente! Creare un backup? [YySs/Nn]"
  while [[ ! $LIST =~ $REPLY ]]
  do
   echo "Input errato! "
   read - p "Directory $ROOT_PRJ esistente! Creare un backup? [YySs/Nn]"
  done
  case $REPLY in
   [yYsS]) 
           echo "Creo il backup..."
           mv $ROOT_PRJ ${ROOT_PRJ}_bak 2>&1 || echo "ERRORE: rename della cartella $ROOT_PRJ fallito!"
 	   mkdir $ROOT_PRJ 2>&1 || echo "ERRORE: creazione struttura impossibile!"
	   ;;
   [Nn])
           echo "Svuoto la directory..."
 	   rm -rf $ROOT_PRJ/* 2>&1 || echo "ERRORE: pulizia directory terminata con errore!"
	   ;;
   *) 
           echo "*** VALORE NON IDENTIFICATO ***"
	   echo "Anomalia nel flusso di programma. Esco..." && exit 7
	   ;;
  esac
 else
  mkdir $ROOT_PRJ
 fi

}

if [[ $# -lt $ARGC ]]
then
 echo "ERRORE: numero di argomenti < $ARGC ! Controllare!" && print_help
 exit 1
elif [[ $# -gt $ARGC ]]
then
 echo "ERRORE: numero di argomenti > $ARGC ! Controllare!" && print_help
 exit 1
else 
 echo "Ok, argomenti corretti!"
fi


PROJNAME=$1
SRC_PATH=$2
ROOT_PRJ=$SRC_PATH$PROJNAME
echo "Directory di root del progetto: ..................... $ROOT_PRJ."
read -p "Premere un tasto per continuare... "

read -p "Il progetto e' una applicazione web? [YySs/Nn]"
while [[ ! $LIST =~ $REPLY ]]
do
 echo "Input errato! "
 read -p "Il progetto e' una applicazione web? [YySs/Nn]"
done
case $REPLY in
 [YySs]) ISWEBAPP=0
         echo "Selezionato flag webapp: ISWEBAPP=$ISWEBAPP"
         ;;
 [Nn])   ISWEBAPP=1
         echo "Deselezionato flag webapp: ISWEBAPP=$ISWEBAPP"
         ;;
 *)      echo "ERRORE di flusso! Esco dal programma! " && exit 6
         ;;
esac

check_root_folder_existence

DIRS="build doc output output/backup output/javadoc src utils"
FILES="build.xml utils/build.properties utils/build.number"

cat << EOF
Procedo con la creazione dell'alberatura seguente:

  $ROOT_PRJ
   |- build.xml             --> Script di compilazione ANT
   |- build                 --> Cartella compilazione temporanea
   |- doc                   --> Documentazione generale del programma
   |- output                --> Cartella posizionamento ear/war/jar
       |- javadoc           --> Cartella posizionamento javadoc
       |- backup            --> Archivio vecchie build programma
   |- src                   --> Cartella sorgenti java
   |- utils                 --> Utilita' varie
       |- build.number      --> File di appoggio per build.xml (numero build)
       |- build.properties  --> File di appoggio per build.xml (proprieta' progetto)
EOF

if [[ $ISWEBAPP -eq 0 ]]
then
 cat << EOF
   |- web                   --> Risorse web direttamente accessibili
       |- META-INF          --> Informazioni di contesto
             |- context.xml --> 
       |- WEB-INF           --> Risorse web (non accessibili da esterno)
             |- web.xml     --> Descrittore applicazione web
EOF
 DIRS=$DIRS" web web/META-INF web/WEB-INF"
 FILES=$FILES" web/META-INF/context.xml web/WEB-INF/web.xml"
fi

echo -e "\nMi sposto in $ROOT_PRJ"
cd $ROOT_PRJ || ( echo "ERRORE: cd in $ROOT_PRJ non eseguito!" && exit 5 )


mkdir $DIRS  || exit 3
touch $FILES || exit 4

echo "Alberatura creata, scrivo il build.xml..."

cat > build.xml  << EOF
<!--
################################################################################
                     SCRIPT ANT DI COMPILAZIONE JAVA
Lo script compila un progetto cosi' strutturato:

 - build                -> temporanea di compilazione
 - docs                 -> documentazione generale dell'applicazione
 - output               -> cartella di deploy del jar/war/ear creato
      |- doc            -> documentazione javadoc
      |- backup         -> vecchie build dell'archivio
 - src                  -> sorgenti java ed eventuali file di risorse statiche
 - web                  -> risorse web (html,css,jsp, eventualmente in struttura a directory)
 - web/WEB-INF/         -> risorse statiche, accessibili direttamente. Tra
          |                queste sara' da inserire il file web.xml, con le
          |                direttive xml necessarie per la web application
 -        | - lib/      -> librerie da importare

 Questo build crea un archivio contenente anche la documentazione javadoc
 delle classi
################################################################################
-->

<project name="TestMVC" default="info">
 <taskdef resource="net/sf/antcontrib/antcontrib.properties"/>

 <!-- Definizione dei task del tomcat -->
 <taskdef name="start" classname="org.apache.catalina.ant.StartTask" />
 <taskdef name="stop" classname="org.apache.catalina.ant.StopTask" />
 <taskdef name="deploy" classname="org.apache.catalina.ant.DeployTask" />
 <taskdef name="undeploy" classname="org.apache.catalina.ant.UndeployTask" />
 <!--
 ###############################################################################
                       PROPRIETA DI BASE DEL BUILD
 ###############################################################################
   -->
 <record name="build.log" action="start" append="false" />
 <echo message="Setto le proprieta' di base..." />
 <property name="basedir" value="." />
  <!-- file di properties per il build -->
 <property file="\${basedir}/utils/build.properties" />
 <echo message="Setto la build number..." />
 <buildnumber file="\${basedir}/utils/build.number" />

 <!-- esco nel caso alcune properties non siano impostate -->
 <fail message="Proprieta' app.name non impostate correttamente: controllare
                il file \${basedir}/utils/build.properties">
  <condition>
   <not>
     <isset property="app.name"/>
   </not>
  </condition>
 </fail>

 <fail message="Proprieta' app.version non impostata correttamente: controllare
                il file \${basedir}/utils/build.properties">
  <condition>
   <not>
     <isset property="app.version"/>
   </not>
  </condition>
 </fail>

 <fail message="Proprieta' app.java.archive.type non impostata correttamente: controllare
                il file \${basedir}/utils/build.properties">
  <condition>
   <not>
     <isset property="app.java.archive.type"/>
   </not>
  </condition>
 </fail>

   <!-- impostazione nome nuovo archivio -->
 <property name="app.arc.file" value="\${app.name}.\${app.version}.\${build.number}.\${app.java.archive.type}" />

 <!-- determino se l'applicazione e' un jar o un war e imposto di conseguenza
      una variabile build.folders.temp -->

 <if>
  <equals arg1="war" arg2="\${app.java.archive.type}" />
  <then>
   <echo message="Archivio war, creo cartelle WEB-INF..." />
   <property name="build.folders.temp" value="\${app.folders.compile}/WEB-INF/classes" />
   <property name="build.folders.lib" value="\${app.folders.compile}/WEB-INF/lib" />
  </then>
  <elseif>
   <equals arg1="jar" arg2="\${app.java.archive.type}" />
   <then>
    <echo message="Archivio jar, non creo struttura web application..." />
    <property name="build.folders.temp" value="\${app.folders.compile}/classes" />
    <property name="build.folders.lib" value="\${app.folders.compile}/lib" />
   </then>
  </elseif>
  <else>
   <fail message="Archivio non determinato: \${app.java.archive.type}: ricontrollare!" />
  </else>
 </if>

 <!-- Verifica property app.personal.classpath ed eventuale impostazione
      del classpath di compilazione -->

 <fail message="Proprieta' app.personal.classpath non impostata! Settare a true
                se l'applicazione necessita di un classpath particolare,
                false altrimenti!">
  <condition>
   <not>
     <isset property="app.personal.classpath"/>
   </not>
  </condition>
 </fail>
  <if>
  <equals arg1="true" arg2="\${app.personal.classpath}" />
  <then>
   <echo message="Classpath personale: carico i jar dell'as \${as.name} in \${as.lib.folder}..." />
   <path id="compile.classpath">
    <fileset dir="\${as.lib.folder}" includes="\${as.name}*.jar"/>
   </path>
  </then>
 </if>

 <!--
 ###############################################################################
                            DEFINIZIONE DEI TARGET
 ###############################################################################
   -->

             <!-- Target di build completo dell'applicazione -->
 <target name="all" depends="clean,prepare,compile,archive"
         description="Avvia in sequenza i task del build.xml per la compilazione dell'applicazione"/>


             <!-- Target di pulizia cartelle compilazione -->
 <target name="clean"
         description="Esegue la pulizia delle directory di compilazione temporanea">
  <echo message="Pulizia directory temporanee e javadoc avviata!" />
  <delete dir="\${app.folders.compile}" verbose="true" includeemptydirs="true"/>
  <delete dir="\${app.folders.javadoc}" includeemptydirs="true" />
  <echo message="Pulizia eseguita!" />
 </target>


             <!-- Target di settaggio delle impostazioni pre-compilazioni -->
 <target name="prepare" depends="clean"
         description="Preparazione compilazione">
                   <!-- creo cartella temporanea di compilazione -->
  <echo message="Creo l'alberatura directory per la compilazione..." />
  <mkdir dir="\${build.folders.temp}"/>
  <mkdir dir="\${build.folders.lib}" />
                   <!-- Copio le risorse statiche html, se siamo in una applicazione web -->
  <echo message="Copio risorse statiche..." />
  <if>
   <equals arg1="war" arg2="\${app.java.archive.type}" />
   <then>
    <copy todir="\${app.folders.compile}">
     <fileset dir="\${app.folders.web}"/>
    </copy>
   </then>
  </if>
                   <!-- Includo i jar nelle librerie delle applicazioni -->
  <!--<copy  todir="\${build.home}/WEB-INF/classes">
   <fileset dir="\${src.home}" excludes="**/*.java"/>
  </copy>-->
 </target>


             <!-- Target creazione javadoc -->
 <target name="javadoc" depends="prepare"
         description="Creazione API javadoc">
  <echo message="Creazione documentazione javadoc..." />
    <mkdir dir="\${app.folders.deploy}/docs/api"/>
    <javadoc sourcepath="\${app.folders.src}"
             destdir="\${app.folders.deploy}/docs/api"
             packagenames="*">
      <!--<classpath refid="compile.classpath"/> -->
    </javadoc>
 </target>


             <!-- Target compilazione java -->
 <target name="compile" depends="prepare"
         description="Compilazione sorgenti Java">
    <echo message="Compilazione java avviata!" />
    <javac srcdir="\${app.folders.src}"
          destdir="\${build.folders.temp}"
            debug="\${compile.debug}"
      deprecation="\${compile.deprecation}"
         optimize="\${compile.optimize}"
         includeantruntime="false" >
         <!--<compilerarg arg="-Xbootclasspath/p:\${toString:compile.classpath}"/> -->
         <classpath refid="compile.classpath" />
         </javac>

    <echo message="Compilazione terminata con successo! Avvio la copia delle risorse statiche..." />
    <!-- Copio eventuali file non sorgenti java dell'applicazione -->
    <copy  todir="\${build.folders.temp}">
      <fileset dir="\${app.folders.src}" excludes="**/*.java"/>
    </copy>

  </target>


             <!-- Target creazione archivio -->
 <target name="archive" depends="compile,javadoc"
         description="Generazione archivio jar o war">
  <echo message="Creazione archivio \${app.java.archive.type} nella cartella di backup in corso..." />
  <mkdir   dir="\${app.folders.deploy}/docs"/>
  <copy    todir="\${app.folders.deploy}/docs">
    <fileset dir="\${app.folders.javadoc}"/>
  </copy>

     <!-- Muovo il vecchio file dell'applicazione, se presente -->
  <!-- <move todir="\${app.folders.backup}" failonerror="false">
   <fileset dir="\${app.folders.deploy}">
    <include name="*.*ar" />
   </fileset>
  </move> -->
     <!-- Creo l'archivio jar -->
  <jar jarfile="\${app.folders.backup}/\${app.arc.file}"
       basedir="\${app.folders.compile}"> <!-- build.folders.temp}"> -->
   <fileset dir="\${app.folders.deploy}/docs/" />
   <!--<manifest>
    <attribute name="Main-Class" value="\${app.main.class}"/>
   </manifest> -->
  </jar>
  <!-- Copio il *ar dell'ultima build sulla root della cartella output, pronto
       per il deploy -->
  <echo message="Copio \${app.arc.file} su \${app.folders.deploy}/\${app.name}.\${app.java.archive.type}..." />
  <copy file="\${app.folders.backup}/\${app.arc.file}" tofile="\${app.folders.deploy}/\${app.name}.\${app.java.archive.type}" />
  <echo message="Ok, archivi creati!" />
 </target>

 <!--
 ###############################################################################
                            TARGET APPLICATION SERVER
 ###############################################################################
   -->

          <!-- Stop applicazione -->
 <target name="stop"
         description="stop applicazione"
         depends="archive">
  <echo message="Stop applicazione in corso..." />
  <stop url="\${as.manager.url}"
        username="\${as.manager.user}"
        password="\${as.manager.password}"
        path="/\${app.name}"
        failonerror="false"
        />
 </target>

          <!-- Undeploy applicazione -->
 <target name="undeploy"
         depends="stop"
         description="Disinstallazione applicazione">
  <echo message="Disinstallo la vecchia versione..." />
  <undeploy
   failonerror="no"
   url="\${as.manager.url}"
   username="\${as.manager.user}"
   password="\${as.manager.password}"
   path="/\${app.name}"
  />
 </target>

          <!-- Deploy applicazione -->
 <target name="deploy"
         depends="undeploy"
         description="Installazione applicazione" >
  <echo message="Inizio installazione nuova versione" />
  <deploy
   url="\${as.manager.url}"
   username="\${as.manager.user}"
   password="\${as.manager.password}"
   path="/\${app.name}"
   war="file:\${app.folders.deploy}/\${app.name}.\${app.java.archive.type}"
   failonerror="true"
  />
 </target>

          <!-- Start applicazione -->
 <target name="start"
         depends="deploy"
         description="Start applicazione">
  <echo message="Avvio l'applicazione..." />
  <start url="\${as.manager.url}"
         username="\${as.manager.user}"
         password="\${as.manager.password}"
         path="/\${app.name}"
         failonerror="true"/>
 </target>
<record name="build.log" action="stop"/>
</project>
EOF

echo "Ok, build.xml creato, creo il build.properties..."

cat > utils/build.properties << EOF
################################################################################
################################################################################
################################################################################
#                                                                              #
#                    FILE DI PROPERTIES PER IL BUILD.XML                       #
#                                                                              #
################################################################################
################################################################################
################################################################################

build.number.file=./utils/build.number

## Cartelle del progetto
app.folders.src=./src
app.folders.deploy=./output
app.folders.compile=./build
app.folders.backup=./output/backup
app.folders.web=./web
app.folders.javadoc=./output/docs

## Proprietà applicazione
app.name=$PROJNAME
app.version=0.0.1
app.java.archive.type=war
app.folders.docs=./doc
#app.main.class=

## Opzioni di compilazione
build.debug=true
build.deprecation=false
build.optimize=true
app.personal.classpath=true

## Opzioni application server
as.lib.folder=/usr/share/java/
as.name=tomcat
#as.ftp.server=FTP_SERVER_GOES_HERE
#as.ftp.user=FTP_USERID_GOES_HERE
#as.ftp.password=FTP_PASSWORD_GOES_HERE
as.manager.url=http://localhost:8080/manager/text
as.manager.user=roberto
as.manager.password=tomcat
################################################################################
EOF

echo "Ok, progetto creato. Esco..."

exit 0

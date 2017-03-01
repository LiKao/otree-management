#!/bin/bash

# Definitions of commands

VENV=virtualenv-3.4
OTREE=otree

# General configuration

REDIS_HOST=localhost
REDIS_PORT=6379
MYSQL_HOST=localhost

# User input for study configuration

read -p "Bitte Namen der Studie eingeben: " STUDYNAME
STUDYDIR=$PWD/${STUDYNAME}

LOGFILE=$PWD/${STUDYNAME}.log
PIDFILE=$PWD/${STUDYNAME}.pid

ENVNAME=$PWD/${STUDYNAME}.venv
ENVACTIVATE=${ENVNAME}/bin/activate



read -p "Bitte gewünschtes Administratorpasswort eingeben: " 	ADMIN_PW
read -p "Bitte Redis ID eingeben: " 							REDIS_DB
read -p "Bitte MySQL DB Namen eingeben: " 						MYSQL_DB
read -p "Bitte MySQL Benutzernamen eingeben: " 					MYSQL_USER
read -p "Bitte MySQL Passwort eingeben: " 						MYSQL_PW

read -p "Bitte Portnummer eingeben: " 							PORTNR

# Create venv and switcth to venv

$VENV $ENVNAME

source ${ENVACTIVATE}

# Install software

pip install --upgrade pip
pip install otree-core
pip install mysqlclient

pip freeze > ${STUDYNAME}.pip.txt

# Create oTree project

$OTREE startproject $STUDYNAME

# Create Config file

CONFFILE=$PWD/${STUDYNAME}.conf.sh

echo "#### General authentication and security" 	> $CONFFILE
echo "ADMIN_PASSWORD=$ADMIN_PW" 					>> $CONFFILE
echo ""												>> $CONFFILE
echo "#### Database"								>> $CONFFILE
echo ""												>> $CONFFILE
echo "REDIS_DB=$REDIS_DB"							>> $CONFFILE
echo ""												>> $CONFFILE
echo "MYSQL_DB=$MYSQL_DB"							>> $CONFFILE
echo "MYSQL_USER=$MYSQL_USER"						>> $CONFFILE
echo "MYSQL_PASSWORD=$MYSQL_PW"						>> $CONFFILE
echo ""												>> $CONFFILE
echo "#### Server"									>> $CONFFILE
echo ""												>> $CONFFILE
echo "PORT=$PORTNR"									>> $CONFFILE

# Create resetdb file

RESETDBFILE=${STUDYNAME}_resetdb.sh

echo "#!/bin/bash"									> $RESETDBFILE
echo ""												>> $RESETDBFILE
echo "# Switch to venv"								>> $RESETDBFILE
echo "source $ENVACTIVATE"							>> $RESETDBFILE
echo ""												>> $RESETDBFILE
echo "# Get configuration"							>> $RESETDBFILE
echo "source $CONFFILE"								>> $RESETDBFILE
echo "export DATABASE_URL=mysql://\${MYSQL_USER}:\${MYSQL_PASSWORD}@${MYSQL_HOST}/\${MYSQL_DB}" >> $RESETDBFILE
echo ""												>> $RESETDBFILE
echo "# Reset"										>> $RESETDBFILE
echo "cd $STUDYDIR"									>> $RESETDBFILE
echo "$OTREE resetdb"								>> $RESETDBFILE

chmod +x $RESETDBFILE

# Create demo file

DEMOFILE=${STUDYNAME}_demo.sh

echo "#!/bin/bash"									> $DEMOFILE
echo ""												>> $DEMOFILE
echo "# Switch to venv"								>> $DEMOFILE
echo "source $ENVACTIVATE"							>> $DEMOFILE
echo ""												>> $DEMOFILE
echo "# Get configuration"							>> $DEMOFILE
echo "source $CONFFILE"								>> $DEMOFILE
echo "export OTREE_ADMIN_PASSWORD=\${ADMIN_PASSWORD}" >> $DEMOFILE
echo "export DATABASE_URL=mysql://\${MYSQL_USER}:\${MYSQL_PASSWORD}@${MYSQL_HOST}/\${MYSQL_DB}" >> $DEMOFILE
echo ""												>> $DEMOFILE
echo "# start demo"									>> $DEMOFILE
echo "cd $STUDYDIR"									>> $DEMOFILE
echo "otree runserver 0.0.0.0:\${PORT}"				>> $DEMOFILE

chmod +x $DEMOFILE

# Create actual run file

RUNFILE=${STUDYNAME}_run.sh

echo "#!/bin/bash"									> $RUNFILE
echo ""												>> $RUNFILE
echo "# Switch to venv"								>> $RUNFILE
echo "source $ENVACTIVATE"							>> $RUNFILE
echo ""												>> $RUNFILE
echo "# Get configuration"							>> $RUNFILE
echo "source $CONFFILE"								>> $RUNFILE
echo "export OTREE_ADMIN_PASSWORD=\${ADMIN_PASSWORD}" >> $RUNFILE
echo "export DATABASE_URL=mysql://\${MYSQL_USER}:\${MYSQL_PASSWORD}@${MYSQL_HOST}/\${MYSQL_DB}" >> $RUNFILE
echo "export REDIS_URL=redis://${REDIS_HOST}:${REDIS_PORT}/\${REDIS_DB}" >> $RUNFILE
echo ""												>> $RUNFILE
echo "# Set study mode"								>> $RUNFILE
echo "export OTREE_PRODUCTION=1"					>> $RUNFILE
echo "export OTREE_AUTH_LEVEL=STUDY"				>> $RUNFILE
echo ""												>> $RUNFILE
echo "# Reset"										>> $RUNFILE
echo "cd $STUDYDIR"									>> $RUNFILE
echo "echo Starting $STUDYNAME... "					>> $RUNFILE
echo "nohup otree runprodserver --addr 0.0.0.0 --port \${PORT} >> $LOGFILE 2>&1 &" >> $RUNFILE
echo "echo \$! > $PIDFILE"							>> $RUNFILE
echo "echo Done"									>> $RUNFILE

chmod +x $RUNFILE

# Create stop file

STOPFILE=${STUDYNAME}_stop.sh

echo "#!/bin/bash"									> $STOPFILE
echo ""												>> $STOPFILE
echo "test -e $PIDFILE && kill \$(cat $PIDFILE)"	>> $STOPFILE
echo "test -e $PIDFILE && rm $PIDFILE"				>> $STOPFILE

chmod +x $STOPFILE

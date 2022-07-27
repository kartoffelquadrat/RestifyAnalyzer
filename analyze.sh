## RESTify upload analyzer
## Produces unit test reports for all participants, ready for export
## Maximilian Schiedermeier, 2022
#! /bin/bash

UPLOADDIR=/Users/schieder/Desktop/uploads
BASEDIR=$(pwd)
REPORT=report.txt

function getCodeName
{
    GROUP=$(echo $1 | cut -d '-' -f1)
    ANIMAL=$(echo $1 | cut -d '-' -f2)
    CODENAME=$GROUP-$ANIMAL
}

function analyzeManual
{
	# Red Manual: Xox
	# Green Manual: BookStore
	# Blue Manual: BookStore
	# Yellow Manual: Xox
	case $GROUP in

        	Red )
		MANUAL=XoxInternals
		;;

        	Green )
		MANUAL=BookStoreInternals
		;;

        	Blue )
		MANUAL=BookStoreInternals
		;;

        	Yellow )
		MANUAL=XoxInternals
		;;

	esac

	echo -n "   * Testing $MANUAL... "
	cd $UPLOADDIR

	# Verify upload exists
	if [ ! -d $CODENAME-File-Upload/$MANUAL ]; then
		echo "Upload not found, skipping"	
		echo " * Manual: MISSING" >> $BASEDIR/$REPORT
		
	else
		cd $CODENAME-File-Upload/$MANUAL
		mvn -q clean package spring-boot:run &
		sleep 15
		pkill -9 java
		cd -
		echo OK
	fi
}

function analyzeUpload
{
    getCodeName $1
    echo " > Analyzing $CODENAME"
    cd $BASEDIR
    echo "# $CODENAME" >> $REPORT

    ## Analyze the manual submission
    analyzeManual
}

## Main logic
## Make sure target report file exists and is empty
ORIGIN=$pwd
if [ -f $REPORT ]; then
   rm $REPORT
fi
touch $REPORT

## Run the actual analysis
cd $UPLOADDIR
for i in [A-Z]*; do analyzeUpload $i; done

cd $ORIGIN

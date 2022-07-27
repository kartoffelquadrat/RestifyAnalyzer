## RESTify upload analyzer
## Produces unit test reports for all participants, ready for export
## Maximilian Schiedermeier, 2022
#! /bin/bash

UPLOADDIR=/Users/schieder/Desktop/uploads
BASEDIR=$(pwd)
REPORT=report.txt
XOXTESTDIR=/Users/schieder/Code/XoxStudyRestTest
BSTESTDIR=/Users/schieder/Code/BookStoreRestTest

function getCodeName
{
    GROUP=$(echo $1 | cut -d '-' -f1)
    ANIMAL=$(echo $1 | cut -d '-' -f2)
    CODENAME=$GROUP-$ANIMAL
}

## Individual method testing for all Xox endpoints
function testXox
{
	cd $XOXTESTDIR
        mvn -Dtest=XoxTest#testXoxGet test | grep Time
	mvn -Dtest=XoxTest#testXoxPost test | grep Time
	mvn -Dtest=XoxTest#testXoxIdGet test | grep Time
	mvn -Dtest=XoxTest#testXoxIdDelete test | grep Time
	mvn -Dtest=XoxTest#testXoxIdBoardGet test | grep Time
	mvn -Dtest=XoxTest#testXoxIdPlayersGet test | grep Time
	mvn -Dtest=XoxTest#testXoxIdPlayersIdActionsGet test | grep Time
	cd -
}

function analyzeManual
{
	# Make sure no other programms are blocking the port
	pkill -9 java

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
		mvn -q clean package spring-boot:run & > /dev/null
		RESTPID=$!
		sleep 15
		# check if the program is still running. If not that means it crashed...
		ALIVE=$(ps -ax | grep $! | grep Java)
		# if alive not empty, it is still runing
		if [ -z "$ALIVE" ]; then
                    echo " * Manual: FAILED TO START" >> $BASEDIR/$REPORT
		else
			# kill it anyway, pass on	
			pkill -9 java
			cd -
			## TODO: generate actual success rate report
			testXox
                        echo " * Manual: OK, XX/XX" >> $BASEDIR/$REPORT
		fi
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

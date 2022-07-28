## RESTify upload analyzer
## Produces unit test reports for all participants, ready for export
## Maximilian Schiedermeier, 2022
#! /bin/bash

#set -x
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
## INcase of failure there are two lines with "Time" but only one of them has a leading comma
function testXox
{
	cd $XOXTESTDIR
        TEST1=$(mvn -Dtest=XoxTest#testXoxGet test | grep ', Time')
	echo "     * [GET] /xox $TEST1" >> $BASEDIR/$REPORT
	TEST2=$(mvn -Dtest=XoxTest#testXoxPost test | grep ', Time')
	echo "     * [POST] /xox $TEST2" >> $BASEDIR/$REPORT
	TEST3=$(mvn -Dtest=XoxTest#testXoxIdGet test | grep ', Time')
	echo "     * [GET] /xox/{gameid} $TEST3" >> $BASEDIR/$REPORT
	TEST4=$(mvn -Dtest=XoxTest#testXoxIdDelete test | grep ', Time')
	echo "     * [DELETE] /xox/{gameid} $TEST4" >> $BASEDIR/$REPORT
	TEST5=$(mvn -Dtest=XoxTest#testXoxIdBoardGet test | grep ', Time')
	echo "     * [GET] /xox/{gameid/board $TEST5" >> $BASEDIR/$REPORT
	TEST6=$(mvn -Dtest=XoxTest#testXoxIdPlayersGet test | grep ', Time')
	echo "     * [GET] /xox/{gameid}/players $TEST6" >> $BASEDIR/$REPORT
	TEST7=$(mvn -Dtest=XoxTest#testXoxIdPlayersIdActionsGet test | grep ', Time')
	echo "     * [GET] /xox/{gameid}/actions $TEST7" >> $BASEDIR/$REPORT
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
		mvn -q clean package spring-boot:run > /tmp/output 2>&1 &
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
			## TODO: generate actual success rate report, depending on which program was used
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

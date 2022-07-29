## RESTify upload analyzer
## Produces unit test reports for all participants, ready for export
## Maximilian Schiedermeier, 2022
#! /bin/bash

#set -x
UPLOADDIR=/Users/schieder/Desktop/uploads
BASEDIR=$(pwd)
REPORT=report.md
XOXTESTDIR=/Users/schieder/Code/XoxStudyRestTest
BSTESTDIR=/Users/schieder/Code/BookStoreRestTest

function getCodeName
{
    GROUP=$(echo $1 | cut -d '-' -f1)
    ANIMAL=$(echo $1 | cut -d '-' -f2)
    CODENAME=$GROUP-$ANIMAL
}

## Generates a markdinw anchor to the corresponding participant entry
function generateHotlink
{
    getCodeName $1
    LC_CODENAME=$(echo $CODENAME | tr '[:upper:]' '[:lower:]')
    echo " * [$CODENAME](#$LC_CODENAME)" >> $BASEDIR/$REPORT
}

## Individual method testing for all Xox endpoints
## In case of failure there are two lines with "Time" but only one of them has a leading comma
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

## Individual method testing for all BookStore endpoints
## In case of failure there are two lines with "Time" but only one of them has a leading comma
function testBookStore
{
	cd $BSTESTDIR

        TEST1=$(mvn -Dtest=AssortmentTest#testIsbnsGet test | grep ', Time')
	echo "     * [GET]  /bookstore/isbns $TEST1" >> $BASEDIR/$REPORT-tmp
	TEST2=$(mvn -Dtest=AssortmentTest#testIsbnsIsbnGet test | grep ', Time')
	echo "     * [GET]  /bookstore/isbns/{isbn} $TEST2" >> $BASEDIR/$REPORT-tmp
	TEST3=$(mvn -Dtest=AssortmentTest#testIsbnsIsbnPut test | grep ', Time')
	echo "     * [PUT]  /bookstore/isbns/{isbn} $TEST3" >> $BASEDIR/$REPORT-tmp

	TEST4=$(mvn -Dtest=StockLocationsTest#testStocklocationsGet test | grep ', Time')
	echo "     * [GET]  /bookstore/stocklocations $TEST4" >> $BASEDIR/$REPORT-tmp
	TEST5=$(mvn -Dtest=StockLocationsTest#testStocklocationsStocklocationGet test | grep ', Time')
	echo "     * [GET]  /bookstore/stocklocations/{location} $TEST5" >> $BASEDIR/$REPORT-tmp
	TEST6=$(mvn -Dtest=StockLocationsTest#testStocklocationsStocklocationIsbnsGet test | grep ', Time')
	echo "     * [GET]  /bookstore/stocklocations/{location}/isbns $TEST6" >> $BASEDIR/$REPORT-tmp
	TEST7=$(mvn -Dtest=StockLocationsTest#testStocklocationsStocklocationIsbnsPost test | grep ', Time')
	echo "     * [POST] /bookstore/stocklocations/{location}/isbns $TEST7" >> $BASEDIR/$REPORT-tmp

	TEST8=$(mvn -Dtest=CommentsTest#testIsbnsIsbnCommentsGet test | grep ', Time')
	echo "     * [GET]  /bookstore/isbns/{isbn}/comments $TEST8" >> $BASEDIR/$REPORT-tmp
	TEST9=$(mvn -Dtest=CommentsTest#testIsbnsIsbnCommentsPost test | grep ', Time')
	echo "     * [POST] /bookstore/isbns/{isbn}/comments $TEST9" >> $BASEDIR/$REPORT-tmp
	TEST10=$(mvn -Dtest=CommentsTest#testIsbnsIsbnCommentsDelete test | grep ', Time')
	echo "     * [DEL]  /bookstore/isbns/{isbn}/comments $TEST10" >> $BASEDIR/$REPORT-tmp
	TEST11=$(mvn -Dtest=CommentsTest#testIsbnsIsbnCommentsCommentPost test | grep ', Time')
	echo "     * [POST] /bookstore/isbns/{isbn}/comments/{commentid} $TEST11" >> $BASEDIR/$REPORT-tmp
	TEST12=$(mvn -Dtest=CommentsTest#testIsbnsIsbnCommentsCommentDelete test | grep ', Time')
	echo "     * [DEL]  /bookstore/isbns/{isbn}/comments/{commentid} $TEST11" >> $BASEDIR/$REPORT-tmp
	cd -
}

function analyzeCodes
{

	# Red Manual: Xox
	# Green Manual: BookStore
	# Blue Manual: BookStore
	# Yellow Manual: Xox
	case $GROUP in

        	Red )
		MANUAL=XoxInternals
		ASSISTED=BookStoreModel
		;;

        	Green )
		MANUAL=BookStoreInternals
                ASSISTED=XoxModel
		;;

        	Blue )
		MANUAL=BookStoreInternals
                ASSISTED=XoxModel
		;;

        	Yellow )
		MANUAL=XoxInternals
                ASSISTED=BookStoreModel
		;;

	esac

	echo  "   * Testing $MANUAL... "
	cd $UPLOADDIR

	# Verify upload exists
	if [ ! -d $CODENAME-File-Upload/$MANUAL ]; then
		echo "Upload not found, skipping"	
		echo " * Manual: MISSING" >> $BASEDIR/$REPORT
		
	else
	        # Make sure no other programs are blocking the port
	        pkill -9 java
		cd $CODENAME-File-Upload/$MANUAL
		mvn -q clean package spring-boot:run > /tmp/output 2>&1 &
		RESTPID=$!
		sleep 15
		# check if the program is still running. If not that means it crashed...
		ALIVE=$(ps -ax | grep $! | grep Java)
		# if alive not empty, it is still running
		if [ -z "$ALIVE" ]; then
                    echo " * Manual: NOT RUNNABLE" >> $BASEDIR/$REPORT
		else
			## Program is running, let's test the individual endpoints
			## Red and Yellow -> Xox
			## Green and Blue -> BookStore
 			
			case $GROUP in

        			Red )
				testXox
	                        echo " * Manual: RUNNABLE, Tests passed: XX/XX" >> $BASEDIR/$REPORT
                                cat $BASEDIR/$REPORT-tmp >> $BASEDIR/$REPORT
				;;

    		    	Green )
				testBookStore
	                        echo " * Manual: RUNNABLE, Tests passed: XX/XX" >> $BASEDIR/$REPORT
                                cat $BASEDIR/$REPORT-tmp >> $BASEDIR/$REPORT
				;;

  		      	Blue )
				testBookStore
	                        echo " * Manual: RUNNABLE, Tests passed: XX/XX" >> $BASEDIR/$REPORT
                                cat $BASEDIR/$REPORT-tmp >> $BASEDIR/$REPORT
				;;

     		   	Yellow )
				testXox
	                        echo " * Manual: RUNNABLE, Tests passed: XX/XX" >> $BASEDIR/$REPORT
                                cat $BASEDIR/$REPORT-tmp >> $BASEDIR/$REPORT
				;;

			esac

		fi

		# kill running program, pass on
		pkill -9 java
		cd -
	fi
}

function analyzeUpload
{
    getCodeName $1
    echo " > Analyzing $CODENAME"
    cd $BASEDIR
    echo "" >> $REPORT
    echo "## $CODENAME" >> $REPORT
    echo "" >> $REPORT

    ## Analyze the manual submission
    analyzeCodes
}

## Main logic
## Make sure target report file exists and is empty
ORIGIN=$pwd
if [ -f $REPORT ]; then
   rm $REPORT
fi
touch $REPORT
echo "# RESTify Study - Unit Test Report" >> $REPORT

## Generate hotlinks
cd $UPLOADDIR
for i in [A-Z]*; do generateHotlink $i; done

## Run the actual analysis
for i in [A-Z]*; do analyzeUpload $i; done

cd $ORIGIN

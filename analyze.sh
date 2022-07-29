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

## Analyzes the last three characters of a provided string and inferes the corresponding CRUD http method.
function extractMethod
{
   METHOD=$(echo $1 | rev | cut -c -3 | rev)
   if [ "$METHOD" = "ost" ] ;then
     METHOD="Post"
   fi
   if [ "$METHOD" = "ete" ] ;then
     METHOD="Del"
   fi
   METHOD='['$METHOD']'
   METHOD=$( printf '%-6s' $METHOD)
}

function extractResource
{
    RESOURCE=$(echo $1 | sed s/Get// | sed s/Put// | sed s/Post// | sed s/Delete//)
    RESOURCE=$(echo $RESOURCE | cut -d "#" -f 2)
    RESOURCE=$(echo $RESOURCE | sed s/test//)
    RESOURCE=$( printf '%-40s' $RESOURCE)
}

function testEndpoint
{
   RESULT=$(mvn -Dtest=$1 test | grep ', Time' | cut -d ":" -f 6)
   extractMethod $1
   extractResource $1
   echo "$METHOD $RESOURCE $RESULT" >> $BASEDIR/$REPORT-tmp
}

## Individual method testing for all Xox endpoints
## In case of failure there are two lines with "Time" but only one of them has a leading comma
function testXox
{
	cd $XOXTESTDIR
        echo "\`\`\`"  > $BASEDIR/$REPORT-tmp
        testEndpoint XoxTest#testXoxGet
	testEndpoint XoxTest#testXoxPost
	testEndpoint XoxTest#testXoxIdGet
	testEndpoint XoxTest#testXoxIdDelete
	testEndpoint XoxTest#testXoxIdBoardGet
	testEndpoint XoxTest#testXoxIdPlayersGet
	testEndpoint XoxTest#testXoxIdPlayersIdActionsGet
## TODO: Figure out why action post is missing
        echo "\`\`\`"  >> $BASEDIR/$REPORT-tmp
	cd -
}

## Individual method testing for all BookStore endpoints
## In case of failure there are two lines with "Time" but only one of them has a leading comma
function testBookStore
{
	cd $BSTESTDIR
        echo "\`\`\`"  > $BASEDIR/$REPORT-tmp
        testEndpoint AssortmentTest#testIsbnsGet
	testEndpoint AssortmentTest#testIsbnsIsbnGet
	testEndpoint AssortmentTest#testIsbnsIsbnPut
	testEndpoint StockLocationsTest#testStocklocationsGet
	testEndpoint StockLocationsTest#testStocklocationsStocklocationGet
	testEndpoint StockLocationsTest#testStocklocationsStocklocationIsbnsGet
	testEndpoint StockLocationsTest#testStocklocationsStocklocationIsbnsPost
	testEndpoint CommentsTest#testIsbnsIsbnCommentsGet
	testEndpoint CommentsTest#testIsbnsIsbnCommentsPost
	testEndpoint CommentsTest#testIsbnsIsbnCommentsDelete
	testEndpoint CommentsTest#testIsbnsIsbnCommentsCommentPost
	testEndpoint CommentsTest#testIsbnsIsbnCommentsCommentDelete
        echo "\`\`\`"  >> $BASEDIR/$REPORT-tmp
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

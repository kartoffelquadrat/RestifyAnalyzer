## RESTify upload analyzer
## Produces unit test reports for all participants, ready for export
## Maximilian Schiedermeier, 2022
#! /bin/bash

set -x
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

## Generates a markdown anchor to the corresponding participant entry
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
    RESOURCE=$(echo $RESOURCE | sed s/test// | sed -r -e "s/([^A-Z])([A-Z])/\1\/\2/g")
    RESOURCE=$(echo $RESOURCE | tr '[:upper:]' '[:lower:]')
    RESOURCE=/$2/$RESOURCE
    RESOURCE=$( printf '%-48s' $RESOURCE)
}

function testEndpoint
{
   RESULT=$(mvn -Dtest=$1 test | grep ', Time' | cut -d ":" -f 6)
   extractMethod $1
   extractResource $1 $2
   echo "$METHOD $RESOURCE $RESULT" >> $BASEDIR/$REPORT-tmp
}

## Individual method testing for all Xox endpoints
## In case of failure there are two lines with "Time" but only one of them has a leading comma
function testXox
{
	cd $XOXTESTDIR
        echo "\`\`\`"  > $BASEDIR/$REPORT-tmp
        testEndpoint XoxTest#testXoxGet xox
	testEndpoint XoxTest#testXoxPost xox
	testEndpoint XoxTest#testXoxIdGet xox
	testEndpoint XoxTest#testXoxIdDelete xox
	testEndpoint XoxTest#testXoxIdBoardGet xox
	testEndpoint XoxTest#testXoxIdPlayersGet xox
	testEndpoint XoxTest#testXoxIdPlayersIdActionsGet xox
	testEndpoint XoxTest#testXoxIdPlayersIdActionsPost xox
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
        testEndpoint AssortmentTest#testIsbnsGet bookstore
	testEndpoint AssortmentTest#testIsbnsIsbnGet bookstore
	testEndpoint AssortmentTest#testIsbnsIsbnPut bookstore
	testEndpoint StockLocationsTest#testStocklocationsGet bookstore
	testEndpoint StockLocationsTest#testStocklocationsStocklocationGet bookstore
	testEndpoint StockLocationsTest#testStocklocationsStocklocationIsbnsGet bookstore
	testEndpoint StockLocationsTest#testStocklocationsStocklocationIsbnsPost bookstore
	testEndpoint CommentsTest#testIsbnsIsbnCommentsGet bookstore
	testEndpoint CommentsTest#testIsbnsIsbnCommentsPost bookstore
	testEndpoint CommentsTest#testIsbnsIsbnCommentsDelete bookstore
	testEndpoint CommentsTest#testIsbnsIsbnCommentsCommentPost bookstore
	testEndpoint CommentsTest#testIsbnsIsbnCommentsCommentDelete bookstore
        echo "\`\`\`"  >> $BASEDIR/$REPORT-tmp
	cd -
}

## Inspects the most recent report tmp file and computes the success ratio
function computeSuccessRatio
{
	TOTAL=$(cat $BASEDIR/$REPORT-tmp | grep -v \` | wc -l)
	SUCCESS=$(cat $BASEDIR/$REPORT-tmp | grep -v \` | grep -v FAILURE | wc -l)
	RATIO=$SUCCESS/$TOTAL
}

function analyzeCode
{
	# Verify upload exists
	if [ ! -d $CODENAME-File-Upload/$1 ]; then
		echo "Upload not found, skipping"	
		echo " * Manual: MISSING" >> $BASEDIR/$REPORT
		
	else
	        # Make sure no other programs are blocking the port
	        pkill -9 java
		cd $CODENAME-File-Upload/$1
		## Try to compile, skip all tests (some users did not delete them)
                mvn -q clean package -Dmaven.test.skip=true > /tmp/output 2>&1
                COMPILABLE=$?

		## if it did not compile, mark as uncompilable and proceed to next
                if [ ! "$COMPILABLE" == 0 ]; then
                        # Not compilable. Flag and proceed
			echo " * $2: NOT COMPILABLE" >> $BASEDIR/$REPORT
                else
			# Compilable, lets try to actually run and test it
			JARFILE=$(find . | grep jar | grep -v javadoc | grep -v sources | grep -v original | grep -v xml)
			echo $JARFILE
			#java -jar $JARFILE > /tmp/output 2>&1 &
			java -jar $JARFILE &
			RESTPID=$!
			sleep 15
			# check if the program is still running. If not that means it crashed...
			ALIVE=$(ps -ax | grep $! | grep java)
			# if alive not empty, it is still running
			if [ -z "$ALIVE" ]; then
			    echo " * $2: NOT RUNNABLE" >> $BASEDIR/$REPORT
			else
				## Program is running, let's test the individual endpoints (depending on what it is)
				APP=$(echo $1 | cut -c -1)
				if [ "$APP" = "X" ]; then
				    testXox
				else
				    testBookStore
				fi
				computeSuccessRatio
				echo " * $2: RUNNABLE, Tests passed: $RATIO" >> $BASEDIR/$REPORT
				cat $BASEDIR/$REPORT-tmp >> $BASEDIR/$REPORT
			fi

			# kill running program, pass on
			pkill -9 java
		fi
                 
		cd -
	fi
}
function analyzeBothCodes
{

	# Red Manual: Xox
	# Green Manual: BookStore
	# Blue Manual: BookStore
	# Yellow Manual: Xox
	case $GROUP in

        	Red )
		MANUAL=XoxInternals
		ASSISTED=BookStoreModel/generated-maven-project
		;;

        	Green )
		MANUAL=BookStoreInternals
                ASSISTED=XoxModel/generated-maven-project
		;;

        	Blue )
		MANUAL=BookStoreInternals
                ASSISTED=XoxModel/generated-maven-project
		;;

        	Yellow )
		MANUAL=XoxInternals
                ASSISTED=BookStoreModel/generated-maven-project
		;;

	esac

	cd $UPLOADDIR
	echo  "   * Testing $ASSISTED "
        analyzeCode $ASSISTED Assisted

	cd $UPLOADDIR
	echo  "   * Testing $MANUAL "
        analyzeCode $MANUAL Manual
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
    analyzeBothCodes
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

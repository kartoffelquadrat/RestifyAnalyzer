#! /bin/bash
## RESTify upload analyzer
## Produces unit test reports for all participants, ready for export
## Maximilian Schiedermeier, 2022

#set -x
UPLOADDIR=/Users/schieder/Desktop/uploads
BASEDIR=$(pwd)
REPORT=report.md
CSVREPORT=tests.csv
XOXTESTDIR=/Users/schieder/Code/XoxStudyRestTest
BSTESTDIR=/Users/schieder/Code/BookStoreRestTest

function getCodeName {
  GROUP=$(echo "$1" | cut -d '-' -f1)
  ANIMAL=$(echo "$1" | cut -d '-' -f2)
  CODENAME=$GROUP-$ANIMAL
}

## Generates a markdown anchor to the corresponding participant entry
function generateHotlink {
  getCodeName "$1"
  LC_CODENAME=$(echo "$CODENAME" | tr '[:upper:]' '[:lower:]')
  echo " * [$CODENAME](#$LC_CODENAME)" >>"$BASEDIR/$REPORT"
}

## Analyzes the last three characters of a provided string and inferes the corresponding CRUD http method.
function extractMethod {
  METHOD=$(echo "$1" | rev | cut -c -3 | rev)
  if [ "$METHOD" = "ost" ]; then
    METHOD="Post"
  fi
  if [ "$METHOD" = "ete" ]; then
    METHOD="Del"
  fi
  METHOD='['$METHOD']'
  METHOD=$(printf '%-6s' "$METHOD")
}

function extractResource {
  RESOURCE=$(echo "$1" | sed s/Get// | sed s/Put// | sed s/Post// | sed s/Delete//)
  RESOURCE=$(echo "$RESOURCE" | cut -d "#" -f 2)
  RESOURCE=$(echo "$RESOURCE" | sed s/test// | sed -r -e "s/([^A-Z])([A-Z])/\1\/\2/g")
  RESOURCE=$(echo "$RESOURCE" | tr '[:upper:]' '[:lower:]')
  RESOURCE="/$2/$RESOURCE"
  RESOURCE=$(printf '%-48s' "$RESOURCE")
}

function testEndpoint {
  RESULT=$(mvn -Dtest="$1" test | grep ', Time' | cut -d ":" -f 6)
  extractMethod "$1"
  extractResource "$1" "$2"

  # append line for markdown report into temporary file
  echo "$METHOD $RESOURCE $RESULT" >>"$BASEDIR/$REPORT-tmp"

  # append string for CSV report into temporary file
  if [[ "$RESULT" == *"FAILURE"* ]]; then
    echo -n ",FAIL" >>"$BASEDIR/$CSVREPORT-indiv"
  else
    echo -n ",PASS" >>"$BASEDIR/$CSVREPORT-indiv"
  fi
}

## Individual method testing for all Xox endpoints
## In case of failure there are two lines with "Time" but only one of them has a leading comma
function testXox {

  # test all xox endpoints
  cd $XOXTESTDIR || exit
  echo "\`\`\`" >"$BASEDIR/$REPORT-tmp"
  testEndpoint XoxTest#testXoxGet xox
  testEndpoint XoxTest#testXoxPost xox
  testEndpoint XoxTest#testXoxIdGet xox
  testEndpoint XoxTest#testXoxIdDelete xox
  testEndpoint XoxTest#testXoxIdBoardGet xox
  testEndpoint XoxTest#testXoxIdPlayersGet xox
  testEndpoint XoxTest#testXoxIdPlayersIdActionsGet xox
  testEndpoint XoxTest#testXoxIdPlayersIdActionsPost xox
  echo "\`\`\`" >>"$BASEDIR/$REPORT-tmp"
  cd - || exit
}

## Individual method testing for all BookStore endpoints
## In case of failure there are two lines with "Time" but only one of them has a leading comma
function testBookStore {
  # reset test reports
  rm "$BASEDIR/$REPORT-indiv"
  rm "$BASEDIR/$REPORT-tmp"

  # test all bookstore endpoints
  cd $BSTESTDIR || exit
  echo "\`\`\`" >"$BASEDIR/$REPORT-tmp"
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
  echo "\`\`\`" >>"$BASEDIR/$REPORT-tmp"
  cd - || exit
}

## Inspects the most recent report tmp file and computes the success ratio
function computeSuccessRatio {
  # TODO: get rid of CAT
  TOTAL=$(grep -v \` "$BASEDIR/$REPORT-tmp" -c)
  SUCCESS=$(grep -v \` "$BASEDIR/$REPORT-tmp" | grep -v FAILURE -c)
  RATIO="$SUCCESS/$TOTAL"
}

function analyzeCode {
  # Determine which app was actually tested
  # Set default outcome for test report to nothing passed:
  if [[ "$1" == *"Xox"* ]]; then
    APP="xox"
    echo -n ",FAIL,FAIL,FAIL,FAIL,FAIL,FAIL,FAIL,FAIL" >"$BASEDIR/X-$CSVREPORT"
    echo "Stored default fail vector in $BASEDIR/$APP-$CSVREPORT"
  elif [[ "$1" == *"BookStore"* ]]; then
    APP="bookstore"
    echo -n ",FAIL,FAIL,FAIL,FAIL,FAIL,FAIL,FAIL,FAIL,FAIL,FAIL,FAIL,FAIL" >"$BASEDIR/B-$CSVREPORT"
    echo "Stored default fail vector in $BASEDIR/$APP-$CSVREPORT"
  else
    echo "Unknown app: $1"
    exit 255
  fi

  # Verify upload exists
  if [ ! -d "$CODENAME-File-Upload/$1" ]; then
    echo "Upload not found, skipping"
    echo " * Manual: MISSING" >>"$BASEDIR/$REPORT"

  else

    # Make sure no other programs are blocking the port
    pkill -9 java
    cd "$CODENAME-File-Upload/$1" || exit

    # Store all detected spring mappings in a dedicated file
    grep -nre @ src -A 2 | grep Mapping -A 2 >"$BASEDIR/$CODENAME-$2.txt"

    ## Try to compile, skip all tests (some users did not delete them)
    mvn -q clean package -Dmaven.test.skip=true >/tmp/output 2>&1
    COMPILABLE=$?

    ## if it did not compile, mark as uncompilable and proceed to next
    if [ ! "$COMPILABLE" == 0 ]; then
      # Not compilable. Flag and proceed
      echo " * [$2: NOT COMPILABLE]($BASEDIR/$CODENAME-$2.txt)" >>"$BASEDIR/$REPORT"
      echo -n "NC,0" >>"$BASEDIR/$CSVREPORT"
    else
      # Compilable, lets try to actually run and test it
      JARFILE=$(find . | grep jar | grep -v javadoc | grep -v sources | grep -v original | grep -v xml)
      echo "$JARFILE"

      java -jar "$JARFILE" &
      #			RESTPID=$!
      sleep 15

      # check if the program is still running (still a running java process). If not that means it crashed...
      ALIVE=$(pgrep java)

      # if alive not empty, it is still running
      if [ -z "$ALIVE" ]; then
        echo " * [$2: NOT RUNNABLE]($BASEDIR/$CODENAME-$2.txt)" >>"$BASEDIR/$REPORT"
        echo -n "NR,0" >>"$BASEDIR/$CSVREPORT"
      else

        ## Program is running, let's test the individual endpoints (depending on what it is)
        APP=$(echo "$1" | cut -c -1)
        if [ "$APP" = "X" ]; then
          testXox
        else
          testBookStore
        fi
        computeSuccessRatio
        echo " * [$2: RUNNABLE, Tests passed: $RATIO]($BASEDIR/$CODENAME-$2.txt)" >>"$BASEDIR/$REPORT"
        echo -n "OK,${RATIO// /}" >>"$BASEDIR/$CSVREPORT"
        cat "$BASEDIR/$REPORT-tmp" >>"$BASEDIR/$REPORT"

        # rename CSV file with individual tests according to tested app
        mv "$BASEDIR/$CSVREPORT-indiv" "$BASEDIR/$APP-$CSVREPORT"
      fi

      # kill running program, pass on
      pkill -9 java

    fi

    cd - || exit
  fi
}

function prepareCsv {
  echo "codename,assistedstatus,assistedsuccessrate,manualstatus,manualsuccessrate,GET/xox,POST/xox,GET/xox/id,DEL/xox/id,GET/xox/id/board,GET/xox/id/players,GET/xox/id/players/id/actions,POST/xox/id/players/id/actions,GET/bookstore/isbns,GET/bookstore/isbns/isbn,PUT/bookstore/isbns/isbn,GET/bookstore/stocklocations,GET/bookstore/stocklocations/stocklocation,GET/bookstore/stocklocations/stocklocation/isbns,POST/bookstore/stocklocations/stocklocation/isbns,GET/bookstore/isbns/isbn/comments,POST/bookstore/isbns/isbn/comments,DEL/bookstore/isbns/isbn/comments,POST/bookstore/isbns/isbn/comments/comment,DEL/bookstore/isbns/isbn/comments/comment" >$CSVREPORT
}

function analyzeBothCodes {

  # Red Manual: Xox
  # Green Manual: BookStore
  # Blue Manual: BookStore
  # Yellow Manual: Xox
  case $GROUP in

  Red)
    MANUAL=XoxInternals
    ASSISTED=BookStoreModel/generated-maven-project
    ;;

  Green)
    MANUAL=BookStoreInternals
    ASSISTED=XoxModel/generated-maven-project
    ;;

  Blue)
    MANUAL=BookStoreInternals
    ASSISTED=XoxModel/generated-maven-project
    ;;

  Yellow)
    MANUAL=XoxInternals
    ASSISTED=BookStoreModel/generated-maven-project
    ;;

  esac

  # Test the assisted restified app
  cd $UPLOADDIR || exit
  echo "   * Testing $ASSISTED "
  analyzeCode $ASSISTED Assisted
  echo -n ',' >>"$BASEDIR/$CSVREPORT"

  # Test the manually restified app
  cd $UPLOADDIR || exit
  echo "   * Testing $MANUAL "
  analyzeCode $MANUAL Manual

  # Add individual test reports to CSV
  {
    cat "$BASEDIR/X-$CSVREPORT"
    cat "$BASEDIR/B-$CSVREPORT"
  } >>"$BASEDIR/$CSVREPORT"

  # Append newline, prepare for next submission test
  echo '' >>"$BASEDIR/$CSVREPORT"
}

function analyzeUpload {
  getCodeName "$1"
  echo " > Analyzing $CODENAME"
  cd "$BASEDIR" || exit
  echo "" >>$REPORT
  echo "## $CODENAME" >>"$REPORT"
  echo "" >>"$REPORT"

  ## write codename into CSV target file
  echo -n "$CODENAME" >>"$BASEDIR/$CSVREPORT"
  echo -n ',' >>"$BASEDIR/$CSVREPORT"

  ## Analyze the manual submission
  analyzeBothCodes
}

## Main logic
## Clear files of previous iterations
rm ./*txt
rm ./*csv
rm report*

## Make sure target report file exists and is empty
ORIGIN=$(pwd)
echo "# RESTify Study - Unit Test Report" >$REPORT

prepareCsv

## Generate hotlinks
cd $UPLOADDIR || exit
for i in [A-Z]*; do generateHotlink "$i"; done

## Run the actual analysis
for i in [A-Z]*; do analyzeUpload "$i"; done

# Clear temp files
rm X-*
rm B-*

cd "$ORIGIN" || exit

# Print success message
echo "Done! The CSV with detailed tests results is: $CSVREPORT"

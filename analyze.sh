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

function analyzeUpload
{
    getCodeName $1
    echo "Analyzing $CODENAME"
    cd $BASEDIR
    echo "# $CODENAME" >> $REPORT
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

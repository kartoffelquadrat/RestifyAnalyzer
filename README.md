# RESTify Analyzer

Automated testing for all RESTify study submissions.

## About

The RESTify study produces 28 submissions with two restful services each. A manual inspection is overly time intense and error prone. This repository hosts a script to automatically test all submissions and generate test reports.

## Usage

 * Call: ```analyze.sh```, wait for script to finish
   * Submissions must be in ```~/Desktop/uploads/{Colour}-{Animal}-File-Upload/[BookStoreModel|XoxModel|BookStoreInternals|XoxInternals]
 * Inspect test reports
   * CSV file: [stats.csv] (consumed as source csv file by [RestifyJupyter](https://github.com/kartoffelquadrat/RestifyJupyter) project. Place output file at ```RestifyJupyter/source-csv-files/tests.csv```)
   * Markdown report: [report.md](report.md) (includes hotlinks to relevat code snippets per submission.)

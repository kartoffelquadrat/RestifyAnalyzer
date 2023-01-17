# RESTify Analyzer

Automated reliable testing of RESTify experiment submissions.

## About

This software is a tool written specifically for analysis of the data acquired throughout the RESTify experiment.

 * The RESTify experiment produced 28 participant submissions with two restful services each.  
 * A manual inspection is overly time intense and errorprone.
 * This repository [hosts a bash script](analyze.sh) that automatically test all submissions and generate test reports in a reliable manner.

## Procedure

### Main Double Iterations

* In default configueation, the script preforms a single loop over all participant folders. Every iteration runs all unit tests for each of the two submitted applications.
  * If no additional parameters are provided, the script does not verify the effectiveness of write operations by means of a subsequent read operation. This is to reduce test cross dependencies between the individual REST API endpoints.
  * Using the ```-v``` flag, the tests can ba hardened to only evaluate to positivie, if state changes of write requests can be confirmend by subsequent read requiests. See [Usage Section](#usage) 

 > Note: The scenario of a successful *Write*, and unsuccessful *Read* validation is very rare. It is recommended to investigate these cases manually, to exclude possibility of a false-positive *Write*.

### True State Reset

Every test is executed in perfect isolation, that is to say every individual unit test run is preceeded by a comlete application restart. This eliminates any effects that stem from blemished test results due to corrupted initial service state (e.g. caused by failed earlier test).

## Usage

### Script Dependencies

 * Install the ```realpath``` command: ```brew install coreutils```
 * Create a ```Code``` directory in your homedir, clone these four repos:
     * ```https://github.com/m5c/XoxStudyRestTest
     * ```git clone https://github.com/m5c/BookStoreRestTest```
     * ```git clone https://github.com/m5c/BookStoreInternals```
     * ```git clone https://github.com/m5c/XoxInternals```
 * Locally install the Internals packages:
    * ```cd XoxInternals; mvn clean install; cd ..```
    * ```cd BookStoreInternals; mvn clean install; cd ..```


### Running the script

 * Get hold of the original study source code submissions: ```submission.zip```  
(Source code of the two RESTful services produced by every RESTify study participant).  
 > Note: For participant anonymity compliance reasons the participant source code submissions cannot be published here. [Contact the authors](#authors) if you need to reproduce the unit tests results.
 * Unzip the ```submissions.zip```, make sure the ```UPLOADDIR``` variable correctly references the submissions source codes.
 * Clone the sources the two REST application test scenarios.  
Update the corresponding ```XOXTESTDIR``` and ```BSTESTDIR``` variables to match the location.
    * [BookStore REST Tests](https://github.com/m5c/BookStoreRestTest) on GitHub
    * [Xox REST Tests](https://github.com/m5c/XoxStudyRestTest) on GitHub
 * Call: ```./analyze.sh```, wait for script to finish. (May take several hours)  
Command line options:
   * ```-h```: Print help message with further usage information
   * ```-d```: Run in debug mode (print all intermediate results)
   * ```v```: Enable read verfication for write operations.  only considered as successful, if the state change if the initial write operation is reflected in the read result. By default this option is disabled.
 This option is by default disabled.
   *  ```-u Colour-Animal```:  Reduce test scope to a single study submission. Name of the target participant code name must be provided, e.g. Pink-Snail
 * Inspect the test reports
   * CSV file for further scripted visualizations: *report-folder*/tests.csv  
This file is consumed as input data by the [RestifyJupyter](https://github.com/m5c/RestifyJupyter) project.
   * Human-readable markdown report: *report-folder*/report.md
 This file also contains hotlinks to relevant code snippets, in case a subsequent manual inspection is required.

## Development

Use IntelliJ IDEA, make sure to enable the [Shell Script](https://plugins.jetbrains.com/plugin/13122-shell-script) plugin.  
This provides automatic execution of the [Shell Check](https://www.shellcheck.net/) static code linter and enforces a minimum of code style and readability.

## Authors

* Principal Investigator: [Maximilian Schiedermeier](https://www.cs.mcgill.ca/~mschie3/)
* Academic Supervisors: [Bettina Kemme](https://www.cs.mcgill.ca/~kemme/), [Jörg Kienzle](https://www.cs.mcgill.ca/~joerg/Home/Jorgs_Home.html)
* Implementation: [Maximilian Schiedermeier](https://github.com/m5c)
   * Study Instructions, by control group:
      * [Red](https://www.cs.mcgill.ca/~mschie3/red/restify-study/)
      * [Green](https://www.cs.mcgill.ca/~mschie3/green/restify-study/)
      * [Blue](https://www.cs.mcgill.ca/~mschie3/blue/restify-study/)
      * [Yellow](https://www.cs.mcgill.ca/~mschie3/yellow/restify-study/)
   * Legacy Application Source Code:
      * [BookStore](https://github.com/m5c/BookStoreInternals/tree/RESTifyStudy)
      * [Zoo](https://github.com/m5c/Zoo/tree/RESTifyStudy)
      * [Xox](https://github.com/m5c/XoxInternals/tree/RESTifyStudy)
   * Submission REST unit test scenarios:
     * [BookStore REST Tests](https://github.com/m5c/BookStoreRestTest)
     * [Xox REST Tests](https://github.com/m5c/XoxStudyRestTest)
   * Jupyter Notebook for full study analysis and description: [RestifyAnalyzer](https://github.com/m5c/RestifyAnalyzer)
* Research Ethics Board Advisor: Lynda McNeil
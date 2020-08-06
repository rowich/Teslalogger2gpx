# Teslalogger2gpx
 Extract GPS trip data from the Teslalogger database and convert to GPX file format
 
 v0.1 - very first initial release
 
 code is based on Powershell (tested with Windows 10/2004 builtin Powershell v5.x [non Core])
 
 use "Extract-Teslalogger-GPX.ps1" to extract GPS trip data from a Teslalogger backup database dump into a readable CSV (tab delimited) file. Writes the file ".\teslalogger.gpx.csv" into current working folder
 - Parameter "-Importfile" to specify the database backup dump file to read from
 - Parameter "-Datestart" to specify the start date of the extract. Format is "yyyy-mm-dd", default is "2000-01-01"
 - Parameter "-Dateend" to specify the end date of the extract. Format is "yyyy-mm-dd", default is "9999-99-99"
 
 use "Write-Teslalogger-GPX.ps1" to convert the CSV file into GPX file format. Reads ".\teslalogger.gpx.csv" and creates "teslalogger.gpx"
 
 no database interface so far.
 MariaDB SQL backup dump file must be extracted before it can be used. "Extract" script must be used with parameter "-Importfile" to specify the file
 
Separated into two steps to allow easier direct data retrieval from datasource, the second steps stays the same

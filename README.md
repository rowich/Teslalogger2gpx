# Teslalogger2gpx
 Extract GPS trip data from the Teslalogger database and convert to GPX file format

 v0.9.1 - fix wrong bahaviour, if a named location contains "(" or ")"
 v0.9   - (dramatically) speed improvement to find start date in data
 
 v0.5   - speed and usage optimised release
          only one script, no temporary CSV file, much faster
 
 Code is based on Powershell (tested with Windows 10/2004 built-in Powershell v5.x [non Core])
 
 use "Teslalogger2gpx.ps1" to extract GPS trip data from a Teslalogger backup database dump and convert it to a GPX file
 - Parameter "-Importfile" to specify the database backup dump file to read from. This is a mandatory parameter
 - Parameter "-Datestart" to specify the start date of the extract. Format is "yyyy-mm-dd", default is "2000-01-01"
 - Parameter "-Dateend" to specify the end date of the extract. Format is "yyyy-mm-dd", default is "9999-99-99"
 - Parameter "-ExportFile" to specify the output file in GPX format, default is "teslalogger.gpx" 
 
 no database interface so far.
 MariaDB SQL backup dump file must be extracted before it can be used. "Extract" script must be used with parameter "-Importfile" to specify the file

v0.01 - very first initial release

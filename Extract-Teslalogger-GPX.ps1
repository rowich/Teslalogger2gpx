param([string] $Importfile = "mysqldump20200805010002", [string] $DateStart = "2000-01-01", [string] $DateEnd = "9999-99-99")

if (-not (Test-Path $Importfile)) {
  Write-Host "Import file $Importfile not found"
  exit 1
}

$Element = @()

#
# find end of current value in data stream
function get-value-length([string] $line) {
    $flagintext = $false
    for($Counter = 0; $counter -le $line.Length; $Counter++) {
        $char = $line.Substring($counter,1)
        if ($char -eq "'") {
            $flagintext = -not $flagintext
            if ($flagintext -eq $false) {
                $Counter++
                break
            }
        }
        if (($char -eq "," -or $char -eq ")") -and $flagintext -eq $false) { break }
    }
    return $Counter
}

#
# extracts datasets from current datastream and creates the object using date, lat, lng and alt values
# checks for datestart and dateend
function process-line([string] $line) {

    # remove trailing "inster into..." SQL command
    $line = $line.Substring($line.IndexOf("(")+1)
    $Param = @()
    $Element = @()
    $ValueCounter = 0
    $lengthstart = $line.Length
    $lengthlaststatus = 0
    while ($true) {
        $lengthstatus = $lengthstart-$line.Length
        if (($lengthstatus % 100) -ne ($lengthlaststatus % 100)) {
            Write-Progress -Activity "Deconstructing line of data" -PercentComplete ($lengthstatus / $lengthstart * 100) -ParentId 1 -Id 2
            $lengthlaststatus = $lengthlaststatus
        }

        # extracts next value
        $i = get-value-length($line)
        $Value = $line.Substring(0,$i)
        if ($Value.Substring(0,1) -eq "'") { $Value = $Value.Substring(1,$Value.Length-2) }
        $Param += $Value

        # if next character in datastream is ")", then the dataset is complete. Check for valid date range and convert to CSV object
        if ($line.substring($i,1) -eq ")") {
            if ($param[1] -gt $DateEnd) { break }
            if ($param[1] -ge $DateStart) {
                $Element += [PSCustomObject] [ordered] @{ "Date" = $param[1]; "Lat" = $param[2]; "Lng" = $param[3]; "Alt" = $param[10] }
                if ($element.Count % 100 -eq 0) { write-host "." -NoNewline -ForegroundColor Gray }
            }
            $Param = @()
            $i += 2
        }
        if ($line.Length -lt ($i+1)) { break }
        $line = $line.Substring($i+1)
    }
    Write-Progress -Completed -Activity "line deconstruction completed" -ParentId 1 -Id 2

    return $Element
}

#
# main code starts here
#

# read data file and filter for SQL "insert into" commands
Write-Host "Reading data from $Importfile into memory"
$dataset = (Get-Content $Importfile -Encoding UTF8 | ? { $_ -like "INSERT INTO *"})
Write-Host "Reading completed."
$datacounter = 0
foreach($line in  $dataset) {
    Write-Progress -Activity "Processing data file $Importfile" -status "from $DateStart to $DateEnd" -PercentComplete (++$datacounter / $dataset.count * 100) -id 1

    # we had issues to initially filter for "insert into `pos`" command. therefore do the second check here
    if ($line.Substring(0,20) -like "*pos*") {
        $Element += process-line $line
    }
}
Write-Progress -Activity "Completed" -Completed -id 1

# write result into temporary csv file
$Element | Export-Csv -LiteralPath ".\Teslalogger.gpx.csv" -NoTypeInformation -Delimiter "`t"
Write-Host "csv file created"

.\Write-Teslalogger-GPX.ps1

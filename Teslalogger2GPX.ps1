param([Parameter(Mandatory=$true)][string] $Importfile, [string] $DateStart = "2020-01-01", [string] $DateEnd = "2100-01-01", [string] $Exportfile = "teslalogger.gpx")

if (-not (Test-Path $Importfile)) {
  Write-Host "Import file $Importfile not found"
  exit 1
}

$Starttime = Get-Date
$GPX = @()


#
# extracts datasets from current datastream and creates the object using date, lat, lng and alt values
# checks for datestart and dateend
function process-line([string] $line) {

    # remove trailing "insert into..." SQL command
    $line = $line.Substring($line.IndexOf("(")+1)
    $Param = @()
    $Element = @()
    $Splitdata = $line.Split("),(")

    #
    # Check if line of data could contain relevant data
    # Searching for last node and check the date if at least the start date
    #
    Write-Progress -Activity "Searching for start date" -Status "$DateStart" -PercentComplete 0 -ParentId 1 -Id 2
    For($i = $Splitdata.Count-1;$i--;$i -ge 0) {
        $checkdate = $null
        try {
            #Write-Host $Splitdata[$i]
            $a = [string] $Splitdata[$i].Replace("'","")
            if ($a.Length -ge 20 -and $a[4] -eq "-" -and $a[7] -eq "-") {
                $checkdate = [datetime] $a
                if ($a -le $DateStart) {
                    return $Element
                }
                break
            }
        } catch { }
    }

    #
    # Found line with probably valid data
    # now building node elements
    #
    $Counter = 0
    foreach($value in $Splitdata) {
        $Counter++
        if (($Counter % 100) -eq 0) {
            Write-Progress -Activity "Deconstructing line of data" -Status "$param1" -PercentComplete ($Counter / $Splitdata.Count * 100) -ParentId 1 -Id 2
        }

        if ($value -eq "") {
            if ($Param.Count -ge 10) {
                $param1 = [string] $Param[1]
                if ($param1.Substring(0,1) -eq "'") { $param1 = $param1.Substring(1,$param1.Length-2) }
                if ($param1 -gt $DateEnd) { break }
                if ($param1 -ge $DateStart) {
                    $Element += [PSCustomObject] [ordered] @{ "Date" = $param1; "Lat" = $param[2]; "Lng" = $param[3]; "Alt" = $param[10] }
                    #if ($element.Count % 100 -eq 0) { write-host "." -NoNewline -ForegroundColor Gray }
                }
                $Param = @()
            }
        } else {
            $Param += $Value
        }
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
        $GPX += process-line $line
    }
}
Write-Progress -Activity "Completed" -Completed -id 1


# write GPX file header
Write-Output @"
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="Teslalogger GPX COnverter" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1" xmlns:gpxx="http://www.garmin.com/xmlschemas/GpxExtensions/v3" elementFormDefault="qualified">
<metadata>
	<name>teslalogger.gpx</name>
</metadata>
"@ | Out-File -FilePath $Exportfile -Encoding utf8

$Counter = 0
$CntEntries = 0
$DateLast = "n/a"
$PosLast = "n/a"

foreach($Element in $GPX) {
    if ($Counter++ % 100 -eq 0) { Write-Progress -Activity "Writing GPX file $Exportfile" -Status $Element.Date -PercentComplete ($Counter / $GPX.Count * 100) -ParentId -1 }

    # only create a new GPX record if the position has changed
    $Pos = "lat=`"$($Element.lat)`" lon=`"$($Element.lng)`""
    if ($Pos -ne $PosLast) {

        # convert date/time into GPX format (insert a "T")
        # do not convert time, GPX analysis tool must know the timezone. Default seems to be UTC. We don't know the originating time zone here, depends on the location of the car at time of recording
        $Date = $Element.date.Substring(0,10) + "T" + $Element.Date.Substring(11)

        # only create the elevation part if one exists
        if ($Element.alt -ne "NULL") {
            $alt = "<ele>$($Element.alt)</ele>"
        } else {
            $alt = ""
        }

        # create new Track element if day has changed since last element. New track node gets the name of the day (allows filtering for days later on)
        if ($DateLast -ne $Element.Date.Substring(0,10)) {
            if ($DateLast -ne "n/a") { Write-Output "</trkseg></trk>" | Out-File -FilePath $Exportfile -Append -Encoding utf8 }
            $DateLast = $Element.Date.Substring(0,10)
            Write-Output "<trk><name>$DateLast</name><trkseg>" | Out-File -FilePath $Exportfile -Append -Encoding utf8
        }

        Write-Output "    <trkpt $Pos>$alt<time>$date</time></trkpt>" | out-file -FilePath $Exportfile -Append -Encoding utf8
        $PosLast = $Pos
        $CntEntries++
    }
}

# write GPX file footer
Write-Output @"
	</trkseg>
</trk>
</gpx>
"@ | Out-File -FilePath $Exportfile -Append -Encoding utf8
Write-Progress -Completed -Activity "Done"
$Time = ((Get-Date) - $Starttime) -f "HH:mm:ss"
Write-Host "`r`nCompleted. $CntEntries GPX elemented written, $Time required"

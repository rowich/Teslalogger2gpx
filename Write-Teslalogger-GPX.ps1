$gpxdata = Import-Csv -LiteralPath ".\Teslalogger.gpx.csv" -Delimiter "`t"
$gpxexportfile = "teslalogger.gpx"

# write GPX file header
Write-Output @"
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="Teslalogger GPX Export" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1" xmlns:gpxx="http://www.garmin.com/xmlschemas/GpxExtensions/v3" elementFormDefault="qualified">
<metadata>
	<name>teslalogger.gpx</name>
</metadata>
"@ | Out-File -FilePath $gpxexportfile -Encoding utf8

$Counter = 0
$DateLast = "n/a"
$PosLast = "n/a"

foreach($element in $gpxdata) {
    if ($Counter++ % 100 -eq 0) { Write-Progress -Activity "Writing GPX file $gpxexportfile" -Status $element.Date -PercentComplete ($Counter / $gpxdata.Count * 100) -ParentId -1 }

    # convert date/time into GPX format (insert a "T")
    # do not convert time, GPX analysis tool must know the timezone. Default seems to be UTC. We don't know the originating time zone here, depends on the location of the car at time of recording
    $Date = $element.date.Substring(0,10) + "T" + $element.Date.Substring(11)

    # only create the elevation part if one exists
    if ($element.alt -ne "NULL") {
        $alt = "<ele>$($element.alt)</ele>"
    } else {
        $alt = ""
    }

    # create new Track element if day has changed since last element. New track node gets the name of the day (allows filtering for days later on)
    if ($DateLast -ne $element.Date.Substring(0,10)) {
        if ($DateLast -ne "n/a") { Write-Output "</trkseg></trk>" | Out-File -FilePath $gpxexportfile -Append -Encoding utf8 }
        $DateLast = $element.Date.Substring(0,10)
        Write-Output "<trk><name>$DateLast</name><trkseg>" | Out-File -FilePath $gpxexportfile -Append -Encoding utf8
    }

    # only create a new GPX record if the position has changed
    $Pos = "lat=`"$($element.lat)`" lon=`"$($element.lng)`""
    if ($Pos -ne $PosLast) {
        Write-Output "    <trkpt $Pos>$alt<time>$date</time></trkpt>" | out-file -FilePath $gpxexportfile -Append -Encoding utf8
        $PosLast = $Pos
    }
}

# write GPX file footer
Write-Output @"
	</trkseg>
</trk>
</gpx>
"@ | Out-File -FilePath $gpxexportfile -Append -Encoding utf8
Write-Progress -Completed -Activity "Done"

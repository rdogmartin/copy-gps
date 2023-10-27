# Create an ImageFile object and load an image file
$imageFilePath = $args[0]
# $imageFilePath = "C:\Dev\playground\GPS\image.jpg"
$image = New-Object -ComObject Wia.ImageFile
$image.LoadFile($imageFilePath)

if (!$image.Properties.Exists('GpsLatitude')) {
    $msg = "Image does not contain GPS data."
    Write-Host $msg
    New-BurntToastNotification -AppLogo $imageFilePath -Text $msg -Button (New-BTButton -Dismiss) -ExpirationTime (Get-Date).AddSeconds(3)
    Start-Sleep -Seconds 1
    exit
}


# Read the GPS coordinates
$latitudeHr = [double]$image.Properties.Item("GpsLatitude").Value[1].Value
$latitudeMin = [double]$image.Properties.Item("GpsLatitude").Value[2].Value
$latitudeSec = [double]$image.Properties.Item("GpsLatitude").Value[3].Value
$longitudeHr = [double]$image.Properties.Item("GpsLongitude").Value[1].Value
$longitudeMin = [double]$image.Properties.Item("GpsLongitude").Value[2].Value
$longitudeSec = [double]$image.Properties.Item("GpsLongitude").Value[3].Value
$latitudeRef = $image.Properties.Item("GpsLatitudeRef").Value
$longitudeRef = $image.Properties.Item("GpsLongitudeRef").Value

# Convert to decimal format
$latitudeDecimal = $latitudeHr + ($latitudeMin / 60) + ($latitudeSec / 3600)
$longitudeDecimal = $longitudeHr + ($longitudeMin / 60) + ($longitudeSec / 3600)

if ($latitudeRef -eq "S") {
    $longitudeDecimal = $longitudeDecimal * -1
}

if ($longitudeRef -eq "W") {
    $longitudeDecimal = $longitudeDecimal * -1
}

$gpsDecimal = ([math]::Round($latitudeDecimal, 6)).ToString() + "," + ([math]::Round($longitudeDecimal, 6)).ToString()
$toastText = "Copied " + $gpsDecimal + " to clipboard"

Set-Clipboard -Value $gpsDecimal
Write-Output $toastText

# Create Windows toast notification
$toastTitle = "GPS Coordinates Extracted"
$mapLinkGoogle = "https://maps.google.com/maps?q=" + $gpsDecimal
$mapLinkGaia = "https://www.gaiagps.com/map/?loc=16.0/" + $longitudeDecimal.ToString() + "/" + $latitudeDecimal.ToString()

$leftButton = New-BTButton -Content "Google Maps" -Arguments $mapLinkGoogle -ActivationType Protocol
$rightButton = New-BTButton -Content "Gaia" -Arguments $mapLinkGaia -ActivationType Protocol

New-BurntToastNotification -AppLogo $imageFilePath -Text $toastTitle, $toastText -Button $leftButton, $rightButton -ExpirationTime (Get-Date).AddMinutes(1)
Start-Sleep -Seconds 1

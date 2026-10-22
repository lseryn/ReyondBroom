# Download only the pinned compiler release and retain corresponding source/notices.
param([string]$Destination="$PSScriptRoot/../tools/ericw")
$ErrorActionPreference='Stop'
$pin=Get-Content "$PSScriptRoot/../tools/ericw/PIN.json" -Raw | ConvertFrom-Json
New-Item -ItemType Directory -Force $Destination | Out-Null
$ready=$true
foreach($entry in $pin.files.PSObject.Properties){
    $path=Join-Path $Destination $entry.Name
    if(!(Test-Path -LiteralPath $path) -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $entry.Value){$ready=$false}
}
if(!$ready){
    $temporary=Join-Path ([IO.Path]::GetTempPath()) ('ftebroom-ericw-'+[guid]::NewGuid())
    New-Item -ItemType Directory $temporary | Out-Null
    $archive=Join-Path $temporary 'release.zip'
    Invoke-WebRequest $pin.binary_url -OutFile $archive
    if((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $pin.binary_sha256){throw 'Compiler archive checksum mismatch'}
    Expand-Archive -LiteralPath $archive -DestinationPath $temporary
    Copy-Item "$temporary/ericw-tools-v$($pin.version)-win64/bin/*" $Destination -Force
    Copy-Item "$temporary/ericw-tools-v$($pin.version)-win64/doc" $Destination -Recurse -Force
}
$source=Join-Path $Destination "ericw-tools-v$($pin.version)-source.zip"
if(!(Test-Path -LiteralPath $source) -or (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $pin.source_sha256){
    Invoke-WebRequest $pin.source_url -OutFile $source
    if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $pin.source_sha256){throw 'Compiler source checksum mismatch'}
}
foreach($entry in $pin.files.PSObject.Properties){
    if((Get-FileHash -LiteralPath (Join-Path $Destination $entry.Name) -Algorithm SHA256).Hash -ne $entry.Value){throw "Compiler file checksum mismatch: $($entry.Name)"}
}
Write-Host "Verified ericw-tools $($pin.version) in $Destination"

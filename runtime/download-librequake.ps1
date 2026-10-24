param([Parameter(Mandatory=$true)][string]$Destination)
# Use Windows PowerShell's modules even when launched from PowerShell 7.
$env:PSModulePath=[IO.Path]::Combine($PSHOME,'Modules')
$ErrorActionPreference='Stop'
$destinationPath=[IO.Path]::GetFullPath($Destination)
[IO.Directory]::CreateDirectory($destinationPath) | Out-Null
$progressPath=Join-Path $destinationPath 'progress.txt'
$archive=Join-Path $destinationPath 'mod_lite.zip.part'
$staging=Join-Path $destinationPath ('extract-'+[guid]::NewGuid())
function Progress([long]$done,[long]$total,[string]$phase){[IO.File]::WriteAllText($progressPath,"$done $total $phase")}
function Install-Package([string]$Url,[string]$Checksum,[string]$Folder,[string]$Required,[string]$Marker) {
  if([IO.File]::Exists("$destinationPath/$Marker") -and [IO.File]::Exists("$destinationPath/$Required")){return}
    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
    $request=[Net.HttpWebRequest]::Create($Url)
    $request.UserAgent='ReyondBroom';$request.Timeout=30000;$request.ReadWriteTimeout=30000
    $response=$request.GetResponse();$inputStream=$response.GetResponseStream();$output=[IO.File]::Create($archive)
    try {$buffer=New-Object byte[] 65536;$done=0;$last=[DateTime]::UtcNow
        Progress 0 $response.ContentLength 'Downloading'
        while(($n=$inputStream.Read($buffer,0,$buffer.Length)) -gt 0){$output.Write($buffer,0,$n);$done+=$n
            if($done -gt 536870912){throw 'Download exceeds 512 MiB'}
            if(([DateTime]::UtcNow-$last).TotalMilliseconds -gt 150){Progress $done $response.ContentLength 'Downloading';$last=[DateTime]::UtcNow}}
    } finally {$output.Dispose();$inputStream.Dispose();$response.Dispose()}
    if((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $Checksum){throw 'LibreQuake archive checksum mismatch'}
    Progress $done $done 'Extracting'
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Directory]::CreateDirectory($staging) | Out-Null
    $zip=[IO.Compression.ZipFile]::OpenRead($archive)
    try {$total=0;foreach($entry in $zip.Entries){
        $target=[IO.Path]::GetFullPath((Join-Path $staging $entry.FullName))
        if(!$target.StartsWith($staging+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Unsafe archive path'}
        $total+=$entry.Length;if($total -gt 1073741824){throw 'Extracted archive exceeds 1 GiB'}
        if(!$entry.Name){[IO.Directory]::CreateDirectory($target)|Out-Null;continue}
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))|Out-Null
        [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$target,$false)
    }} finally {$zip.Dispose()}
    if(!(Test-Path -LiteralPath "$staging/$Required")){throw 'LibreQuake PAK is missing'}
    if(!(Test-Path -LiteralPath "$destinationPath/$Folder")){Move-Item -LiteralPath "$staging/$Folder" -Destination "$destinationPath/$Folder"}
    if($Folder -eq "mod_lite"){[IO.Directory]::CreateDirectory("$destinationPath/mod_lite/id1")|Out-Null}
    if(![IO.File]::Exists("$destinationPath/$Required")){throw "Incomplete LibreQuake installation"}
    [IO.File]::WriteAllText("$destinationPath/$Marker",'v0.09-beta')
    Progress $done $done 'Ready'
}
try {
    Install-Package 'https://github.com/lavenderdotpet/LibreQuake/releases/download/v0.09-beta/mod_lite.zip' 'DCE87BC769FFCD342D297AAF260DC651458D4F00BF1F332A6600BA4C52457193' 'mod_lite' 'mod_lite/lq1/pak0.pak' 'ready.txt'
    Install-Package 'https://github.com/lavenderdotpet/LibreQuake/releases/download/v0.09-beta/dev.zip' '8B6CD467A73976E8ED6EE52EECC0CAFC7D3A0C289058B1CCEBCF05583A88F288' 'dev' 'dev/texture-wads/lq_dev.wad' 'wads-ready.txt'
    $wadFolder="$destinationPath/mod_lite/lq1/texture-wads"
    [IO.Directory]::CreateDirectory($wadFolder)|Out-Null
    foreach($wad in [IO.Directory]::GetFiles("$destinationPath/dev/texture-wads",'*.wad')) {
        $target=[IO.Path]::Combine($wadFolder,[IO.Path]::GetFileName($wad))
        if(![IO.File]::Exists($target)){[IO.File]::Copy($wad,$target)}
    }
} catch {[IO.File]::WriteAllText("$destinationPath/error.txt",$_.Exception.Message);exit 1}
finally {
    # Only files created inside this installer-owned directory are removed.
    if(Test-Path -LiteralPath $archive){Remove-Item -LiteralPath $archive}
    $checked=[IO.Path]::GetFullPath($staging)
    if($checked.StartsWith($destinationPath+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $checked)){Remove-Item -LiteralPath $checked -Recurse}
}

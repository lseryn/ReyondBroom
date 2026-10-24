# SPDX-License-Identifier: GPL-2.0-or-later
param([Parameter(Mandatory=$true)][string]$Destination)
$ErrorActionPreference='Stop'
$folder='blender-5.0.0-windows-x64'
$checksum='14d491b6e491c35950b89bac8caa4ab7115596cc056775f427806d3ea2eac698'
$stage=$null
function Progress([long]$done,[long]$total,[string]$phase) {
    [IO.File]::WriteAllText((Join-Path $Destination 'progress.txt'),"$done $total $phase")
}
function LongPath([string]$path) {
    $path=[IO.Path]::GetFullPath($path)
    if($path.StartsWith('\\')){return '\\?\UNC\'+$path.Substring(2)}
    return '\\?\'+$path
}
try {
    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    $Destination=(Resolve-Path -LiteralPath $Destination).Path
    $target=Join-Path $Destination $folder
    if (!(Test-Path -LiteralPath "$target/ftebroom-ready.txt") -or !(Test-Path -LiteralPath "$target/blender.exe")) {
        $stage=Join-Path $Destination ('install-'+[guid]::NewGuid())
        New-Item -ItemType Directory -Path $stage | Out-Null
        $archive=Join-Path $stage 'download.zip'
        Progress 0 0 'Connecting to blender.org'
        $request=[Net.HttpWebRequest]::Create("https://download.blender.org/release/Blender5.0/$folder.zip")
        $request.UserAgent='ReyondBroom';$request.Timeout=45000;$request.ReadWriteTimeout=45000
        $response=$request.GetResponse()
        try {
            $inputStream=$response.GetResponseStream();$output=[IO.File]::Create($archive)
            try {
                $buffer=New-Object byte[] 1048576;$done=0L
                while(($count=$inputStream.Read($buffer,0,$buffer.Length)) -gt 0) {
                    $done+=$count
                    if($done -gt 1GB){throw 'Blender download exceeds 1 GiB'}
                    $output.Write($buffer,0,$count)
                    Progress $done $response.ContentLength 'Downloading Blender 5.0.0'
                }
            } finally {$output.Dispose();$inputStream.Dispose()}
        } finally {$response.Dispose()}
        Progress 1 1 'Verifying download'
        if((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $checksum){throw 'Blender checksum mismatch; retry the download'}
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip=[IO.Compression.ZipFile]::OpenRead($archive)
        try {
            $total=0L;$index=0
            foreach($entry in $zip.Entries) {
                $total+=$entry.Length
                if($total -gt 4GB -or $zip.Entries.Count -gt 100000){throw 'Blender archive exceeds extraction limits'}
                $name=$entry.FullName.Replace('\','/')
                if(!$name.StartsWith("$folder/") -or $name.Split('/') -contains '..' -or $name.Contains(':')){throw 'Unsafe archive path'}
                $path=Join-Path $stage $name
                $path=LongPath $path
                if($name.EndsWith('/')){[IO.Directory]::CreateDirectory($path) | Out-Null}
                else {[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path)) | Out-Null;[IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$path,$false)}
                $index++;if($index % 100 -eq 0){Progress $index $zip.Entries.Count 'Extracting Blender'}
            }
        } finally {$zip.Dispose()}
        if(!(Test-Path -LiteralPath "$stage/$folder/blender.exe")){throw 'Blender executable is missing'}
        [IO.File]::WriteAllText("$stage/$folder/ftebroom-ready.txt",$checksum)
        if(Test-Path -LiteralPath $target){if(!(Test-Path -LiteralPath "$target/ftebroom-ready.txt")){throw 'Incomplete managed Blender installation'}}
        else {Move-Item -LiteralPath "$stage/$folder" -Destination $target}
    }
    Progress 1 1 'Blender ready'
    [IO.File]::WriteAllText((Join-Path $Destination 'success.txt'),'5.0.0')
} catch {
    [IO.File]::WriteAllText((Join-Path $Destination 'error.txt'),$_.Exception.Message)
    exit 1
} finally {
    if($stage -and (Test-Path -LiteralPath $stage)){
        $resolved=[IO.Path]::GetFullPath($stage)
        if($resolved.StartsWith($Destination+[IO.Path]::DirectorySeparatorChar) -and [IO.Path]::GetFileName($resolved).StartsWith('install-')){[IO.Directory]::Delete((LongPath $resolved),$true)}
    }
}

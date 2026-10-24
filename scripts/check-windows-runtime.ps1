param([Parameter(Mandatory=$true)][string]$Bundle,[string]$MinGW='C:/msys64/mingw64/bin')
$ErrorActionPreference='Stop'
$root=(Resolve-Path -LiteralPath $Bundle).Path
$queue=[Collections.Generic.Queue[string]]::new()
foreach($name in @('FTEBroom.exe','fteqw64.exe','fteplug_ftebroom_x64.dll','zlib1.dll','libpng16.dll','libjpeg.dll','libgcc_s_seh-1.dll','libwinpthread-1.dll')){
    $path=Join-Path $root $name
    if(!(Test-Path -LiteralPath $path -PathType Leaf)){throw "Incomplete distribution: $name is missing"}
    $queue.Enqueue($path)
}
$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
while($queue.Count){
    $path=$queue.Dequeue();if(!$seen.Add($path)){continue}
    $output=(& "$MinGW/objdump.exe" -p $path | Out-String)
    if($LASTEXITCODE){throw "Cannot inspect $path"}
    foreach($match in [regex]::Matches($output,'DLL Name:\s*(\S+)')){
        $name=$match.Groups[1].Value
        if($name -match '^(api-ms-|ext-ms-)' -or (Test-Path -LiteralPath (Join-Path "$env:SystemRoot/System32" $name))){continue}
        $dependency=Join-Path $root $name
        if(!(Test-Path -LiteralPath $dependency -PathType Leaf)){throw "$path requires missing $name"}
        $queue.Enqueue($dependency)
    }
}
Write-Host "PASS: Windows runtime dependencies in $root"

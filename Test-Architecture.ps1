param([switch]$Keep)
$ErrorActionPreference='Stop'
$root=$PSScriptRoot
$work=Join-Path ([IO.Path]::GetTempPath()) ('XAudioUniversal-'+[Guid]::NewGuid().ToString('N'))
$files=@('xaudiouniv.dll','dsound.dll','eax.dll','OpenAL32.dll','wrap_oal.dll','ct_oal.dll','soft_oal.dll','winmm.dll','universal_probe.exe','xaudiouniv.ini','dsound.ini','eax.ini','OpenAL32.ini','wrap_oal.ini','ct_oal.ini','soft_oal.ini','winmm.ini')
foreach($file in $files){if(-not (Test-Path -LiteralPath (Join-Path $root $file))){throw "Missing $file"}}
New-Item -ItemType Directory -Path $work | Out-Null
$cases=@(
 @{Name='default';OK=$true},
 @{Name='renamed-core';Core='audio_engine.dll';OK=$true},
 @{Name='renamed-relay';Relay='my_sound.dll';Args=@('--dsound=my_sound.dll');OK=$true},
 @{Name='openal-disabled';Feature='OpenAL';Args=@('--expect-openal-off');OK=$true},
 @{Name='eax-master-disabled';Feature='EAX';Args=@('--expect-eax-off');OK=$true},
 @{Name='eax-versions-disabled';AllEax=$true;Args=@('--expect-eax-off');OK=$true},
 @{Name='eax-and-native-openal-disabled';AllEax=$true;NativeOff=$true;Args=@('--expect-eax-off');OK=$true},
 @{Name='eax5-disabled';Feature='EAX5';Args=@('--expect-eax5-off');OK=$true},
 @{Name='wrong-core-relay';Real='eax.dll';OK=$false},
 @{Name='wrong-wrapper-mode';Mode='winmm';OK=$false},
 @{Name='missing-core';Real='missing.dll';OK=$false}
)
$failed=0
try{
 foreach($case in $cases){
  $folder=Join-Path $work $case.Name;New-Item -ItemType Directory -Path $folder | Out-Null
  foreach($file in $files){Copy-Item -LiteralPath (Join-Path $root $file) -Destination $folder}
  $ini=Get-Content -Raw -LiteralPath (Join-Path $folder 'xaudiouniv.ini')
  if($case.Core){Move-Item -LiteralPath (Join-Path $folder 'xaudiouniv.dll') -Destination (Join-Path $folder $case.Core);$ini=$ini.Replace('RealDllPath=xaudiouniv.dll',"RealDllPath=$($case.Core)")}
  if($case.Real){$ini=$ini.Replace('RealDllPath=xaudiouniv.dll',"RealDllPath=$($case.Real)")}
  if($case.Feature){$ini=$ini.Replace("$($case.Feature)=1","$($case.Feature)=0")}
  if($case.AllEax){foreach($n in 1..5){$ini=$ini.Replace("EAX$n=1","EAX$n=0")}}
  if($case.NativeOff){$ini=$ini.Replace('OpenAL=1','OpenAL=0').Replace('OpenALEFX=1','OpenALEFX=0')}
  Set-Content -LiteralPath (Join-Path $folder 'xaudiouniv.ini') -Value $ini -Encoding Unicode
  if($case.Relay){Move-Item -LiteralPath (Join-Path $folder 'dsound.dll') -Destination (Join-Path $folder $case.Relay);"[Wrapper]`r`nWrapperMode=dsound`r`nRealDllPath=`r`n"|Set-Content -LiteralPath (Join-Path $folder 'my_sound.ini') -Encoding Unicode}
  if($case.Mode){"[Wrapper]`r`nWrapperMode=$($case.Mode)`r`n"|Set-Content -LiteralPath (Join-Path $folder 'dsound.ini') -Encoding Unicode}
  $start=@{FilePath=(Join-Path $folder 'universal_probe.exe');WorkingDirectory=$folder;NoNewWindow=$true;Wait=$true;PassThru=$true;RedirectStandardOutput=(Join-Path $folder 'probe.log');RedirectStandardError=(Join-Path $folder 'probe-error.log')}
  if($case.Args){$start.ArgumentList=$case.Args}
  $process=Start-Process @start;$ok=(($process.ExitCode -eq 0) -eq $case.OK);if(-not $ok){$failed++}
  Write-Host "$($case.Name): $(if($ok){'PASS'}else{'FAIL'}) (exit=$($process.ExitCode))"
 }
 if($failed){throw "$failed cases failed. Logs: $work"}
}finally{if($Keep -or $failed){Write-Host "Logs retained: $work"}else{Remove-Item -LiteralPath $work -Recurse -Force}}

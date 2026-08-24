param(
  [Parameter(Mandatory=$true)]
  [string]$ExePath
)

$exe = (Resolve-Path $ExePath).Path
$base = 'HKCU:\Software\Classes\campusx'
New-Item -Path $base -Force | Out-Null
Set-ItemProperty -Path $base -Name '(default)' -Value 'URL:CampusX'
New-ItemProperty -Path $base -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
$command = Join-Path $base 'shell\open\command'
New-Item -Path $command -Force | Out-Null
Set-ItemProperty -Path $command -Name '(default)' -Value ('"' + $exe + '" "%1"')
Write-Host "Registered campusx:// -> $exe"

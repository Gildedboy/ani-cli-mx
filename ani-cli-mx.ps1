$ErrorActionPreference = "Stop"

$bashCandidates = @()
if ($env:GIT_INSTALL_ROOT) {
    $bashCandidates += (Join-Path $env:GIT_INSTALL_ROOT "bin\bash.exe")
}
if ($env:SCOOP) {
    $bashCandidates += (Join-Path $env:SCOOP "apps\git\current\bin\bash.exe")
}
$bashCandidates += (Join-Path $env:USERPROFILE "scoop\apps\git\current\bin\bash.exe")
if ($env:SCOOP_GLOBAL) {
    $bashCandidates += (Join-Path $env:SCOOP_GLOBAL "apps\git\current\bin\bash.exe")
}
if ($env:ProgramData) {
    $bashCandidates += (Join-Path $env:ProgramData "scoop\apps\git\current\bin\bash.exe")
}
if ($env:ProgramFiles) {
    $bashCandidates += (Join-Path $env:ProgramFiles "Git\bin\bash.exe")
}
if ($env:LocalAppData) {
    $bashCandidates += (Join-Path $env:LocalAppData "Programs\Git\bin\bash.exe")
}

$bashExe = $bashCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $bashExe) {
    [Console]::Error.WriteLine("ani-cli-mx necesita Git for Windows. Instalalo con: scoop install git")
    exit 1
}

$corePath = Join-Path $PSScriptRoot "ani-cli-mx-core"
if (-not (Test-Path $corePath)) {
    [Console]::Error.WriteLine("No se encontro ani-cli-mx-core junto al launcher de Windows.")
    exit 1
}

$env:ANI_CLI_WINDOWS = "1"
$env:ANI_CLI_PACKAGE_MANAGER = "scoop"
$env:ANI_CLI_NAME = "ani-cli-mx"
$env:ANI_CLI_LOG_TAG = "ani-cli-mx"
$env:ANI_CLI_STATE_NAME = "ani-cli-mx"

& $bashExe $corePath @args
exit $LASTEXITCODE

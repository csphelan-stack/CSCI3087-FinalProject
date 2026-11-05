<#
.SYNOPSIS
Runs the built game in test mode and copies its results into the workspace.

.DESCRIPTION
1. Unzips the Windows build that igor-build produced.
2. Deletes any old test_results.json so a stale file can never pass.
3. Starts the game with --run-tests. GameMaker writes everything the game
   prints (show_debug_message) to game-log.txt.
4. Waits for the game to close, killing it after -TimeoutSeconds.
5. Copies test_results.json from the game's save folder
   (%LOCALAPPDATA%\<game name>\) into -OutDir.

Deciding pass or fail is left to check_test_results.py, so this script only
fails when the game cannot be found or does not exit in time.

.EXAMPLE
./tools/ci/run-gml-tests.ps1 -BuildDir build_output -OutDir test-output
#>
param(
    [Parameter(Mandatory = $true)][string]$BuildDir,
    [string]$OutDir = "test-output",
    [int]$TimeoutSeconds = 300
)

$ErrorActionPreference = "Stop"
$resultsName = "test_results.json"

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$OutDir = (Resolve-Path $OutDir).Path

# 1. Unpack the build.
$gameDir = Join-Path $OutDir "game"
$zip = Get-ChildItem -Path $BuildDir -Filter *.zip -Recurse | Select-Object -First 1
if ($zip) {
    Write-Host "Unpacking $($zip.FullName)"
    Expand-Archive -Path $zip.FullName -DestinationPath $gameDir -Force
} else {
    $gameDir = $BuildDir
}
$exe = Get-ChildItem -Path $gameDir -Filter *.exe -Recurse | Select-Object -First 1
if (-not $exe) {
    throw "No .exe found in $gameDir. Check the 'Build Windows game' step."
}
Write-Host "Game executable: $($exe.FullName)"

# 2. Remove results left by an earlier run.
Get-ChildItem -Path $env:LOCALAPPDATA -Filter $resultsName -Recurse -Depth 1 -ErrorAction SilentlyContinue |
    Remove-Item -Force

# 3. Start the game in test mode.
$log = Join-Path $OutDir "game-log.txt"
New-Item -ItemType File -Force -Path $log | Out-Null
$startedAt = Get-Date
$process = Start-Process -FilePath $exe.FullName -WorkingDirectory $exe.DirectoryName `
    -ArgumentList "--run-tests", "-output", "`"$log`"", "-debugoutput", "`"$log`"" `
    -PassThru -NoNewWindow
$null = $process.Handle  # keeps ExitCode readable after the process ends

# 4. Wait for it to close.
if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
    $process.Kill()
    Get-Content $log -Tail 40 -ErrorAction SilentlyContinue
    throw "The game did not close within $TimeoutSeconds seconds. A test may be stuck in a loop, or the game never reached the test runner. See game-log.txt."
}
$elapsed = [math]::Round(((Get-Date) - $startedAt).TotalSeconds)
Write-Host "Game closed with exit code $($process.ExitCode) after $elapsed s"

# 5. Collect the results.
$results = Get-ChildItem -Path $env:LOCALAPPDATA -Filter $resultsName -Recurse -Depth 1 -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -ge $startedAt } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
if ($results) {
    Copy-Item $results.FullName (Join-Path $OutDir $resultsName) -Force
    Write-Host "Copied results from $($results.FullName)"
} else {
    Write-Host "No $resultsName was written; the results check will fail."
}

Write-Host "---- last lines of game-log.txt ----"
Get-Content $log -Tail 40 -ErrorAction SilentlyContinue

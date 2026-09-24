param(
    [string]$Rojo = 'C:\Tools\Rojo\rojo.exe',
    [string]$LuauDirectory = ''
)
$ErrorActionPreference = 'Stop'
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    New-Item -ItemType Directory -Path build -Force | Out-Null
    & $Rojo build default.project.json -o build/mutant-farm.rbxlx
    if ($LASTEXITCODE -ne 0) { throw 'Rojo build failed.' }
    [xml]$place = Get-Content -Raw build/mutant-farm.rbxlx
    $scripts = @($place.SelectNodes('//Item[@class="Script"]'))
    $clients = @($place.SelectNodes('//Item[@class="LocalScript"]'))
    $modules = @($place.SelectNodes('//Item[@class="ModuleScript"]'))
    if ($scripts.Count -ne 1 -or $clients.Count -ne 1 -or $modules.Count -ne 3) {
        throw 'Unexpected script layout in built place.'
    }
    if ((Get-Content -Raw build/mutant-farm.rbxlx).Contains('ROJO_SYNC_TEST')) { throw 'Old sync test remains.' }
    Write-Output 'PASS Rojo build: one server, one client, three modules; no sync test.'
    if ($LuauDirectory) {
        $compiler = Join-Path $LuauDirectory 'luau-compile.exe'
        $runner = Join-Path $LuauDirectory 'luau.exe'
        foreach ($file in Get-ChildItem src,tests -Recurse -Filter '*.luau') {
            & $compiler --null $file.FullName
            if ($LASTEXITCODE -ne 0) { throw "Luau compile failed: $($file.FullName)" }
        }
        & $runner tests/FarmState.spec.luau
        if ($LASTEXITCODE -ne 0) { throw 'Gameplay-state tests failed.' }
    } else {
        Write-Output 'SKIP Luau compilation/state tests: pass -LuauDirectory with official standalone tools.'
    }
    git diff --check
    if ($LASTEXITCODE -ne 0) { throw 'Whitespace check failed.' }
} finally {
    Pop-Location
}

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
    if ($scripts.Count -ne 1 -or $clients.Count -ne 1 -or $modules.Count -ne 7) {
        throw 'Unexpected script layout in built place.'
    }
    if ((Get-Content -Raw build/mutant-farm.rbxlx).Contains('ROJO_SYNC_TEST')) { throw 'Old sync test remains.' }
    Write-Output 'PASS Rojo build: one server, one client, seven modules; no sync test.'
    $serverModules = @($place.SelectNodes('//Item[@class="ServerScriptService"]//Item[@class="ModuleScript"]/Properties/string[@name="Name"]') | ForEach-Object InnerText)
    if ($serverModules -notcontains 'StudioPreview' -or $serverModules -notcontains 'CropVisuals') {
        throw 'Expected server-only preview and crop renderer modules.'
    }
    $clientModules = @($place.SelectNodes('//Item[@class="StarterPlayerScripts"]//Item[@class="ModuleScript"]/Properties/string[@name="Name"]') | ForEach-Object InnerText)
    if ($clientModules -notcontains 'FarmEffects' -or $clientModules -contains 'StudioPreview') {
        throw 'Unexpected client module placement.'
    }
    $previewSource = Get-Content -Raw src/server/StudioPreview.luau
    $studioGuard = 'if not RunService:IsStudio() or not RunService:IsServer() then return'
    if (([regex]::Matches($previewSource, [regex]::Escape($studioGuard))).Count -ne 2) {
        throw 'Preview installation and invocation must both be Studio/server gated.'
    }
    if ($previewSource.Contains('RemoteEvent') -or -not $previewSource.Contains('command.Parent = ServerStorage')) {
        throw 'Preview must remain a ServerStorage bindable, not a client remote.'
    }
    $mainSource = Get-Content -Raw src/server/Main.server.luau
    if ($mainSource -match 'feedback\.OnServerEvent\s*:') {
        throw 'Feedback must remain outbound-only.'
    }
    if (-not $mainSource.Contains('actionRequest.OnServerEvent:Connect') -or
        -not $mainSource.Contains('type(cropId) ~= "string" or not Config.Crops[cropId]') -or
        -not $mainSource.Contains('action ~= "Buy" and action ~= "Select"') -or
        -not $mainSource.Contains('allowed(player, player, target, Config.ShopDistance)')) {
        throw 'Crop requests must whitelist identifiers and validate proximity/rate/character.'
    }
    Write-Output 'PASS static boundaries: Studio-only preview, outbound feedback, guarded crop requests.'
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

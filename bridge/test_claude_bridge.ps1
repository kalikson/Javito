# Pruebas aisladas del puente. Usa remote bare temporal y stubs de Claude en %TEMP%.
# No toca el repositorio real ni hace push a ningun remote real.
$ErrorActionPreference = "Stop"

$bridgeScript = Join-Path $PSScriptRoot "claude_bridge.ps1"
$root = Join-Path ([IO.Path]::GetTempPath()) ("bridge-test-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $root | Out-Null

$env:GIT_AUTHOR_NAME = "test"; $env:GIT_AUTHOR_EMAIL = "test@localhost"
$env:GIT_COMMITTER_NAME = "test"; $env:GIT_COMMITTER_EMAIL = "test@localhost"

$script:failures = 0
function Assert-That {
    param([bool]$Condition, [string]$Name)
    if ($Condition) { Write-Host "PASS  $Name" } else { Write-Host "FAIL  $Name"; $script:failures++ }
}

function Git {
    # Git silencioso; devuelve stdout como texto. stderr se ignora (git informa por ahi).
    param([string]$Dir, [string[]]$GitArgs)
    $prev = $ErrorActionPreference; $ErrorActionPreference = "Continue"
    try { $out = & git -C $Dir @GitArgs 2>$null } finally { $ErrorActionPreference = $prev }
    return (($out | ForEach-Object { "$_" }) -join "`n").Trim()
}

function New-Stub {
    # Stub fuera del repo: cuenta invocaciones, opcionalmente hace un commit local, sale con $Exit.
    param([string]$Name, [int]$Exit, [switch]$LocalCommit)
    $path = Join-Path $root "$Name.cmd"
    $counter = Join-Path $root "$Name.count"
    $lines = @("@echo off", "echo x>>`"$counter`"", "echo harmless output")
    if ($LocalCommit) {
        $lines += "echo partial>partial.txt"
        $lines += "git add partial.txt"
        $lines += "git commit -q -m partial-claude-commit"
    }
    $lines += "exit /b $Exit"
    Set-Content -Path $path -Value $lines -Encoding ASCII
    return $path
}

function Get-StubCount {
    param([string]$Stub)
    $c = [IO.Path]::ChangeExtension($Stub, "count")
    if (Test-Path $c) { return @(Get-Content $c).Count } else { return 0 }
}

function New-Fixture {
    param([string]$Name)
    $bare = Join-Path $root "$Name-remote.git"
    $seed = Join-Path $root "$Name-seed"
    $work = Join-Path $root "$Name-work"
    & git init -q --bare -b main $bare 2>$null
    & git init -q -b main $seed 2>$null
    New-Item -ItemType Directory -Path (Join-Path $seed "bridge") | Out-Null
    Set-Content (Join-Path $seed "NEXT_TASK.md") "task v1"
    Set-Content (Join-Path $seed "README.md") "readme"
    Set-Content (Join-Path $seed ".gitignore") ".claude/"
    Copy-Item $bridgeScript (Join-Path $seed "bridge\claude_bridge.ps1")
    Git $seed @("add", "-A") | Out-Null
    Git $seed @("commit", "-q", "-m", "seed") | Out-Null
    Git $seed @("remote", "add", "origin", $bare) | Out-Null
    Git $seed @("push", "-q", "origin", "main") | Out-Null
    & git clone -q $bare $work 2>$null
    return [pscustomobject]@{ Bare = $bare; Seed = $seed; Work = $work }
}

function Invoke-Bridge {
    param($Fx, [string]$Stub, [switch]$RunCurrent)
    $argList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $Fx.Work "bridge\claude_bridge.ps1"), "-Once", "-ClaudeExe", $Stub)
    if ($RunCurrent) { $argList += "-RunCurrent" }
    & powershell.exe @argList *> $null
}

function Get-LocalState {
    param($Fx)
    Get-Content (Join-Path $Fx.Work ".claude\bridge_state.json") -Raw | ConvertFrom-Json
}

function Get-StatusFile {
    param($Fx)
    Git $Fx.Bare @("show", "bridge-status:BRIDGE_STATUS.md")
}

$realRepo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$realHeadBefore = Git $realRepo @("rev-parse", "origin/main")
$realStatusBefore = Git $realRepo @("status", "--porcelain")

try {
    # --- Escenario A/D: salida 7, no reintento, creacion y actualizacion de BRIDGE_STATUS.md ---
    Write-Host "== Escenario A: salida no cero =="
    $fx = New-Fixture "a"
    $mainBefore = Git $fx.Bare @("rev-parse", "main")
    $stub7 = New-Stub "stub7" 7
    Invoke-Bridge $fx $stub7 -RunCurrent
    $st = Get-LocalState $fx
    Assert-That ($st.status -eq "claude_exit_7") "1. estado local claude_exit_7"
    Assert-That ($st.exit_code -eq 7) "1b. exit_code guardado"
    Assert-That ((Get-StubCount $stub7) -eq 1) "1c. Claude lanzado una vez"

    Invoke-Bridge $fx $stub7
    Assert-That ((Get-StubCount $stub7) -eq 1) "2. misma version de NEXT_TASK.md no se relanza"

    $status = Get-StatusFile $fx
    Assert-That ($status -match "status: claude_exit_7") "3. BRIDGE_STATUS.md creado en bridge-status del remote de prueba"
    Assert-That ($status -match "exit_code: 7") "3b. contiene exit_code"
    Assert-That ($status -notmatch "harmless") "3c. no copia stdout de Claude"
    Assert-That ((Git $fx.Bare @("ls-tree", "--name-only", "bridge-status")) -eq "BRIDGE_STATUS.md") "4. bridge-status contiene solo BRIDGE_STATUS.md"
    Assert-That ((Git $fx.Bare @("rev-parse", "main")) -eq $mainBefore) "4b. main del remote no cambio"
    Assert-That ((Git $fx.Work @("status", "--porcelain")) -eq "") "4c. arbol de trabajo limpio, sin archivos ajenos"

    # Nueva version de tarea: la rama de estado se actualiza (2 commits)
    Set-Content (Join-Path $fx.Seed "NEXT_TASK.md") "task v2"
    Git $fx.Seed @("commit", "-q", "-am", "task v2") | Out-Null
    Git $fx.Seed @("push", "-q", "origin", "main") | Out-Null
    Invoke-Bridge $fx $stub7
    Assert-That ((Get-StubCount $stub7) -eq 2) "2b. nueva version de NEXT_TASK.md si se lanza"
    Assert-That ((Git $fx.Bare @("rev-list", "--count", "bridge-status")) -eq "2") "3d. bridge-status se actualiza (2 commits)"

    # --- Escenario B: commit local parcial de Claude no llega al remote/rama de estado ---
    Write-Host "== Escenario B: commit local parcial =="
    $fx = New-Fixture "b"
    $mainBefore = Git $fx.Bare @("rev-parse", "main")
    $stubC = New-Stub "stubC" 7 -LocalCommit
    Invoke-Bridge $fx $stubC -RunCurrent
    $partial = Git $fx.Work @("rev-parse", "HEAD")
    Assert-That ($partial -ne $mainBefore) "6a. el commit parcial existe localmente en main"
    $inRemote = Git $fx.Bare @("cat-file", "-t", $partial)
    Assert-That ($inRemote -ne "commit") "6. commit parcial NO esta en el remote (ni en bridge-status)"
    Assert-That ((Git $fx.Bare @("ls-tree", "--name-only", "bridge-status")) -eq "BRIDGE_STATUS.md") "6b. bridge-status solo tiene el archivo de estado"
    Assert-That ((Git $fx.Bare @("rev-parse", "main")) -eq $mainBefore) "6c. main del remote intacto"
    Assert-That ((Get-LocalState $fx).status -eq "claude_exit_7") "6d. estado local claude_exit_7"

    # --- Escenario C: arbol sucio ---
    Write-Host "== Escenario C: arbol sucio =="
    $fx = New-Fixture "c"
    $mainBefore = Git $fx.Bare @("rev-parse", "main")
    $stubOk = New-Stub "stubOk" 0
    Set-Content (Join-Path $fx.Work "README.md") "cambio local SECRETO-123"
    Set-Content (Join-Path $fx.Work "nuevo.txt") "archivo sin trackear"
    Invoke-Bridge $fx $stubOk -RunCurrent
    Assert-That ((Get-StubCount $stubOk) -eq 0) "5a. Claude no se ejecuto con arbol sucio"
    Assert-That ((Get-LocalState $fx).status -eq "blocked_dirty_tree") "5b. estado local blocked_dirty_tree"
    Assert-That ((Get-Content (Join-Path $fx.Work "README.md") -Raw).Trim() -eq "cambio local SECRETO-123") "5c. cambio tracked conservado"
    Assert-That (Test-Path (Join-Path $fx.Work "nuevo.txt")) "5d. archivo sin trackear conservado"
    $status = Get-StatusFile $fx
    Assert-That ($status -match "status: blocked_dirty_tree") "5e. publicado blocked_dirty_tree"
    Assert-That (($status -match "README.md") -and ($status -match "nuevo.txt")) "5f. lista rutas sucias"
    Assert-That ($status -notmatch "SECRETO-123") "5g. sin contenido de archivos"
    Invoke-Bridge $fx $stubOk
    Assert-That ((Git $fx.Bare @("rev-list", "--count", "bridge-status")) -eq "1") "5h. no hay bucle: mismo estado no se republica"
    Assert-That ((Git $fx.Bare @("rev-parse", "main")) -eq $mainBefore) "5i. main del remote intacto"

    # --- 7: repositorio real ---
    Write-Host "== Repositorio real =="
    Assert-That ((Git $realRepo @("rev-parse", "origin/main")) -eq $realHeadBefore) "7a. origin/main real sin cambios por las pruebas"
    Assert-That ((Git $realRepo @("status", "--porcelain")) -eq $realStatusBefore) "7b. estado del repo real igual que antes de las pruebas"
}
finally {
    if ($root -like "*bridge-test-*") { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($script:failures -gt 0) { Write-Host "$($script:failures) prueba(s) fallida(s)"; exit 1 }
Write-Host "Todas las pruebas pasaron."
exit 0

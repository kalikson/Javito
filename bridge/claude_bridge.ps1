param(
    [int]$PollSeconds = 20,
    [switch]$RunCurrent,
    [string]$ClaudeExe = (Join-Path $env:USERPROFILE ".local\bin\claude.exe"),
    [switch]$Once
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $repoRoot

$claudeExe = $ClaudeExe
$stateDir = Join-Path $repoRoot ".claude"
$stateFile = Join-Path $stateDir "bridge_state.json"
$logFile = Join-Path $stateDir "bridge.log"

New-Item -ItemType Directory -Force -Path $stateDir | Out-Null

function Write-BridgeLog {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Write-Host $line
    Add-Content -Path $logFile -Value $line -Encoding UTF8
}

function Get-RemoteTaskSha {
    & git fetch origin main --quiet
    if ($LASTEXITCODE -ne 0) {
        throw "git fetch fallo con codigo $LASTEXITCODE"
    }

    $sha = & git rev-parse "origin/main:NEXT_TASK.md" 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $sha) {
        throw "No se pudo obtener el SHA remoto de NEXT_TASK.md"
    }

    return ($sha | Select-Object -First 1).Trim()
}

function Get-BridgeState {
    if (-not (Test-Path $stateFile)) {
        return $null
    }

    try {
        return Get-Content $stateFile -Raw | ConvertFrom-Json
    }
    catch {
        Write-BridgeLog "Estado local invalido; se reinicializara. Detalle: $($_.Exception.Message)"
        return $null
    }
}

function Save-BridgeState {
    param(
        [string]$TaskSha,
        [string]$Status,
        $ExitCode = $null
    )

    $state = [ordered]@{
        last_task_sha = $TaskSha
        status        = $Status
        updated_at    = (Get-Date).ToString("o")
    }
    if ($null -ne $ExitCode) {
        $state["exit_code"] = $ExitCode
    }
    $state | ConvertTo-Json | Set-Content -Path $stateFile -Encoding UTF8
}

function Get-DirtyPaths {
    # Solo rutas (sin contenido). Formato porcelain: "XY ruta".
    $lines = & git status --porcelain
    if ($LASTEXITCODE -ne 0) { return @() }
    return @($lines | Where-Object { $_ } | ForEach-Object { ([string]$_).Substring(3) })
}

function Get-BridgeStatusContent {
    param(
        [string]$Status,
        [string]$TaskSha,
        $ExitCode,
        [string[]]$DirtyPaths
    )

    $messages = @{
        success            = "Claude termino con codigo 0. Revisar CLAUDE_REPORT.md en main."
        blocked_dirty_tree = "El arbol de trabajo tenia cambios sin commit; Claude NO se ejecuto para esta version de NEXT_TASK.md. Requiere limpiar/commitear el arbol local o una nueva version de NEXT_TASK.md."
        pull_failed        = "git pull --ff-only fallo; Claude NO se ejecuto para esta version de NEXT_TASK.md. Revisar divergencia entre local y origin/main."
        launch_exception   = "No se pudo invocar el ejecutable de Claude. Revisar instalacion/ruta."
    }
    if ($messages.ContainsKey($Status)) {
        $message = $messages[$Status]
    }
    else {
        $message = "Claude termino con salida distinta de 0 (posible trabajo parcial local sin publicar). No se reintentara esta version de NEXT_TASK.md; el Director debe decidir el siguiente paso."
    }

    $clean = (@($DirtyPaths).Count -eq 0)
    $exitText = if ($null -ne $ExitCode) { "$ExitCode" } else { "n/a" }
    $treeText = if ($clean) { "clean" } else { "dirty" }
    $out = @(
        "# BRIDGE STATUS",
        "",
        "- status: $Status",
        "- next_task_sha: $TaskSha",
        "- timestamp: $((Get-Date).ToString('o'))",
        "- exit_code: $exitText",
        "- working_tree: $treeText"
    )
    if (-not $clean) {
        $out += "- dirty_paths:"
        foreach ($p in $DirtyPaths) { $out += "  - $p" }
    }
    $out += ""
    $out += "Mensaje: $message"
    return (($out -join "`n") + "`n")
}

function Invoke-GitIn {
    # Git en un directorio aislado dado; nunca toca el arbol principal.
    param([string]$Dir, [string[]]$GitArgs)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $out = & git -C $Dir @GitArgs 2>&1
        $code = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $prev
    }
    foreach ($l in $out) { Write-BridgeLog "[git status-channel] $l" }
    return $code
}

function Remove-BridgeTempDir {
    # Solo borra directorios creados por el propio puente dentro de %TEMP%.
    param([string]$Dir)
    if (-not $Dir) { return }
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    $full = [IO.Path]::GetFullPath($Dir)
    if ($full.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and (Split-Path $full -Leaf) -like "bridge-status-*") {
        Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Publish-BridgeStatus {
    param(
        [string]$Status,
        [string]$TaskSha,
        $ExitCode = $null,
        [string[]]$DirtyPaths = @()
    )

    $tmp = $null
    try {
        $origin = (& git remote get-url origin | Select-Object -First 1)
        if ($LASTEXITCODE -ne 0 -or -not $origin) { throw "No se pudo obtener la URL de origin" }
        $name = (& git config user.name | Select-Object -First 1)
        $email = (& git config user.email | Select-Object -First 1)
        if (-not $name) { $name = "claude-bridge" }
        if (-not $email) { $email = "claude-bridge@localhost" }

        $tmp = Join-Path ([IO.Path]::GetTempPath()) ("bridge-status-" + [guid]::NewGuid().ToString("N"))
        New-Item -ItemType Directory -Path $tmp | Out-Null

        if ((Invoke-GitIn $tmp @("init", "-q")) -ne 0) { throw "git init fallo" }
        if ((Invoke-GitIn $tmp @("remote", "add", "origin", $origin)) -ne 0) { throw "git remote add fallo" }

        $lsCode = Invoke-GitIn $tmp @("ls-remote", "--exit-code", "--heads", "origin", "bridge-status")
        if ($lsCode -eq 0) {
            if ((Invoke-GitIn $tmp @("fetch", "-q", "origin", "bridge-status")) -ne 0) { throw "fetch de bridge-status fallo" }
            if ((Invoke-GitIn $tmp @("checkout", "-q", "-B", "bridge-status", "FETCH_HEAD")) -ne 0) { throw "checkout de bridge-status fallo" }
        }
        elseif ($lsCode -eq 2) {
            # Rama nueva sin historia compartida con main: nada de main viaja con ella.
            if ((Invoke-GitIn $tmp @("checkout", "-q", "--orphan", "bridge-status")) -ne 0) { throw "checkout --orphan fallo" }
        }
        else {
            throw "git ls-remote fallo con codigo $lsCode"
        }

        $content = Get-BridgeStatusContent -Status $Status -TaskSha $TaskSha -ExitCode $ExitCode -DirtyPaths $DirtyPaths
        [IO.File]::WriteAllText((Join-Path $tmp "BRIDGE_STATUS.md"), $content, (New-Object Text.UTF8Encoding($false)))

        if ((Invoke-GitIn $tmp @("add", "BRIDGE_STATUS.md")) -ne 0) { throw "git add fallo" }
        $commitArgs = @("-c", "user.name=$name", "-c", "user.email=$email", "commit", "-q", "-m", "Bridge status: $Status")
        if ((Invoke-GitIn $tmp $commitArgs) -ne 0) { throw "git commit fallo" }
        if ((Invoke-GitIn $tmp @("push", "-q", "origin", "bridge-status:refs/heads/bridge-status")) -ne 0) { throw "git push a bridge-status fallo" }

        Write-BridgeLog "Estado '$Status' publicado en la rama bridge-status."
    }
    catch {
        Write-BridgeLog "No se pudo publicar el estado '$Status': $($_.Exception.Message)"
    }
    finally {
        Remove-BridgeTempDir -Dir $tmp
    }
}

function Stop-TaskWithStatus {
    # Marca esta version de NEXT_TASK.md como atendida (sin reintentos) y publica el estado.
    param(
        [string]$TaskSha,
        [string]$Status,
        $ExitCode = $null,
        [string[]]$DirtyPaths = @()
    )
    Save-BridgeState -TaskSha $TaskSha -Status $Status -ExitCode $ExitCode
    Publish-BridgeStatus -Status $Status -TaskSha $TaskSha -ExitCode $ExitCode -DirtyPaths $DirtyPaths
}

function Invoke-CurrentTask {
    param([string]$TaskSha)

    $dirty = & git status --porcelain
    if ($LASTEXITCODE -ne 0) {
        Write-BridgeLog "No se pudo consultar git status."
        return
    }

    if ($dirty) {
        Write-BridgeLog "Hay cambios locales sin commit. No se ejecuta Claude para esta version de la tarea; se conservan los cambios."
        Stop-TaskWithStatus -TaskSha $TaskSha -Status "blocked_dirty_tree" -DirtyPaths (Get-DirtyPaths)
        return
    }

    Write-BridgeLog "Nueva tarea detectada. Actualizando repositorio..."

    # Git escribe mensajes informativos de fetch/pull por stderr aun cuando el
    # comando termina correctamente. En Windows PowerShell, con
    # ErrorActionPreference=Stop, redirigir ese stderr directamente dentro de
    # PowerShell puede convertir mensajes como 'From https://github.com/...'
    # en una excepcion. Hacemos la redireccion dentro de cmd.exe para que el
    # puente reciba una sola corriente de texto y use el codigo de salida real.
    $pullOutput = & cmd.exe /d /c "git pull --ff-only origin main 2>&1"
    $pullExit = $LASTEXITCODE

    foreach ($line in $pullOutput) {
        Write-BridgeLog "[git pull] $line"
    }

    if ($pullExit -ne 0) {
        Write-BridgeLog "git pull fallo con codigo $pullExit. No se repetira esta misma tarea automaticamente."
        Stop-TaskWithStatus -TaskSha $TaskSha -Status "pull_failed" -ExitCode $pullExit
        return
    }

    $prompt = @"
Lee CLAUDE.md, MASTER.md, ADN_APP.md y NEXT_TASK.md.
Ejecuta exactamente la tarea vigente y no decidas la siguiente tarea.
Usa los permisos persistentes del proyecto.
Si necesitas una decision que no este resuelta por los documentos, responde unicamente como PREGUNTA ABIERTA en texto, nunca con checkpoint, botones, selectores ni formularios.
Al terminar, actualiza CLAUDE_REPORT.md con el estado y las validaciones realizadas, haz commit de tus cambios y haz git push.
"@

    Write-BridgeLog "Lanzando Claude Code..."
    $prevEap = $ErrorActionPreference
    try {
        # El stderr de Claude no debe convertirse en excepcion; solo cuenta el codigo de salida.
        $ErrorActionPreference = "Continue"
        $claudeOutput = & $claudeExe -p $prompt --permission-prompts none 2>&1
        $claudeExit = $LASTEXITCODE
    }
    catch {
        $ErrorActionPreference = $prevEap
        Write-BridgeLog "Excepcion al lanzar Claude: $($_.Exception.Message). No se repetira esta misma tarea automaticamente."
        Stop-TaskWithStatus -TaskSha $TaskSha -Status "launch_exception" -DirtyPaths (Get-DirtyPaths)
        return
    }
    $ErrorActionPreference = $prevEap

    foreach ($line in $claudeOutput) {
        Write-BridgeLog "[Claude] $line"
    }

    $dirtyAfter = Get-DirtyPaths

    if ($claudeExit -eq 0) {
        Stop-TaskWithStatus -TaskSha $TaskSha -Status "success" -ExitCode 0 -DirtyPaths $dirtyAfter
        Write-BridgeLog "Claude termino. Esperando una nueva version de NEXT_TASK.md."
    }
    else {
        Stop-TaskWithStatus -TaskSha $TaskSha -Status ("claude_exit_{0}" -f $claudeExit) -ExitCode $claudeExit -DirtyPaths $dirtyAfter
        Write-BridgeLog "Claude termino con codigo $claudeExit. No se repetira esta misma tarea automaticamente."
    }
}

if (-not (Test-Path $claudeExe)) {
    throw "No se encontro Claude Code en $claudeExe"
}

Write-BridgeLog "Puente iniciado en $repoRoot. Intervalo: $PollSeconds segundos."

$initialTaskSha = Get-RemoteTaskSha
$state = Get-BridgeState

if ($RunCurrent) {
    Write-BridgeLog "RunCurrent activo: se ejecutara la tarea remota actual."
    Invoke-CurrentTask -TaskSha $initialTaskSha
}
elseif ($null -eq $state -or -not $state.last_task_sha) {
    Save-BridgeState -TaskSha $initialTaskSha -Status "initialized"
    Write-BridgeLog "Estado inicial guardado. La tarea actual NO se reejecutara. Esperando un cambio en NEXT_TASK.md."
}
else {
    Write-BridgeLog "Estado existente cargado. Esperando cambios en NEXT_TASK.md."
}

while ($true) {
    if (-not $Once) { Start-Sleep -Seconds $PollSeconds }

    try {
        $remoteTaskSha = Get-RemoteTaskSha
        $state = Get-BridgeState

        if ($null -eq $state -or $state.last_task_sha -ne $remoteTaskSha) {
            Write-BridgeLog "Cambio detectado en NEXT_TASK.md: $remoteTaskSha"
            Invoke-CurrentTask -TaskSha $remoteTaskSha
        }
    }
    catch {
        Write-BridgeLog "Error de vigilancia: $($_.Exception.Message)"
    }

    if ($Once) { break }
}

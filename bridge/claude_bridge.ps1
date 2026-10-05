param(
    [int]$PollSeconds = 20,
    [switch]$RunCurrent
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $repoRoot

$claudeExe = Join-Path $env:USERPROFILE ".local\bin\claude.exe"
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
        [string]$Status
    )

    [ordered]@{
        last_task_sha = $TaskSha
        status        = $Status
        updated_at    = (Get-Date).ToString("o")
    } | ConvertTo-Json | Set-Content -Path $stateFile -Encoding UTF8
}

function Invoke-CurrentTask {
    param([string]$TaskSha)

    $dirty = & git status --porcelain
    if ($LASTEXITCODE -ne 0) {
        Write-BridgeLog "No se pudo consultar git status."
        return
    }

    if ($dirty) {
        Write-BridgeLog "Hay cambios locales sin commit. No se ejecutara Claude hasta que el arbol de trabajo este limpio."
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
        Write-BridgeLog "git pull fallo con codigo $pullExit. Se reintentara en el siguiente ciclo."
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
    $claudeOutput = & $claudeExe -p $prompt --permission-prompts none 2>&1
    $claudeExit = $LASTEXITCODE

    foreach ($line in $claudeOutput) {
        Write-BridgeLog "[Claude] $line"
    }

    Save-BridgeState -TaskSha $TaskSha -Status ("claude_exit_{0}" -f $claudeExit)

    if ($claudeExit -eq 0) {
        Write-BridgeLog "Claude termino. Esperando una nueva version de NEXT_TASK.md."
    }
    else {
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
    Start-Sleep -Seconds $PollSeconds

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
}
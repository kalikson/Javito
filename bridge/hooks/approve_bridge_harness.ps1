$ErrorActionPreference = "Stop"

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { return }

    $request = $raw | ConvertFrom-Json
    $expectedCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File bridge/test_claude_bridge.ps1"

    $repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    $requestCwd = if ($request.cwd) { [IO.Path]::GetFullPath([string]$request.cwd) } else { "" }
    $toolName = [string]$request.tool_name
    $eventName = [string]$request.hook_event_name
    $command = if ($request.tool_input -and $request.tool_input.command) { ([string]$request.tool_input.command).Trim() } else { "" }

    $sameRoot = [string]::Equals(
        $repoRoot.TrimEnd('\', '/'),
        $requestCwd.TrimEnd('\', '/'),
        [StringComparison]::OrdinalIgnoreCase
    )

    if ($eventName -eq "PermissionRequest" -and
        $toolName -eq "Bash" -and
        $command -ceq $expectedCommand -and
        $sameRoot) {

        $response = [ordered]@{
            hookSpecificOutput = [ordered]@{
                hookEventName = "PermissionRequest"
                decision = [ordered]@{
                    behavior = "allow"
                }
            }
        }

        $response | ConvertTo-Json -Depth 6 -Compress
    }
}
catch {
    # Fail closed: any parse/path/runtime error produces no allow decision.
    return
}

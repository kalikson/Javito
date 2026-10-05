# NEXT TASK

## Tarea 005-F — Instalar hook mínimo de permiso para el harness

### Estado del Director
**CORREGIR / DESBLOQUEO TÉCNICO.** La Tarea 005-E confirmó que ni la regla `permissions.allow` de PowerShell ni la regla exacta de Bash resolvieron la petición antes de `--permission-prompts none`.

La documentación actual de Claude Code establece que, en sesiones no interactivas, los hooks `PermissionRequest` sí se ejecutan antes de la denegación final y pueden responder `allow`. Vamos a usar ese mecanismo, limitado exclusivamente al harness de esta prueba.

### Objetivo
Preparar un hook versionado y auditable que autorice **solo** la ejecución exacta del harness de puente y ninguna otra petición de permiso. No ejecutar todavía el harness en esta tarea; el hook se validará en una sesión nueva mediante la siguiente versión de `NEXT_TASK.md`.

### Implementación exacta
1. Leer `MASTER.md`, `ADN_APP.md`, `CLAUDE.md`, esta tarea, `.claude/settings.json` y `CLAUDE_REPORT.md`.
2. Crear `.claude/hooks/approve_bridge_harness.ps1`.
3. El hook debe leer el JSON de entrada desde stdin y únicamente devolver una decisión `allow` cuando se cumplan **todas** estas condiciones:
   - `hook_event_name` es `PermissionRequest`;
   - `tool_name` es `Bash`;
   - `tool_input.command`, después de `Trim()`, es exactamente:
     `powershell.exe -NoProfile -ExecutionPolicy Bypass -File bridge/test_claude_bridge.ps1`
   - `cwd`, normalizado con `GetFullPath`, coincide con la raíz real del repositorio Javito calculada desde la propia ubicación del hook (`.claude/hooks` -> dos niveles arriba).
4. Cuando las condiciones coincidan, escribir en stdout JSON válido con esta semántica:
   - `hookSpecificOutput.hookEventName = "PermissionRequest"`
   - `hookSpecificOutput.decision.behavior = "allow"`
5. Para cualquier otra herramienta, comando o directorio:
   - no autorizar;
   - no emitir una decisión `allow`;
   - terminar normalmente para que el flujo estándar de permisos decida y, con `--permission-prompts none`, lo deniegue.
6. El hook no debe modificar archivos, ejecutar el harness, ejecutar git, cambiar permisos ni persistir una autorización más amplia.
7. Actualizar `.claude/settings.json` para:
   - retirar la regla `permissions.allow` temporal de Bash que ya demostró no resolver el caso;
   - configurar `hooks.PermissionRequest` con `matcher: "Bash"`;
   - ejecutar como hook exactamente:
     `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .claude/hooks/approve_bridge_harness.ps1`
8. No añadir `PowerShell(*)`, `Bash(*)`, `bypassPermissions`, `auto` ni otra autorización amplia.

### Validación de esta tarea
Esta tarea es únicamente de instalación del mecanismo; **no ejecutes el harness todavía**, porque la sesión actual ya quedó marcada sin superficie de aprobación y el nuevo hook debe cargarse desde el inicio de una sesión nueva.

Verifica por inspección:
- JSON válido y estructura correcta de `.claude/settings.json`;
- el hook contiene comparación exacta del comando;
- el hook comprueba también la raíz del repositorio;
- no hay una ruta que autorice otras órdenes Bash;
- no quedan reglas amplias de permisos.

No uses un comando PowerShell para validar la sintaxis del hook en esta sesión si eso requiere aprobación. No inventes resultados dinámicos.

### CLAUDE_REPORT.md obligatorio
Reportar:
- estado `COMPLETADO` o `BLOQUEADO`;
- tarea `005-F`;
- archivos modificados;
- contenido lógico exacto del filtro del hook;
- estructura final de `.claude/settings.json`;
- confirmación de que el harness NO se ejecutó en esta tarea;
- confirmación de que no se añadió permiso amplio;
- cualquier riesgo o duda real para el Director.

### Prohibido
- No ejecutar el harness en esta tarea.
- No cambiar `bridge/claude_bridge.ps1` ni `bridge/test_claude_bridge.ps1`.
- No modificar `MASTER.md`, `ADN_APP.md`, `CLAUDE.md`, `NEXT_TASK.md`, `lib/` ni `test/`.
- No usar permisos globales o bypass.
- No pedir intervención de Javier.
- No usar checkpoint, botones, selectores ni formularios interactivos.
- No decidir ni escribir la siguiente tarea.

### Al terminar
Actualizar `CLAUDE_REPORT.md`, hacer commit y `git push` a `main`. No modificar `NEXT_TASK.md`.
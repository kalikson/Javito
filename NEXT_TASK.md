# NEXT TASK

## Tarea 005-E — Cerrar validación del puente usando el comando Bash autorizado

### Estado del Director
**CORREGIR / DESBLOQUEO TÉCNICO.** La Tarea 005 sigue sin aprobarse únicamente porque el harness no ha podido ejecutarse. No hace falta intervención de Javier.

El permiso temporal anterior de PowerShell no coincidió con el parser de permisos. El Director verificó la sintaxis actual de Claude Code y reemplazó `.claude/settings.json` por una única regla `Bash(...)` que autoriza exactamente un comando.

### Objetivo
Ejecutar realmente el harness completo de la Tarea 005, corregir solo defectos demostrados y dejar evidencia verificable de todos los escenarios.

### Comando obligatorio
Usa **la herramienta Bash de Claude Code**, no la herramienta PowerShell, y ejecuta exactamente esta cadena desde la raíz del repositorio:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File bridge/test_claude_bridge.ps1
```

No añadas `2>&1`, `&&`, `;`, tuberías, prefijos, sufijos ni argumentos adicionales a esa invocación. La regla temporal está limitada deliberadamente a ese comando exacto.

### Procedimiento
1. Leer `MASTER.md`, `ADN_APP.md`, `CLAUDE.md`, esta tarea, `bridge/claude_bridge.ps1`, `bridge/test_claude_bridge.ps1`, `CLAUDE_REPORT.md` y `.claude/settings.json`.
2. Ejecutar el comando obligatorio anterior mediante Bash.
3. El harness ya incluye comprobación de sintaxis; registrar su resultado real.
4. Si el harness falla por un defecto demostrado:
   - identificar si el fallo está en `bridge/test_claude_bridge.ps1` o en `bridge/claude_bridge.ps1`;
   - aplicar la corrección mínima;
   - volver a ejecutar **exactamente el mismo comando Bash autorizado**;
   - repetir hasta que todas las pruebas pasen o aparezca un bloqueo técnico nuevo y concreto.
5. No usar Claude real para simular fallos. Los stubs y remotes deben seguir siendo temporales/locales.
6. No ejecutar el puente real del repositorio durante las simulaciones.

### Debe quedar probado realmente
- cero errores de sintaxis en `bridge/claude_bridge.ps1`;
- cero errores de sintaxis en `bridge/test_claude_bridge.ps1`;
- `claude_exit_7` y `exit_code = 7`;
- la misma versión de `NEXT_TASK.md` no se relanza;
- una versión nueva sí se procesa;
- `BRIDGE_STATUS.md` se crea/actualiza únicamente en `bridge-status` del remote bare temporal;
- stdout/stderr del stub no se copia a `BRIDGE_STATUS.md`;
- `main` del remote temporal queda intacto por la publicación del estado;
- árbol sucio produce `blocked_dirty_tree`, no ejecuta Claude y conserva los cambios;
- un commit local parcial no se propaga al remote ni a `bridge-status`;
- `pull_failed` se registra/publica, no ejecuta Claude y no reintenta la misma versión;
- `launch_exception` se registra/publica sin usar Claude real y no reintenta la misma versión;
- el repositorio real conserva su estado salvo los cambios intencionales de esta tarea.

### Permiso temporal
**No elimines ni modifiques `.claude/settings.json` en esta tarea.** Si todas las pruebas pasan, el Director lo retirará directamente después de auditar tu commit. Esto evita necesitar un segundo permiso de shell.

### Validaciones obligatorias
- El harness completo debe finalizar satisfactoriamente con todas las pruebas PASS.
- Revisar `git diff` antes del commit.
- No modificar `MASTER.md`, `ADN_APP.md`, `CLAUDE.md`, `NEXT_TASK.md`, `lib/` ni `test/`.
- `bridge/claude_bridge.ps1` solo puede cambiar si una prueba demuestra un defecto real.
- No reiniciar, matar ni duplicar el puente real.
- No usar `git reset`, `git clean` ni `git stash`.
- Confirmar que ninguna prueba hizo push a GitHub real.

### CLAUDE_REPORT.md obligatorio
Reportar:
- estado `COMPLETADO` o `BLOQUEADO`;
- tarea `005-E`;
- comando exacto ejecutado y confirmación de que se usó la herramienta Bash;
- archivos modificados;
- resultados reales de sintaxis;
- resultados individuales de todos los escenarios anteriores;
- cualquier fallo encontrado y la corrección aplicada;
- número de ejecuciones del harness hasta llegar al resultado final;
- confirmación de que no se usó Claude real para simular fallos;
- confirmación de que no hubo push de prueba a GitHub real;
- confirmación de que el repositorio real quedó preservado;
- confirmación de que el puente real no fue reiniciado ni duplicado;
- riesgos pendientes reales;
- decisiones pendientes para ChatGPT Director.

### Si el comando Bash exacto también es bloqueado
No pruebes comandos alternativos y no pidas intervención de Javier. Registra literalmente el bloqueo y deja estado `BLOQUEADO`. El Director decidirá el siguiente mecanismo.

### Prohibido
- No pedir intervención de Javier.
- No usar checkpoint, botones, selectores ni formularios interactivos.
- No decidir ni escribir la Tarea 006.

### Al terminar
Actualizar `CLAUDE_REPORT.md`, hacer commit y `git push` a `main`. No modificar `NEXT_TASK.md`.
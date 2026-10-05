# NEXT TASK

## Tarea 005-C — Ejecutar y cerrar la validación segura del puente

### Estado del Director
**CORREGIR.** La implementación de la Tarea 005 no puede aprobarse todavía porque las pruebas obligatorias no se ejecutaron. No hace falta una decisión de Javier: el bloqueo es técnico y debe resolverse dentro de esta tarea correctiva.

### Objetivo
Validar de verdad la implementación ya realizada para `bridge-status`, corrigiendo únicamente lo necesario para que las pruebas puedan ejecutarse sin depender de lanzar un PowerShell anidado que la sesión de Claude Code no puede aprobar.

No avanzar a Tarea 006 hasta que esta validación quede cerrada.

### Implementación exacta

#### A. Eliminar el bloqueo del PowerShell anidado
1. Leer `MASTER.md`, `ADN_APP.md`, `CLAUDE.md`, esta tarea, `bridge/claude_bridge.ps1`, `bridge/test_claude_bridge.ps1` y el último `CLAUDE_REPORT.md`.
2. Modificar `bridge/test_claude_bridge.ps1` para que **no lance `powershell.exe`, `pwsh.exe` ni otro proceso PowerShell hijo para ejecutar el puente**.
3. La prueba debe seguir copiando `bridge/claude_bridge.ps1` al fixture/repositorio temporal y ejecutar **esa copia temporal** dentro del proceso PowerShell actual mediante el operador de llamada `&` o mecanismo equivalente en el mismo host.
4. La función de prueba que invoque el puente debe:
   - guardar la ubicación actual antes de ejecutar la copia temporal;
   - ejecutar la copia del puente del fixture con `-Once`, `-ClaudeExe <stub>` y `-RunCurrent` cuando corresponda;
   - restaurar siempre la ubicación original en un `finally`, aunque el puente falle;
   - no ejecutar nunca el puente real del repositorio de trabajo como parte de la simulación.
5. Si la ejecución directa del `.ps1` en el host actual requiere un ajuste menor del harness, hacerlo dentro del archivo de pruebas. No cambiar la política de ejecución del sistema ni pedir aprobación interactiva.

#### B. Ejecutar las pruebas existentes de la Tarea 005
Ejecutar realmente el harness y comprobar como mínimo:
1. salida `7` produce `claude_exit_7` y guarda `exit_code = 7`;
2. la misma versión de `NEXT_TASK.md` no relanza Claude automáticamente;
3. una versión nueva sí puede ejecutarse;
4. `BRIDGE_STATUS.md` se crea/actualiza únicamente en `bridge-status` del remote bare temporal;
5. stdout/stderr de Claude no se copia al archivo de estado;
6. `main` del remote temporal no cambia por publicar estado;
7. árbol sucio produce `blocked_dirty_tree`, no ejecuta Claude y conserva intactos los cambios;
8. un commit local parcial de Claude no llega ni a `main` remoto ni a `bridge-status`;
9. el repositorio real conserva el mismo estado que tenía antes de iniciar las pruebas.

#### C. Añadir cobertura de los dos casos que quedaron sin prueba
Añadir dos escenarios aislados al harness, sin tocar GitHub real:

**`pull_failed`**
- usar un fixture temporal limpio cuyo `main` local y `origin/main` estén divergidos de forma controlada;
- hacer que exista una versión remota de `NEXT_TASK.md` asociada a la prueba;
- confirmar que `git pull --ff-only` falla;
- confirmar estado local `pull_failed`;
- confirmar publicación `status: pull_failed` en `bridge-status`;
- confirmar que Claude no fue ejecutado;
- confirmar que la misma versión no se reintenta automáticamente.

**`launch_exception`**
- provocar una excepción de lanzamiento sin usar Claude real y sin borrar archivos; por ejemplo, pasar como `ClaudeExe` una ruta existente que no sea ejecutable, siempre que pase la comprobación inicial de existencia y falle al invocarse;
- confirmar estado local `launch_exception`;
- confirmar publicación `status: launch_exception` en `bridge-status`;
- confirmar que la misma versión no se reintenta automáticamente.

Si el método propuesto para provocar `launch_exception` no genera una excepción real en este PowerShell, usar otro fixture inocuo y local que sí la produzca. No modificar el sistema ni utilizar el Claude real para forzar el fallo.

#### D. Corregir solo fallos demostrados
1. Si alguna prueba falla por un defecto real de `bridge/claude_bridge.ps1`, corregir ese defecto de forma mínima.
2. Si falla únicamente el harness, corregir únicamente `bridge/test_claude_bridge.ps1`.
3. No refactorizar el puente por estilo ni ampliar alcance.
4. Mantener la decisión ya tomada por el Director:
   - sin reintentos automáticos de ejecuciones fallidas;
   - preservar trabajo parcial;
   - estado remoto aislado en `bridge-status`;
   - ningún commit automático de fallo a `main`.

### Validaciones obligatorias
- Ejecutar el harness completo y obtener **todas las pruebas PASS**.
- Hacer una comprobación de sintaxis de los scripts PowerShell sin lanzar un proceso PowerShell hijo, por ejemplo mediante el parser disponible en el host actual.
- Revisar `git diff` antes del commit.
- El diff debe limitarse a los archivos estrictamente necesarios para cerrar Tarea 005-C y `CLAUDE_REPORT.md`.
- No modificar `lib/`, `test/`, `MASTER.md`, `ADN_APP.md`, `CLAUDE.md` ni `NEXT_TASK.md`.
- No reiniciar, matar ni duplicar el puente real.
- Confirmar explícitamente que las pruebas usaron únicamente repositorios/remotes temporales y que no hicieron push a `origin/main` real.

### Si la sesión sigue impidiendo ejecutar el harness
No pedir intervención de Javier y no marcar la tarea como completada.

Primero intenta la ejecución en el proceso PowerShell actual, sin `powershell.exe`/`pwsh.exe` hijos. Si la plataforma bloquea incluso esa ejecución, documenta exactamente el comando/mecanismo bloqueado y deja `BLOQUEADO` en `CLAUDE_REPORT.md`; no inventes resultados ni aceptes la implementación sin pruebas.

### Contenido obligatorio de `CLAUDE_REPORT.md`
- estado `COMPLETADO` o `BLOQUEADO`;
- tarea `005-C`;
- archivos modificados;
- causa original del bloqueo y cómo se eliminó;
- comando o mecanismo exacto usado para ejecutar las pruebas sin PowerShell anidado;
- resultados individuales de todos los escenarios, incluyendo `claude_exit_7`, no reintento, actualización de tarea, árbol sucio, commit parcial, `pull_failed`, `launch_exception` y preservación del repo real;
- resultado de comprobación de sintaxis;
- cualquier corrección aplicada a `bridge/claude_bridge.ps1` y la prueba que demostró su necesidad;
- confirmación de que ninguna prueba hizo push a `origin/main` real;
- confirmación de que el puente real no fue reiniciado ni duplicado;
- si la nueva versión del puente sigue necesitando reinicio manual para quedar activa;
- riesgos pendientes reales, si queda alguno;
- decisiones pendientes para ChatGPT Director.

### Prohibido
- No usar Claude real para simular fallos.
- No ejecutar pruebas destructivas sobre el repositorio real.
- No usar `git reset`, `git clean`, `git stash` ni descartar cambios del usuario.
- No hacer push de pruebas a GitHub real.
- No lanzar PowerShell anidado para ejecutar el puente de prueba.
- No reiniciar ni lanzar un segundo puente real.
- No pedir intervención de Javier.
- No usar checkpoint, botones, selectores ni formularios interactivos.
- No decidir ni escribir la Tarea 006.

### Al terminar
Actualizar `CLAUDE_REPORT.md`, hacer commit y `git push` de los cambios necesarios a `main`. No modificar `NEXT_TASK.md` y no decidir la siguiente tarea.
# CLAUDE REPORT

## Estado
COMPLETADO

## Tarea
Tarea 004 — Auditar manejo de salida no cero de Claude Code

## Archivos modificados
- `CLAUDE_REPORT.md` (único archivo modificado)

Referencias: todas las líneas citadas son de `bridge/claude_bridge.ps1` (auditoría de solo lectura; el script no se modificó).

## Comportamiento actual ante `$claudeExit -ne 0`
Flujo en `Invoke-CurrentTask` (líneas 66-124):

1. **Qué se guarda en `bridge_state.json`**: la línea 116 llama a `Save-BridgeState` (definida en 53-64) **incondicionalmente**, antes del `if ($claudeExit -eq 0)` de la línea 118. Se escribe `{ last_task_sha = <sha remoto de NEXT_TASK.md>, status = "claude_exit_<N>", updated_at = <ISO> }`. El código de salida distinto de 0 solo se distingue por el texto de `status`.
2. **`last_task_sha` queda actualizado**: sí. Es el mismo valor que se guarda con salida 0 (`$TaskSha` recibido como parámetro, línea 67/116). Nada en el script lee `status` para decidir nada.
3. **¿El `while` reejecuta la misma tarea?** No. El bucle (147-162) solo invoca `Invoke-CurrentTask` si `$state.last_task_sha -ne $remoteTaskSha` (línea 154). Como la línea 116 ya igualó ambos valores, la misma versión de `NEXT_TASK.md` no se reintenta. La línea 122 lo confirma en el log ("No se repetira esta misma tarea automaticamente"). Un reintento solo ocurre si cambia el SHA de `NEXT_TASK.md`, si se borra/corrompe el estado (`Get-BridgeState`, 39-51, devuelve `$null` → línea 154 es verdadera) o si se arranca con `-RunCurrent` (135-138).
4. **Visible solo en el log local**: todo el stdout/stderr de Claude (líneas 109 y 112-114, con `2>&1`), el valor numérico del código de salida (líneas 116 y 122), la salida de `git pull` (91-93) y los avisos de árbol sucio o pull fallido (76, 96). El log es `.claude/bridge.log` y el estado `.claude/bridge_state.json`; ambos están en `.gitignore` (líneas 50-51), así que **nunca llegan a GitHub**.
5. **Qué llega a GitHub**: nada generado por el puente. Solo llega lo que el propio Claude alcance a commitear y pushear antes de morir. Si falla antes de actualizar/pushear `CLAUDE_REPORT.md`, el reporte remoto sigue siendo el de la tarea anterior y ChatGPT Director no tiene ninguna señal de fallo en el repositorio.

Detalle adicional relevante: el bloque de arranque (139-142) y el bucle usan el mismo estado, por lo que reiniciar el puente tras un fallo tampoco reejecuta la tarea (línea 144: "Estado existente cargado").

## Riesgos encontrados
1. **Pérdida silenciosa de tarea**: una tarea fallida queda marcada como procesada (línea 116 incondicional). Solo se entera quien lea el log local.
2. **Director a ciegas**: sin commit del puente ni de Claude, GitHub no refleja el fallo; el Director podría interpretar el reporte viejo como resultado de la tarea nueva o esperar indefinidamente.
3. **Árbol sucio posterior**: si Claude dejó cambios sin commit al fallar, la siguiente invocación cae en la línea 75-78 y **no ejecuta nada** (solo registra el aviso) mientras el árbol esté sucio. Como el estado no se actualiza en esa rama, el aviso se repite cada ciclo (cada `PollSeconds`) → ruido de log y bloqueo hasta intervención manual. Esto afecta incluso a la tarea siguiente (Tarea N+1), que no arrancaría.
4. **Intervención manual necesaria**: recuperar requiere editar/borrar `bridge_state.json`, usar `-RunCurrent`, o cambiar `NEXT_TASK.md`.
5. **Commit/push parcial**: Claude pudo haber commiteado sin hacer push (o viceversa); el puente no lo verifica y el `git pull --ff-only` del siguiente ciclo podría fallar o divergir (línea 95-98 reintenta indefinidamente, sin actualizar estado).
6. **Reintentos infinitos (acotados a otras ramas)**: no existen para la salida no cero, pero sí para `git pull` fallido (95-98) y árbol sucio (75-78), porque en ambos `return` no guarda estado y la condición de la línea 154 sigue siendo verdadera.
7. **Excepciones no controladas**: si `& $claudeExe` lanzara una excepción (p. ej. ejecutable dañado), con `$ErrorActionPreference = "Stop"` (línea 6) iría al `catch` de la línea 159 sin ejecutar la línea 116: en ese caso el estado **no** se actualiza y se reintentaría en cada ciclo. Comportamiento distinto al de salida no cero, y también sin señal en GitHub.
8. **Observación sin verificar**: la línea 109 usa `--permission-prompts none`; no he comprobado en esta tarea que esa opción exista en la versión instalada de Claude Code (no se ejecutó Claude, por la prohibición de provocar fallos). Si no existiera, produciría precisamente una salida no cero en cada ejecución. Se sugiere verificarlo con `claude --help` (acción de solo lectura) cuando el Director lo decida.

## Alternativas técnicas (máximo 3)

### Alternativa 1 — Marcar fallo y notificar vía GitHub con un commit del puente
- **Comportamiento**: si `$claudeExit -ne 0`, el puente conserva `last_task_sha` (no repite), pero escribe un archivo versionado (p. ej. un bloque en `CLAUDE_REPORT.md` o `BRIDGE_FAILURE.md`) con código de salida, fecha, SHA de tarea y cola del log, y hace commit + push solo de ese archivo.
- **Ventajas**: ChatGPT Director se entera por GitHub sin intervención humana; no hay reintentos automáticos.
- **Riesgos**: el commit del puente puede fallar (red/credenciales) y vuelve a ser silencioso; puede sobrescribir un `CLAUDE_REPORT.md` parcial de Claude; exige `git add` selectivo para no arrastrar cambios de Claude.
- **Impacto en árbol local**: si hay cambios sin commit de Claude, se dejan intactos (add selectivo); el árbol seguirá sucio y bloqueará la siguiente tarea (riesgo 3) salvo que se combine con detección de ese caso.
- **¿Director se entera por GitHub?** Sí, si el push tiene éxito.

### Alternativa 2 — No marcar como procesada (estado `failed`) y reintentar con límite
- **Comportamiento**: ante salida no cero, guardar `status=failed` y un contador de intentos; no igualar `last_task_sha` hasta éxito o hasta N intentos (p. ej. 2), tras los cuales se marca como agotada y se detiene.
- **Ventajas**: tolera fallos transitorios (red, límite de uso) sin intervención; evita pérdida silenciosa en el primer fallo.
- **Riesgos**: requiere cambiar `Save-BridgeState`/condición de la línea 154; Claude puede repetir acciones parciales (commits duplicados); sigue sin informar a GitHub durante los reintentos; si no hay tope, bucle infinito.
- **Impacto en árbol local**: el reintento choca con cambios sin commit del intento anterior (línea 75-78), así que **sin tratamiento del árbol sucio no reintenta realmente**; limpiarlo sería destructivo y no se propone sin decisión del Director.
- **¿Director se entera por GitHub?** No por sí sola; solo si agota intentos y se combina con la Alternativa 1.

### Alternativa 3 — Fallo “duro”: detener el puente y requerir intervención explícita, con bandera local
- **Comportamiento**: ante salida no cero, guardar `status=failed_needs_attention`, escribir un archivo local de bandera, y hacer que el bucle se pause (no ejecute más tareas) hasta que alguien limpie la bandera.
- **Ventajas**: la más simple y segura; ninguna tarea posterior corre sobre un estado dudoso; no toca git ni el árbol.
- **Riesgos**: sin notificación a GitHub el Director sigue a ciegas; frena todo el flujo automático y requiere a Javier, lo que contradice el objetivo de mínima intervención humana.
- **Impacto en árbol local**: ninguno (no toca nada); el trabajo parcial se preserva para inspección.
- **¿Director se entera por GitHub?** No.

## Propuesta de prueba reproducible y segura (no ejecutada)
Objetivo: simular salida no cero sin lanzar Claude real y sin tocar el repo de trabajo.

1. Añadir (en una tarea futura autorizada) un parámetro de prueba al puente, p. ej. `-ClaudeExePath`, que por defecto siga siendo `$env:USERPROFILE\.local\bin\claude.exe`.
2. Crear un **stub** fuera del repo (p. ej. `%TEMP%\fake_claude.cmd`) que imprima un par de líneas y ejecute `exit 7`.
3. Clonar el repo a un **directorio temporal** (`git clone C:\dev\Pruebas\Javito %TEMP%\bridge_test`) y ejecutar allí el puente con `-RunCurrent -ClaudeExePath <stub>`. Así `.claude/bridge_state.json`, `bridge.log` y cualquier commit son del clon, no del repo real.
4. Para que no haya push accidental, configurar en el clon `git remote set-url --push origin NO_PUSH` (o apuntar a un bare repo local temporal).
5. Verificar: (a) `bridge_state.json` contiene `status=claude_exit_7` y el `last_task_sha` esperado; (b) el log contiene "No se repetira"; (c) un segundo ciclo no relanza el stub; (d) con un archivo sin commit creado antes en el clon, se observa el bloqueo por árbol sucio (riesgo 3); (e) `git status` del repo real sigue limpio.
6. Borrar el directorio temporal al terminar (solo ese directorio, creado para la prueba).

Alternativa sin modificar el puente: copiar `bridge/claude_bridge.ps1` al clon temporal y sustituir allí la línea 11 por la ruta del stub; el original queda intacto.

## Recomendación técnica de Claude (no es una decisión)
Combinar la Alternativa 1 (notificación versionada a GitHub, con `git add` selectivo y sin tocar cambios ajenos) con la lógica de la Alternativa 3 limitada al caso de árbol sucio (aviso una sola vez, no cada ciclo), y no reintentar automáticamente. Motivo: el mayor riesgo actual es que el Director no se entere (riesgos 1-2), y los reintentos sobre un árbol potencialmente parcial añaden riesgo sin beneficio claro. Antes de eso, verificar la opción `--permission-prompts` (riesgo 8).

## Validaciones realizadas
- Lectura de `MASTER.md`, `ADN_APP.md`, `CLAUDE.md`, `NEXT_TASK.md` y `bridge/claude_bridge.ps1` completos.
- Confirmado con `git check-ignore` que `.claude/bridge.log` está ignorado por git; `.gitignore` también ignora `bridge_state.json`.
- No se ejecutó el puente, Claude ni ninguna simulación; no se provocó ningún fallo.
- `git diff` antes del commit: cambios únicamente en `CLAUDE_REPORT.md`.
- No se tocaron `lib/`, `test/`, `bridge/`, `MASTER.md`, `ADN_APP.md`, `CLAUDE.md` ni `NEXT_TASK.md`.

## Decisiones pendientes para ChatGPT Director
1. Elegir la alternativa (1, 2, 3 o una combinación) para manejar la salida no cero.
2. Decidir si el árbol sucio tras un fallo debe tratarse en la misma tarea o en otra.
3. Decidir si se verifica la opción `--permission-prompts none` con `claude --help`.
4. Autorizar la modificación del puente (p. ej. parámetro `-ClaudeExePath`) necesaria para la prueba con stub.

Claude Code no decide la Tarea 005 y espera una nueva versión de `NEXT_TASK.md`.

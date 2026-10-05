# NEXT TASK

## Tarea 005 — Implementar señal segura de fallo del puente

### Objetivo
Corregir el defecto confirmado en la Tarea 004: cuando Claude Code termina con salida no cero o el árbol queda en un estado que impide continuar, ChatGPT Director debe poder enterarse por GitHub sin reintentar automáticamente la misma ejecución, sin borrar trabajo local y sin empujar por accidente commits parciales de Claude desde la rama `main`.

### Decisión del Director
Implementar este comportamiento:

1. **No reintentar automáticamente una ejecución de Claude Code que termine con código distinto de `0`.**
2. **Preservar intacto cualquier trabajo parcial** que Claude haya dejado en el árbol principal.
3. Publicar el estado del puente en una rama Git independiente llamada **`bridge-status`**, usando un entorno git aislado del árbol principal para que un commit local parcial de Claude nunca sea arrastrado por el push de estado.
4. El canal de estado debe usar un archivo `BRIDGE_STATUS.md` en `bridge-status`.
5. `BRIDGE_STATUS.md` no debe copiar stdout/stderr completo de Claude, prompts, tokens, credenciales ni contenido potencialmente sensible. Solo metadatos suficientes para que el Director decida.
6. El árbol principal y la rama `main` no deben recibir commits automáticos del puente cuando Claude falla.

### Implementar

#### A. Parámetros y estructura
1. En `bridge/claude_bridge.ps1`, permitir inyectar la ruta del ejecutable de Claude para pruebas mediante un parámetro opcional, manteniendo como valor por defecto la ruta actual `%USERPROFILE%\.local\bin\claude.exe`.
2. Añadir funciones pequeñas y separadas para:
   - guardar estado local;
   - publicar estado remoto en la rama `bridge-status`;
   - construir el contenido de `BRIDGE_STATUS.md`;
   - limpiar únicamente recursos temporales creados por el propio puente.
3. Evitar una refactorización grande que cambie el comportamiento normal exitoso más de lo necesario.

#### B. Estado local
Ante una salida no cero de Claude:
- guardar `last_task_sha = <SHA de NEXT_TASK.md>` para impedir el reintento automático de esa misma versión;
- guardar `status = claude_exit_<N>`;
- guardar también el código de salida y la fecha si resulta útil, manteniendo compatibilidad con el estado anterior;
- no limpiar, resetear, descartar ni hacer stash del árbol local.

Ante árbol sucio antes de lanzar Claude para una tarea nueva:
- no ejecutar Claude;
- no entrar en un bucle ruidoso indefinido para la misma versión de `NEXT_TASK.md`;
- registrar esa versión de la tarea como atendida/bloqueada localmente;
- publicar un estado `blocked_dirty_tree` en `bridge-status`;
- conservar absolutamente todos los cambios locales.

#### C. Canal remoto `bridge-status`
Implementar `Publish-BridgeStatus` o equivalente con estas reglas:

1. **No hacer commit desde el árbol principal.**
2. Crear un directorio temporal propio y trabajar allí con Git de forma aislada.
3. Obtener `origin/bridge-status` si ya existe; si no existe, crear la rama de estado a partir de `origin/main` o de un punto limpio equivalente.
4. Escribir/actualizar únicamente `BRIDGE_STATUS.md`.
5. Hacer commit únicamente del archivo de estado y push únicamente a `bridge-status`.
6. El archivo debe contener como mínimo:
   - `status` (`success`, `claude_exit_N`, `blocked_dirty_tree`, `pull_failed`, `launch_exception` o equivalente claro);
   - SHA de la versión de `NEXT_TASK.md` asociada;
   - fecha/hora ISO;
   - código de salida cuando exista;
   - si el árbol principal estaba limpio o sucio;
   - lista de rutas modificadas si el árbol estaba sucio, **sin incluir contenido de archivos**;
   - mensaje corto y accionable para ChatGPT Director.
7. Si publicar el estado remoto falla, registrar el error en el log local, pero no destruir ni modificar trabajo del árbol principal.
8. El mecanismo no debe usar `git push origin main` para publicar estado.

#### D. Otros fallos relevantes
Sin ampliar innecesariamente el alcance, tratar también estos casos detectados en la Tarea 004:

- `git pull --ff-only` termina distinto de cero: publicar `pull_failed` y evitar reintentos infinitos de la misma versión de tarea.
- invocar el ejecutable de Claude produce una excepción antes de obtener un código normal: publicar `launch_exception` y evitar reintentos infinitos de la misma versión.

No hace falta resolver fallos de red que impidan completamente contactar GitHub; en ese caso basta con el log local y preservar el estado.

### Prueba reproducible obligatoria
Probar el comportamiento **sin provocar un fallo real de Claude en el repositorio de trabajo**.

La prueba debe usar un entorno temporal aislado, por ejemplo:
- clon temporal del repositorio o fixture equivalente;
- remote bare local temporal para que ningún push de prueba llegue al GitHub real;
- stub de Claude fuera del repo que imprima texto inocuo y termine con `exit 7`;
- ruta de Claude inyectada mediante el nuevo parámetro.

Validar al menos:
1. salida `7` produce estado local `claude_exit_7`;
2. la misma versión de `NEXT_TASK.md` no se relanza automáticamente;
3. se crea/actualiza `BRIDGE_STATUS.md` en la rama de estado del remote de prueba;
4. no se modifica ni se hace commit de archivos ajenos;
5. un árbol sucio se conserva intacto y produce `blocked_dirty_tree`;
6. un commit local adicional que exista en `main` antes de publicar el estado **no termina accidentalmente en la rama/remoto de estado**;
7. el repositorio real queda limpio al terminar las pruebas, salvo los cambios intencionales de esta Tarea 005.

### Activación del puente real
El proceso de PowerShell que ya está ejecutando el puente puede tener cargada en memoria la versión anterior del script.

Por eso:
- **no matar, reiniciar ni duplicar automáticamente el puente real en esta tarea**;
- documentar en `CLAUDE_REPORT.md` si la nueva versión requiere reinicio para quedar activa;
- analizar brevemente una estrategia segura para que futuras actualizaciones del puente puedan recargarse sin dejar dos watchers ejecutándose, pero **no implementarla todavía** salvo que sea estrictamente necesaria para las pruebas aisladas.

### Validaciones obligatorias
- Ejecutar las pruebas nuevas del puente.
- `git diff` antes del commit debe contener únicamente archivos necesarios para esta Tarea 005.
- No modificar `lib/` ni `test/` de la app Flutter salvo que exista una razón técnica imprescindible y se documente; en principio esta tarea es solo del puente y sus pruebas/documentación.
- No modificar `NEXT_TASK.md`.
- No borrar ni resetear trabajo local.
- Confirmar explícitamente que ninguna prueba hizo push a `origin/main` real.

### Contenido obligatorio de `CLAUDE_REPORT.md`
- estado `COMPLETADO` o `BLOQUEADO`;
- tarea vigente;
- archivos modificados;
- arquitectura final implementada;
- explicación de cómo se evita empujar commits parciales de Claude;
- resultados de cada prueba obligatoria;
- ejemplo del contenido de `BRIDGE_STATUS.md` sin datos sensibles;
- si hace falta reiniciar el puente real para activar la nueva versión;
- propuesta breve para recarga/actualización futura del puente sin watchers duplicados;
- riesgos que queden pendientes;
- decisiones pendientes para ChatGPT Director.

### Prohibido
- No ejecutar una simulación destructiva sobre el repositorio real.
- No usar `git reset`, `git clean`, `git stash` ni descartar cambios del usuario.
- No hacer push de pruebas a `main` real.
- No lanzar dos puentes reales en paralelo.
- No pedir intervención de Javier.
- No usar checkpoint, botones, selectores ni formularios interactivos.

### Al terminar
Actualizar `CLAUDE_REPORT.md`, hacer commit y `git push` de la implementación a `main`. No decidir la Tarea 006.

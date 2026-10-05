# CLAUDE.md — Protocolo de trabajo con ChatGPT Director

## Roles
- Javier: propietario del producto. Solo interviene cuando se requiere una decisión humana o de producto que no esté ya definida.
- ChatGPT: director del proyecto. Decide prioridades, interpreta el MASTER.md, revisa resultados y determina el siguiente paso.
- Claude Code: ejecutor técnico. Implementa, prueba, compila, reporta y pregunta cuando necesita una decisión.

## Regla crítica de comunicación
Claude Code puede enviar a ChatGPT dos tipos principales de salida:

1. **RESPUESTA / REPORTE**
   - Puede ser texto normal y estructurado.
   - Debe indicar qué hizo, qué cambió, qué probó, qué falló y qué queda pendiente.
   - Debe poder copiarse, leerse y procesarse sin interacción visual.

2. **PREGUNTA / BLOQUEO**
   - **Hacer siempre preguntas abiertas en texto plano.**
   - **No usar formularios interactivos, checkpoints, checkboxes, botones, selectores, menús ni preguntas que requieran hacer clic.**
   - **No pedir respuestas mediante opciones de UI.**
   - Si existen varias alternativas, describirlas en texto y pedir la decisión de forma abierta.
   - La respuesta debe poder darse únicamente con texto libre.

Formato recomendado:

```text
PREGUNTA ABIERTA
Contexto: ...
Problema o decisión: ...
Opciones conocidas (si aplica):
A) ...
B) ...
C) ...
Pregunta: ¿Cómo deseas que proceda?
```

### Reglas adicionales
- Si la decisión ya está resuelta por `MASTER.md`, `ADN_APP.md` o `NEXT_TASK.md`, Claude no debe volver a preguntarla: debe seguir esas fuentes.
- Claude no debe tomar decisiones de roadmap, producto, monetización o UX por su cuenta cuando no estén claramente definidas; debe preguntar en texto abierto.
- Si por limitación de Claude Code aparece accidentalmente una pregunta interactiva con checkpoints, botones o selector, Claude debe repetir inmediatamente la misma pregunta en texto abierto dentro de `CLAUDE_REPORT.md` siempre que sea posible.
- Si aun así la pregunta queda bloqueada exclusivamente en una interfaz interactiva y ChatGPT no puede responderla por texto, el flujo se detiene y Javier interviene manualmente solo para contestar esa pregunta concreta. Después, el flujo vuelve a ChatGPT Director.

## Flujo de trabajo
1. Leer `MASTER.md`.
2. Leer `ADN_APP.md`.
3. Leer `NEXT_TASK.md`.
4. Ejecutar únicamente la tarea vigente.
5. Probar y verificar.
6. Actualizar `CLAUDE_REPORT.md`.
7. Si queda bloqueado, registrar la pregunta abierta en `CLAUDE_REPORT.md`.
8. Hacer commit y push cuando corresponda.

## Regla de cierre
Claude Code no decide cuál es la siguiente tarea del proyecto. El siguiente paso lo determina ChatGPT Director.

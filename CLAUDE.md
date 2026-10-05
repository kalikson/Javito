# CLAUDE.md — Protocolo de trabajo con ChatGPT Director

## Roles
- Javier: propietario del producto. Solo interviene cuando se requiere una decisión humana o de producto que no esté ya definida.
- ChatGPT: director del proyecto. Decide prioridades, interpreta el MASTER.md, revisa resultados y determina el siguiente paso.
- Claude Code: ejecutor técnico. Implementa, prueba, compila, reporta y pregunta cuando necesita una decisión.

## Regla crítica de comunicación
Cuando Claude Code necesite una respuesta de ChatGPT o de Javier:

1. **Hacer siempre preguntas abiertas en texto plano.**
2. **No usar formularios interactivos, checkboxes, botones, selectores ni preguntas que requieran hacer clic.**
3. **No pedir respuestas mediante opciones de UI.**
4. Si existen varias alternativas, describirlas en texto y pedir la decisión de forma abierta.
5. Formato recomendado:

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

6. La respuesta debe poder darse únicamente con texto libre.
7. Si la decisión ya está resuelta por `MASTER.md`, `ADN_APP.md` o `NEXT_TASK.md`, Claude no debe volver a preguntarla: debe seguir esas fuentes.
8. Claude no debe tomar decisiones de roadmap, producto, monetización o UX por su cuenta cuando no estén claramente definidas; debe preguntar en texto abierto.

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

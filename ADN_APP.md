# ADN DE LA APP — Requisitos obligatorios para futuros proyectos

Este documento define los puntos que deben revisarse e incorporarse en todos los proyectos de apps, salvo que exista una razón explícita para no aplicarlos. Debe copiarse o referenciarse desde el `MASTER.md` de cada proyecto.

## A. Reglas base de producto definidas por Javier

1. **Paletas de color obligatorias desde el MD**
   - Mínimo 3 paletas base:
     - Oscura.
     - Clara/blanca con variantes de color.
     - Rosa/femenina.
   - Pueden existir más, pero estas tres deben contemplarse por defecto.

2. **Mapa de pantallas antes de entrar de lleno a programación**
   - Cuando ya estén claras la estructura, dolores del usuario, operación, información disponible y funciones, definir cuántas pantallas habrá y qué función cumple cada una.

3. **Principio “La información es poder”**
   - Priorizar datos útiles que Android o la propia app ya tengan.
   - Traducir información técnica a decisiones entendibles.
   - Ofrecer vistas y consultas que ayuden al usuario a entender qué pasa y qué hacer.

4. **Flujo de producto**
   - Detectar → explicar → proponer solución → permitir actuar.
   - Si Android no permite actuar directamente, guiar al ajuste o camino exacto.

5. **Gratis y Pro deben definirse desde el MD**
   - La versión Gratis debe ser útil y funcional.
   - Pro amplía límites, profundidad, contenido, funciones o capacidad.
   - No dejar esta decisión para el final del proyecto.

6. **Botón permanente y discreto “Mejorar plan”**
   - Visible durante el uso normal para usuarios Gratis.
   - Siempre accesible, sin estorbar ni interrumpir navegación.
   - Debe adaptarse a la paleta y destacar lo suficiente.
   - La filosofía es facilitar la compra, no presionar al usuario.

7. **Usuario Pro: “Administrar suscripción”**
   - Una vez suscrito, el acceso de compra cambia a “Administrar suscripción” o equivalente.
   - Debe existir también dentro de Configuración.

8. **Comprar fácil y cancelar fácil**
   - La app debe facilitar el acceso a Google Play para contratar, administrar o cancelar la suscripción.
   - No ocultar la cancelación.
   - Debe quedar claro que puede cancelar cuando quiera y volver a suscribirse después.
   - La facturación real y la cancelación las gestiona Google Play; la app ofrece accesos claros y correctos.

9. **Monetización visible pero no molesta**
   - Nada de pop-ups insistentes, tácticas engañosas o interrupciones repetitivas.
   - La venta debe estar siempre disponible, no siempre estorbando.

10. **Diseño visual con punto de aprobación de Javier**
   - ChatGPT propone y dirige el diseño.
   - Antes de cerrar las pantallas visuales principales, Javier revisa y aprueba el enfoque.
   - Después de esa aprobación, el proyecto puede continuar normalmente.

11. **Interfaz de monetización preparada antes de publicación**
   - Pantalla o modal de Pro.
   - Beneficios claros.
   - Mejorar plan.
   - Administrar suscripción.
   - Restaurar compras.
   - Estados Gratis/Pro.
   - Manejo de compra cancelada o fallida.
   - Reconocimiento correcto de derechos adquiridos.

12. **Auditoría de monetización antes de publicar**
   - Verificar límites Gratis.
   - Verificar desbloqueos Pro.
   - Verificar accesos a compra y administración.
   - Verificar restauración de compras.
   - Verificar que no queden funciones Pro abiertas accidentalmente.

12A. **Simulador DEV Gratis / Pro obligatorio durante desarrollo**
   - Durante desarrollo debe existir una forma rápida de simular el estado `Gratis` y `Pro` para probar toda la experiencia sin realizar compras reales.
   - Puede presentarse como switch, selector o control interno dentro de un menú de desarrollo, pero **el switch es solamente la interfaz del simulador, nunca la seguridad real de Pro**.
   - La arquitectura debe separar claramente dos fuentes de derechos:
     - `DevEntitlementProvider` o equivalente: solo para debug/flavor interno.
     - `PlayEntitlementProvider` o equivalente: única fuente válida en producción.
   - La lógica de negocio no debe depender de un booleano local tipo `isPro = true`, una preferencia editable, SharedPreferences, un archivo local o un valor fácilmente parcheable.
   - El código que permite forzar Gratis/Pro debe compilarse únicamente en builds de desarrollo o flavor interno. Idealmente, las clases, rutas, controles y dependencias del simulador DEV **no deben formar parte del AAB release**, no solo quedar ocultas visualmente.
   - En release, el estado Pro debe derivarse de los derechos reales obtenidos por Google Play Billing y de la validación que corresponda al proyecto.
   - Si el valor comercial o el riesgo lo justifican, considerar validación adicional del lado servidor para dificultar alteraciones locales; nunca asumir que una app instalada en el dispositivo es imposible de modificar.
   - El desbloqueo de funciones Pro debe pasar por una capa central de `Entitlements/AccessControl`, de modo que ninguna pantalla pueda desbloquearse cambiando una sola variable aislada.
   - El simulador DEV debe afectar esa misma capa de permisos para probar exactamente los mismos caminos de UI, límites y funciones que usará producción.
   - Antes del AAB final debe hacerse una auditoría específica que confirme:
     - no existe menú DEV accesible;
     - no existe ruta oculta para forzar Pro;
     - no existe preferencia local capaz de activar Pro;
     - el provider DEV no forma parte del release cuando la arquitectura lo permita;
     - los derechos Pro reales provienen de Google Play/validación autorizada;
     - modificar un único valor local no basta para convertir Gratis en Pro.
   - Objetivo: disfrutar durante desarrollo de un cambio Gratis/Pro instantáneo sin dejar una puerta trasera trivial en producción.

## B. Reglas adicionales internas de calidad y funcionamiento

13. **Estados completos de cada pantalla**
   - Normal.
   - Cargando.
   - Sin datos.
   - Error.
   - Sin conexión cuando aplique.

14. **Persistencia de estado**
   - Revisar qué debe recordar la app al cerrarse y volver a abrirse: preferencias, filtros, colores, última pantalla, configuración, etc.

15. **Permisos con explicación previa**
   - Pedir cámara, micrófono, ubicación, contactos, notificaciones, accesibilidad u otros permisos solo cuando se necesiten.
   - Explicar antes para qué sirven y qué gana el usuario.

16. **Privacidad por diseño**
   - Preguntar siempre qué datos se recogen, para qué, dónde se guardan y si salen del dispositivo.
   - Regla: si un dato no es necesario, no pedirlo.

17. **Seguridad proporcional al proyecto**
   - No incluir secretos, tokens o claves sensibles directamente en el código.
   - Usar almacenamiento seguro y cifrado cuando corresponda.
   - Revisar dependencias y superficies de riesgo.

18. **Accesibilidad mínima obligatoria**
   - Texto legible.
   - Contraste suficiente.
   - Controles con tamaño razonable.
   - No depender solo del color para comunicar estados.
   - Soportar escalado de texto razonablemente.

19. **Acciones peligrosas: confirmar o permitir deshacer**
   - Confirmar borrados, reseteos o acciones irreversibles.
   - Preferir “Deshacer” cuando sea más cómodo y seguro.

20. **Errores entendibles**
   - No mostrar errores técnicos crudos al usuario.
   - Explicar qué ocurrió, qué significa y qué puede hacer ahora.

21. **Ayuda contextual**
   - Incluir ayuda breve donde una función pueda generar dudas.
   - Puede ser icono `?`, tooltip, ayuda contextual o explicación corta.

22. **Tutorial inicial y tutorial dinámico**
   - Cuando la app lo justifique, incluir onboarding inicial breve.
   - Añadir tutorial dinámico/contextual que explique botones o zonas clave al usarlas por primera vez.
   - Evitar tutoriales eternos o invasivos.

23. **Documento de ayuda dentro de la app**
   - Debe existir un acceso mediante `?` o sección Ayuda.
   - Explicar de forma rápida para qué sirve cada pantalla, botón o función importante.
   - Mantenerlo simple, útil y actualizado.

24. **Acerca de / Soporte / Versión**
   - Incluir versión de la app, información básica, privacidad y vía de soporte/contacto cuando aplique.
   - Si hay suscripción, incluir Plan y suscripción.

25. **Prueba de primera instalación**
   - Probar como usuario nuevo: instalación limpia, primer arranque, permisos, datos iniciales, navegación y Gratis/Pro.

26. **Prueba de actualización**
   - Probar actualización desde una versión anterior conservando datos y preferencias.

27. **Prueba sin Internet**
   - Verificar comportamiento cuando se pierde conexión.
   - Las funciones offline deben seguir funcionando realmente offline.

28. **Prueba de ciclo de vida Android**
   - Atrás, minimizar, regresar, cambiar de app, bloquear teléfono, reanudar y cerrar.
   - No perder trabajo innecesariamente ni entrar en estados incoherentes.

29. **Rendimiento, batería y almacenamiento**
   - Revisar inicio, fluidez, tamaño APK/AAB, segundo plano, sensores, ubicación, consumo de batería y almacenamiento.

30. **Dependencias y compatibilidad Android**
   - Primero capacidades nativas Android.
   - Después librerías Flutter maduras, mantenidas y seguras.
   - Solo después código propio.
   - Auditar APIs, SDK objetivo, compatibilidad y políticas de Google Play.

31. **Identidad visual completa**
   - Icono.
   - Icono adaptativo.
   - Nombre mostrado.
   - Splash cuando corresponda.
   - Tipografía.
   - Paletas.
   - Consistencia visual.

32. **Preparación Google Play**
   - Icono.
   - Screenshots.
   - Feature graphic.
   - Descripción corta y larga.
   - Categoría.
   - Política de privacidad.
   - Data Safety.
   - Clasificación de contenido.
   - Testing requerido.
   - AAB de producción.

33. **Restaurar compras y reconocer Pro**
   - Si reinstala, cambia de teléfono o vuelve tiempo después, la app debe recuperar correctamente sus derechos mediante Google Play.

34. **Widgets — evaluar siempre si aportan valor**
   - No toda app necesita widget, pero debe evaluarse explícitamente en el MD.
   - Si un widget permite consultar o actuar sin abrir la app y mejora claramente el producto, debe considerarse parte importante de la experiencia.
   - No agregar widgets solo por tenerlos; deben resolver algo útil.

35. **Auditoría final ADN**
   - Antes de declarar el proyecto terminado revisar todo este documento.
   - Si un punto obligatorio no está implementado, probado o descartado con una razón explícita, el proyecto todavía no se considera terminado.

## C. Regla de definición de terminado

> Una función no se considera terminada porque ya funciona. Se considera terminada cuando funciona, se entiende, falla correctamente, conserva su estado cuando corresponde y está probada.

## D. Uso en futuros proyectos

- Cada `MASTER.md` debe incluir una sección `ADN DE LA APP` o enlazar/copiar este checklist.
- ChatGPT es responsable de recordar estos puntos aunque Javier no los mencione durante el proyecto.
- Claude Code implementa lo que ChatGPT indique; no decide eliminar, cambiar o ignorar estos requisitos por iniciativa propia.
- Si un requisito no aplica a una app concreta, debe marcarse explícitamente como `NO APLICA` junto con la razón.

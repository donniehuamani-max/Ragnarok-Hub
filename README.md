# Ragnarok Hub v2.0

Ragnarok Hub v2.0 es un runtime Luau de interfaz compacta para control, configuración y diagnóstico local. La implementación está concentrada en `main.lua` y mantiene un diseño oscuro, modular y orientado a estado.

## Alcance

La versión 2.0 incorpora un shell redimensionado, navegación por páginas, búsqueda de controles, notificaciones con cola, configuración normalizada, persistencia versionada, restauración de valores base, ciclo de vida de personaje, cierre seguro, métricas de runtime, control de cámara, control visual de hitbox, movimiento aéreo, salto direccional, rotación automática, anti AFK, parámetros experimentales, atajos configurables y API pública de sesión.

## Instalación

Cargar `main.lua` en un entorno Luau compatible con Roblox. La interfaz se inicia minimizada en el icono flotante cuando la opción correspondiente está activa. El atajo inicial para abrir o cerrar el panel es `RightShift`.

## Persistencia

El archivo se guarda en `RagnarokHub/v2/config.json` cuando el entorno expone las funciones de archivo necesarias. La configuración se normaliza contra el esquema de v2 y se ignoran valores inválidos. La posición de la ventana, los atajos y los parámetros de cada sección se mantienen entre sesiones.

## Arquitectura

El runtime se divide en configuración, persistencia, tema visual, fábrica de componentes, registro de controles, páginas, controladores funcionales, ciclo de personaje, métricas, búsqueda, atajos, diagnóstico y apagado. Todas las conexiones se registran para poder liberar recursos durante el cierre.

## Controladores

Los controladores de `hitbox`, `movement`, `stats`, `visuals` y `utilities` se activan por estado. Cada controlador expone inicio, detención y refresco. La actualización visual usa cadencia limitada y evita enumeraciones de remotos o llamadas arbitrarias a servicios del juego.

## Compatibilidad

Requiere `UserInputService`, `Players`, `RunService`, `TweenService`, `GuiService`, `Stats`, `CoreGui` y una cámara activa. Las funciones de persistencia y protección de interfaz son opcionales; si no están disponibles, el runtime continúa con configuración en memoria.

## Versión

| Campo | Valor |
|---|---|
| Versión | 2.0.0 |
| Build | 2026.08 |
| Archivo principal | `main.lua` |
| Líneas de código | Más de 2600 |
| Comentarios de código | 0 |
| Persistencia | `RagnarokHub/v2/config.json` |

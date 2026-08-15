# Ragnarok Hub Executor 3.1

Ragnarok Hub Executor es un script Luau para ejecutores externos de Roblox. No es un plugin, no es un proyecto de Roblox Studio y no requiere publicación dentro de Studio.

## Ejecución

Ejecutar `loader.lua` desde el executor. El loader valida `loadstring` o `load`, descarga `main.lua` desde la rama principal, comprueba la compilación y encapsula la ejecución.

También se puede ejecutar `main.lua` directamente desde el executor. La interfaz se monta en `gethui()` cuando existe, usa `syn.protect_gui` cuando está disponible y utiliza `CoreGui` como fallback.

## Interfaz

La UI conserva la composición compacta de la base v1.0: ventana oscura, cabecera corta, icono flotante, pestañas horizontales, controles densos, sliders y menú de terminación. Las pestañas disponibles son `MAIN`, `MISC`, `ADVANCED` y `CONFIG`. Cada pestaña utiliza un viewport `ScrollingFrame` con canvas automático, scrollbar visible y altura responsive según la resolución de GUI, sin depender del CFrame de la cámara. Los botones usan `Activated` y la ventana, el icono y los sliders aceptan touch.

La rueda del mouse desplaza la pestaña activa. `PageDown`, `ArrowDown`, `PageUp`, `ArrowUp`, `Home` y `End` permiten navegar sin depender del scrollbar. La ventana mantiene una altura limitada y ajusta su tamaño a resoluciones pequeñas.

## Opciones funcionales

El runtime conecta hitbox visual local, escala, color, transparencia, actualización limitada, salto direccional, movimiento aéreo, velocidad aérea, rotación automática, anti AFK, FOV normal, FOV stretched, notificaciones, binds, persistencia, perfiles locales, exportación, importación, diagnóstico, apagado seguro y los multiplicadores de estadísticas de la base v1.0: Dive Speed, Spike Power, Tilt Power, Speed, Set Power, Serve Power, Jump Power, Bump Power y Block Power.

Las funciones que dependan de autoridad del servidor no se fuerzan mediante enumeración arbitraria de remotos. El script controla únicamente lo que el cliente y el executor pueden aplicar de forma local y estable.

## APIs executor detectadas

| API | Uso |
|---|---|
| `getgenv` | Estado global y API de sesión |
| `gethui` | Protección de GUI |
| `syn.protect_gui` | Protección alternativa de GUI |
| `writefile` | Guardado de configuración y snapshot |
| `readfile` | Carga de configuración y snapshot |
| `isfile` | Verificación de archivos |
| `loadstring` o `load` | Compilación del loader |

## Correcciones de 3.2

La UI dejó de crecer indefinidamente porque las páginas ahora son viewports desplazables. El layout usa la resolución de GUI para dimensionar la ventana y no actualiza la posición por cambios de cámara. El stats changer volvió a escribir los atributos históricos de jugador, personaje y humanoid, reaplicar valores tras respawn y restaurar los valores base al desactivarse o apagarse.

## Informe técnico

La regresión principal fue convertir una interfaz compacta en una jerarquía larga sin viewport. El segundo fallo fue utilizar la cámara como fuente del layout en vez de separar resolución de pantalla y estado de cámara. El tercer fallo fue eliminar el bloque histórico de stats durante la reestructuración v3. El cuarto fallo fue dejar eventos de mouse en controles que también debían aceptar touch. El quinto fallo fue validar sintaxis sin probar el comportamiento visual dentro de Roblox; la validación estática no sustituye una prueba en un executor real.

La referencia oficial de Luau sirvió para confirmar que Luau prioriza compatibilidad con Lua 5.1 cuando es posible, seguridad, rendimiento y embebibilidad. No define APIs de executor ni garantiza la existencia de `getgenv`, `gethui`, `writefile` o `loadstring`; esas capacidades pertenecen al entorno que ejecuta el script.

## API pública

La sesión expone `getgenv().RagnarokAPI` con `Toggle`, `Show`, `Hide`, `SetPage`, `SetValue`, `GetConfig`, `GetState`, `GetStats`, `SetStatsEnabled`, `ApplyAllStats`, `ResetStats`, `GetRuntime`, `GetEnvironment`, `GetLogs`, `ClearLogs`, `SelfTest`, `Save`, `Load`, `Reset`, `Export`, `Import`, `SaveProfile`, `LoadProfile`, `CaptureProfile`, `ListProfiles`, `Notify`, `Shutdown` y `Ready`.

## Compatibilidad

| Campo | Valor |
|---|---|
| Versión | 3.2.0-EXECUTOR |
| Archivo principal | `main.lua` |
| Loader | `loader.lua` |
| Líneas | Más de 2000 |
| Locals raíz | 0 |
| Comentarios en código | 0 |
| Roblox Studio | No requerido |
| GitHub | Publicación executor externa |

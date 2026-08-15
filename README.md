# Ragnarok Hub Executor 3.1

Ragnarok Hub Executor es un script Luau para ejecutores externos de Roblox. No es un plugin, no es un proyecto de Roblox Studio y no requiere publicación dentro de Studio.

## Ejecución

Ejecutar `loader.lua` desde el executor. El loader valida `loadstring` o `load`, descarga `main.lua` desde la rama principal, comprueba la compilación y encapsula la ejecución.

También se puede ejecutar `main.lua` directamente desde el executor. La interfaz se monta en `gethui()` cuando existe, usa `syn.protect_gui` cuando está disponible y utiliza `CoreGui` como fallback.

## Interfaz

La UI conserva la composición compacta de la base v1.0: ventana oscura de 400 píxeles, cabecera corta, icono flotante, pestañas horizontales, controles densos, sliders y menú de terminación. Las pestañas disponibles son `MAIN`, `MISC`, `ADVANCED` y `CONFIG`.

## Opciones funcionales

El runtime conecta hitbox visual local, escala, color, transparencia, actualización limitada, salto direccional, movimiento aéreo, velocidad aérea, rotación automática, anti AFK, FOV normal, FOV stretched, notificaciones, binds, persistencia, perfiles locales, exportación, importación, diagnóstico y apagado seguro.

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

## API pública

La sesión expone `getgenv().RagnarokAPI` con `Toggle`, `Show`, `Hide`, `SetPage`, `SetValue`, `GetConfig`, `GetState`, `GetRuntime`, `GetEnvironment`, `GetLogs`, `ClearLogs`, `SelfTest`, `Save`, `Load`, `Reset`, `Export`, `Import`, `SaveProfile`, `LoadProfile`, `CaptureProfile`, `ListProfiles`, `Notify`, `Shutdown` y `Ready`.

## Compatibilidad

| Campo | Valor |
|---|---|
| Versión | 3.1.0-EXECUTOR |
| Archivo principal | `main.lua` |
| Loader | `loader.lua` |
| Líneas | Más de 2000 |
| Locals raíz | 0 |
| Comentarios en código | 0 |
| Roblox Studio | No requerido |
| GitHub | Publicación executor externa |

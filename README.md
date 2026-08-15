# Ragnarok Hub v3.0

Ragnarok Hub v3.0 es un runtime Luau modular con configuración versionada, perfiles aislados, estado observable y herramientas de diagnóstico integradas.

## Entrega

El paquete contiene `main.lua` y este documento. La copia fue preparada fuera del repositorio de GitHub. No se creó commit y no se ejecutó push.

## Cambios de v3.0

La versión añade una matriz de tres perfiles independientes, migración desde la ruta v2, guardado automático configurable, estado con revisiones, listeners de cambios, ledger de sesión limitado, scheduler de tareas, inspector de runtime, paleta de comandos, layout compacto, estándar y ancho, API pública ampliada y cierre seguro. El parche correctivo elimina locals de nivel superior para evitar el límite de registros del compilador y estabiliza las referencias adelantadas.

## Funciones principales

El runtime conserva las páginas Dashboard, Gameplay, Movement, Visuals, Experimental, Utilities y Settings. Se mantienen el control visual de hitbox, salto direccional, movimiento aéreo, rotación, cámara, anti AFK, sincronización de atributos, persistencia, notificaciones, búsqueda y atajos.

La paleta de comandos se abre con `F2` por defecto. Permite navegar entre páginas, guardar o recargar el perfil, refrescar el runtime, restaurar valores, cambiar layout, cambiar de perfil y detener la sesión.

## Perfiles

Los perfiles disponibles son `alpha`, `beta` y `gamma`. Cada perfil se guarda en una ruta separada dentro de `RagnarokHub/v3/`. El perfil `alpha` puede migrar automáticamente el archivo legado de `RagnarokHub/v2/config.json`.

## Loader

Ejecutar `loader.lua` para descargar y ejecutar la versión publicada de `main.lua`. El loader comprueba `loadstring` o `load`, valida que la fuente no esté vacía, verifica la compilación y encapsula la ejecución con `pcall`.

## API pública

La sesión expone `getgenv().RagnarokAPI` con métodos para obtener estado, cambiar valores, suscribirse a cambios, cambiar perfiles, ejecutar comandos, inspeccionar el runtime, leer el historial, guardar, recargar, reconciliar y cerrar la sesión.

## Validación

| Campo | Valor |
|---|---|
| Versión | 3.0.0 |
| Build | 2026.08-R3 |
| Archivo principal | `main.lua` |
| Líneas de código | Más de 3300 |
| Comentarios en código | 0 |
| Registro local superior | 0 |
| Estado del parche | Compilador estable |
| Commit GitHub | Ninguno |
| Push GitHub | Ninguno |
| Persistencia v3 | `RagnarokHub/v3/{profile}.json` |
| Loader | `loader.lua` |

# Solución de Problemas - Sistema de Parking con Vehículos de Facción

## Problema: Los vehículos de facción no aparecen

### Pasos para verificar:

1. **Verificar la base de datos**
   - Asegúrate de haber ejecutado el SQL para crear la tabla `r1mus_faction_vehicles`
   - Verifica que la tabla existe en tu base de datos

2. **Verificar la configuración**
   - En `config.lua`, asegúrate de que `Config.FactionVehicles.enabled = true`
   - Verifica que las coordenadas de los vehículos sean correctas para tu mapa

3. **Comandos de depuración (como admin)**
   ```
   /debugfaction - Ver información de depuración en la consola del servidor
   /spawnfactionvehicles - Forzar el spawn de todos los vehículos de facción
   ```

4. **Verificar logs del servidor**
   - Al iniciar el recurso deberías ver:
     ```
     Inicializando vehículos de facción...
     Vehículo de facción registrado: POL00001 - police - Patrulla #1
     ...
     Total de vehículos de facción registrados: 15
     ```
   - Después de 10 segundos:
     ```
     === INICIANDO SPAWN AUTOMÁTICO DE VEHÍCULOS DE FACCIÓN ===
     Vehículos de facción encontrados: 15
     Spawneando vehículo 1/15: POL00001 - Patrulla #1
     ...
     ```

## Problema: Los vehículos personales no aparecen

### Verificar:

1. **Sintaxis del código**
   - Los errores de sintaxis han sido corregidos en `client/main.lua`
   - Reinicia el recurso después de las correcciones

2. **Base de datos**
   - Verifica que la tabla `r1mus_parked_vehicles` existe
   - Verifica que la tabla `player_vehicles` tiene vehículos

3. **Logs del cliente**
   - Presiona F8 para ver la consola
   - Deberías ver mensajes como:
     ```
     OnPlayerLoaded triggered
     Solicitando vehículos después de 3 segundos
     Intentando restaurar vehículo: ABC123
     ```

## Solución Rápida

1. **Reiniciar el recurso completamente**
   ```
   stop r1mus_parking
   start r1mus_parking
   ```

2. **Si los vehículos de facción no aparecen automáticamente**
   - Espera 10 segundos después del reinicio
   - Si no aparecen, usa: `/spawnfactionvehicles` (como admin)

3. **Para verificar el estado del sistema**
   - Usa: `/debugfaction` (como admin)
   - Revisa la consola del servidor

## Orden de Inicio Recomendado

1. Asegúrate de que estos recursos estén iniciados primero:
   - `oxmysql`
   - `qb-core`
   - `PolyZone`
   - `LegacyFuel`

2. Luego inicia:
   - `r1mus_parking`

## Verificación Final

Para verificar que todo funciona:

1. **Vehículos Personales**
   - Saca un vehículo personal
   - Muévete con él
   - Desconéctate y reconéctate
   - El vehículo debería aparecer donde lo dejaste

2. **Vehículos de Facción**
   - Cambia tu trabajo a `police`, `ambulance` o `mechanic`
   - Usa `/factionvehicles` para ver la lista
   - Los vehículos deberían estar en sus ubicaciones configuradas
   - Solo podrás usar los de tu facción actual

## Notas Importantes

- Los vehículos de facción se reinician a sus posiciones originales al reiniciar el servidor
- Los vehículos personales mantienen su última posición
- Ambos sistemas funcionan independientemente
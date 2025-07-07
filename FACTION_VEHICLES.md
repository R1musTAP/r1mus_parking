# Sistema de Vehículos de Facción

Esta es una extensión del sistema r1mus_parking que añade soporte para vehículos de facción (policía, EMS, etc.).

## Características

- **Vehículos Predefinidos por Trabajo**: Cada facción tiene sus propios vehículos configurados
- **Spawn Automático**: Los vehículos aparecen automáticamente en ubicaciones específicas
- **Persistencia**: Los vehículos mantienen su posición y estado entre reinicios
- **Sistema de Permisos**: Solo miembros de la facción pueden usar los vehículos
- **Restauración Automática**: Opción para devolver vehículos a posiciones originales al reiniciar

## Configuración

### 1. Ejecutar el SQL adicional

```sql
-- Tabla para vehículos de facción
CREATE TABLE IF NOT EXISTS `r1mus_faction_vehicles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `plate` VARCHAR(8) NOT NULL,
    `job` VARCHAR(50) NOT NULL,
    `model` VARCHAR(50) NOT NULL,
    `coords` TEXT NOT NULL,
    `heading` FLOAT NOT NULL,
    `original_coords` TEXT NOT NULL,
    `original_heading` FLOAT NOT NULL,
    `label` VARCHAR(100),
    `livery` INT DEFAULT 0,
    `extras` TEXT,
    `body_health` FLOAT DEFAULT 1000.0,
    `engine_health` FLOAT DEFAULT 1000.0,
    `fuel_level` FLOAT DEFAULT 100.0,
    `dirt_level` FLOAT DEFAULT 0.0,
    `mods` TEXT,
    `in_use` BOOLEAN DEFAULT false,
    `last_used` BIGINT,
    UNIQUE KEY `unique_faction_plate` (`plate`),
    INDEX `idx_job` (`job`),
    INDEX `idx_in_use` (`in_use`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 2. Configurar vehículos en config.lua

```lua
Config.FactionVehicles = {
    enabled = true,
    respawnOnRestart = true, -- Devolver a posición original al reiniciar
    lockToFaction = true, -- Solo miembros pueden usar
    
    factions = {
        ['police'] = {
            vehicles = {
                {
                    model = 'police',
                    coords = vector3(442.73, -1019.77, 28.55),
                    heading = 90.0,
                    livery = 0,
                    extras = {1, 2},
                    label = "Patrulla #1"
                },
                -- Más vehículos...
            }
        },
        ['ambulance'] = {
            vehicles = {
                {
                    model = 'ambulance',
                    coords = vector3(295.58, -1446.66, 29.97),
                    heading = 320.0,
                    livery = 0,
                    label = "Ambulancia #1"
                },
                -- Más vehículos...
            }
        }
    }
}
```

## Uso

### Para Jugadores

1. **Spawn Automático**: Los vehículos de tu facción aparecen automáticamente al conectarte
2. **Bloqueo/Desbloqueo**: Usa la tecla X cerca del vehículo (igual que vehículos personales)
3. **Comando**: `/factionvehicles` - Ver lista de vehículos de facción disponibles

### Para Administradores

Los comandos de administrador funcionan también con vehículos de facción:
- `/locatevehicle [matrícula]` - Localizar vehículo de facción
- `/getvehicle [matrícula]` - Traer vehículo a tu ubicación
- `/gotovehicle [matrícula]` - Ir a la ubicación del vehículo

## Cómo Funciona

1. **Al iniciar el servidor**:
   - Se crean registros en la base de datos para cada vehículo configurado
   - Si `respawnOnRestart` está activo, los vehículos vuelven a sus posiciones originales
   - **NUEVO**: Los vehículos de facción se spawnan automáticamente sin necesidad de jugadores conectados

2. **Al conectarse un jugador**:
   - Si tiene un trabajo con vehículos configurados, puede verlos y usarlos
   - Los vehículos mantienen su último estado (daños, combustible, etc.)
   - Solo puede usar vehículos de su facción actual

3. **Al cambiar de trabajo**:
   - Los vehículos del trabajo anterior ya no pueden ser usados
   - Obtiene acceso a los vehículos del nuevo trabajo (si los tiene)

4. **Guardado automático**:
   - La posición y estado se guardan cada 30 segundos
   - También se guarda cuando el vehículo se detiene

## Personalización

### Añadir más trabajos

El sistema ya incluye vehículos para:
- **police**: 5 vehículos (patrullas, moto, unidad FBI)
- **ambulance**: 5 vehículos (ambulancias, camión de bomberos, rescate)
- **mechanic**: 5 vehículos (grúas, vans de trabajo)

Para añadir más trabajos, simplemente añade una nueva entrada en `Config.FactionVehicles.factions`:

```lua
['taxi'] = {
    vehicles = {
        {
            model = 'taxi',
            coords = vector3(100.0, 200.0, 30.0),
            heading = 180.0,
            label = "Taxi #1"
        }
    }
}
```

### Modificar comportamiento

- `enabled`: Activa/desactiva el sistema completo
- `respawnOnRestart`: Define si los vehículos vuelven a su posición original
- `lockToFaction`: Controla si solo miembros pueden usar los vehículos

## Notas Importantes

- Las matrículas se generan automáticamente: `[JOB][00001]` (ej: POL00001, AMB00001, MEC00001)
- Los vehículos de facción no cuentan como vehículos personales
- El sistema es compatible con el sistema original de parking personal
- Los vehículos aparecen automáticamente al iniciar el servidor
- Los vehículos persisten entre reinicios del servidor
- Solo miembros de la facción pueden usar sus vehículos específicos

## Solución de Problemas

**Vehículos no aparecen**:
- Verifica que el trabajo del jugador coincida con los configurados
- Revisa que la tabla SQL se haya creado correctamente
- Comprueba los logs del servidor para errores

**Vehículos duplicados**:
- Reinicia el recurso para limpiar la base de datos
- Verifica que no haya otros recursos spawneando los mismos modelos

**No puedo usar el vehículo**:
- Asegúrate de que `lockToFaction` esté configurado correctamente
- Verifica que tu trabajo coincida con el del vehículo
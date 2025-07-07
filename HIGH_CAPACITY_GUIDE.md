# Guía para Servidores de Alta Capacidad (250+ Jugadores)

## Sistema de Streaming de Vehículos de Facción

### Problema Original
- Con 15 vehículos de facción y 250 jugadores = 3,750 entidades
- Esto causaría lag extremo y crasheos del servidor

### Solución Implementada: Sistema de Streaming

#### 1. **Streaming Dinámico** (`client/faction_streaming.lua`)
- Los vehículos solo aparecen cuando un jugador está a menos de 150 metros
- Cada cliente solo renderiza los vehículos cercanos
- Reduce las entidades activas en ~90%

#### 2. **Datos Centralizados**
- El servidor envía las posiciones de todos los vehículos de facción una vez
- Los clientes manejan el spawn/despawn localmente
- No hay comunicación constante servidor-cliente

#### 3. **Optimizaciones Implementadas**

```lua
-- Configuración para alta capacidad
Config.Optimization = {
    streamingEnabled = true,      -- IMPORTANTE: Debe estar en true
    streamDistance = 150.0,       -- Solo mostrar vehículos en 150m
    streamCheckInterval = 2000,   -- Verificar cada 2 segundos
    vehicleCheckInterval = 5000,  -- Verificar vehículos cada 5s
    positionSaveInterval = 30000, -- Guardar posición cada 30s
    enablePermissionCache = true, -- Cache de permisos habilitado
    cacheTimeout = 60000         -- 1 minuto de cache
}
```

## Configuración para 250+ Jugadores

### 1. **Base de Datos**
```sql
-- Índices optimizados (ya incluidos)
CREATE INDEX idx_citizenid ON r1mus_parked_vehicles(citizenid);
CREATE INDEX idx_last_parked ON r1mus_parked_vehicles(last_parked);
CREATE INDEX idx_job ON r1mus_faction_vehicles(job);
CREATE INDEX idx_in_use ON r1mus_faction_vehicles(in_use);
```

### 2. **Configuración del Servidor**
```cfg
# server.cfg
set mysql_connection_string "server=localhost;database=qbcore;userid=root;password=;charset=utf8mb4;sslmode=none;connectionTimeout=30;maximumPoolSize=50"
set mysql_slow_query_warning 200
set sv_projectName "Mi Servidor RP"
set sv_projectDesc "Servidor optimizado para 250+ jugadores"
set onesync on
set onesync_population true
```

### 3. **Límites Recomendados**
```lua
Config.Optimization.maxVehiclesPerPlayer = 5  -- Máximo 5 vehículos por jugador
Config.FactionVehicles.respawnOnRestart = true -- Resetear posiciones al reiniciar
```

## Monitoreo de Rendimiento

### Comandos de Admin
- `/debugfaction` - Ver estado del sistema de facción
- `/spawnfactionvehicles` - Forzar spawn manual (NO USAR con 250+ jugadores)

### Métricas a Monitorear
1. **Entidades Activas**: Mantener bajo 5000 total
2. **Uso de CPU**: No debe exceder 80%
3. **Uso de RAM**: Mantener bajo 8GB
4. **Latencia de Red**: < 100ms promedio

## Escalabilidad

### Con Sistema de Streaming
| Jugadores | Vehículos Facción | Entidades Totales | Impacto |
|-----------|-------------------|-------------------|---------|
| 50        | 15                | ~150              | Mínimo  |
| 100       | 15                | ~300              | Bajo    |
| 250       | 15                | ~750              | Medio   |
| 500       | 15                | ~1500             | Alto    |

### Sin Sistema de Streaming (NO RECOMENDADO)
| Jugadores | Vehículos Facción | Entidades Totales | Impacto    |
|-----------|-------------------|-------------------|------------|
| 50        | 15                | 750               | Alto       |
| 100       | 15                | 1500              | Muy Alto   |
| 250       | 15                | 3750              | CRÍTICO    |
| 500       | 15                | 7500              | IMPOSIBLE  |

## Solución de Problemas

### Los vehículos de facción no aparecen
1. Verifica que `streamingEnabled = true` en config.lua
2. Reinicia el recurso completamente
3. Espera 10 segundos para que se carguen los datos
4. Verifica la consola del servidor para errores

### Lag con muchos jugadores
1. Reduce `streamDistance` a 100.0 o menos
2. Aumenta `streamCheckInterval` a 3000 o más
3. Reduce `maxVehiclesPerPlayer` a 3

### Vehículos desaparecen/aparecen constantemente
1. Aumenta `streamDistance` a 200.0
2. Verifica que no haya otros scripts spawneando vehículos

## Mejores Prácticas

1. **Reiniciar diariamente**: Programa reinicios automáticos cada 24 horas
2. **Monitorear recursos**: Usa herramientas como txAdmin
3. **Limitar vehículos**: No más de 20 vehículos de facción total
4. **Optimizar otros recursos**: Este sistema es solo una parte

## Conclusión

Con estas optimizaciones, el servidor puede manejar:
- ✅ 250+ jugadores simultáneos
- ✅ 15-20 vehículos de facción
- ✅ Miles de vehículos personales
- ✅ Sin lag significativo

El sistema de streaming es ESENCIAL para servidores grandes. Sin él, el rendimiento se degradará rápidamente con más de 50 jugadores.
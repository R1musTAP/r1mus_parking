# 🚗 R1MUS Parking System

[English](#english) | [Español](#español)

---

## English

### 📋 Description

R1MUS Parking is an advanced parking system for FiveM with QBCore. It completely replaces traditional garage and key systems with a more immersive and optimized solution.

### ⚠️ IMPORTANT: Required Replacements

**This system COMPLETELY REPLACES:**
- ❌ **qb-vehiclekeys** - The system includes its own key handling
- ❌ **qb-garages** - Vehicles are saved where you park them

**You MUST REMOVE or DISABLE these resources before installing R1MUS Parking.**

### ✨ Main Features

#### 🔑 Core System
- **Persistent Parking**: Vehicles remain exactly where you leave them
- **Persistent Damage**: Broken doors, windows, flat tires are maintained
- **Integrated Key System**: Automatic key handling without external resources
- **Anti-Duplication**: Prevents vehicle duplication exploits
- **Real-Time Sync**: Instant updates between players

#### 🚔 Faction Vehicles
- Predefined vehicles for Police, EMS, and Mechanics
- Automatically appear without needing to be on duty
- Job-restricted access
- Flexible model and location configuration

#### 🚤 Boat System
- Automatic boat detection
- Location validation (water/docks only)
- Prevents saving on land

#### 🚧 Impound System
- `/impound` command to confiscate vehicles
- Impounded vehicles go to depot
- Recovery system with fines

#### ⚡ Extreme Optimization
- Streaming system for 250+ players
- Only renders nearby vehicles (150m)
- Permission caching to reduce load
- Single main thread on client

### 📦 Requirements

- **Framework**: QBCore
- **Database**: MySQL with oxmysql
- **Dependencies**: 
  - qb-core
  - oxmysql
  - qb-target (optional, for interactions)

### 🛠️ Installation

#### 1. Preparation
```bash
# FIRST: Disable or remove these resources
ensure qb-vehiclekeys # ❌ REMOVE/COMMENT
ensure qb-garages    # ❌ REMOVE/COMMENT
```

#### 2. Resource Installation
```bash
# Copy r1mus_parking folder to your resources folder
cd resources/[qb]
# Paste r1mus_parking here
```

#### 3. Database
Run the `install.sql` file in your MySQL database:
```sql
-- The file will create necessary tables:
-- player_parked_vehicles
-- faction_vehicles
```

#### 4. Server Configuration
In your `server.cfg`:
```cfg
ensure r1mus_parking
```

#### 5. Restart Server
Fully restart your FiveM server.

### ⚙️ Configuration

All configuration is in `config.lua`:

#### General Configuration
```lua
Config.SaveInterval = 300000        -- Auto-save every 5 minutes
Config.VehicleCheckRadius = 50.0    -- Detection radius
Config.MaxVehiclesPerPlayer = 10    -- Limit per player
Config.EnableFactionVehicles = true -- Enable faction vehicles
```

#### Faction Vehicles
```lua
Config.FactionVehicles = {
    ['police'] = {
        vehicles = {
            {model = 'police', coords = vector3(x, y, z), heading = 0.0}
        }
    }
}
```

### 📝 Commands

#### Player Commands
- `/park` - Park your current vehicle
- `/unpark` - Show list of parked vehicles
- `/findcar [plate]` - Locate your vehicle

#### Admin Commands
- `/resetparking` - Reset parking system
- `/clearparking [playerid]` - Clear player's vehicles
- `/resetfactionvehicles` - Reset faction vehicles
- `/impound [playerid]` - Impound nearest vehicle

### 🔧 Troubleshooting

#### Vehicles don't appear
1. Verify you removed qb-garages and qb-vehiclekeys
2. Check F8 console for errors
3. Ensure SQL tables were created correctly

#### Faction vehicles misplaced
1. Use `/resetfactionvehicles`
2. Adjust coordinates in `config.lua`

#### Performance issues
1. Reduce `Config.StreamingDistance` to 100.0
2. Increase `Config.StreamingInterval` to 2000
3. Check optimization guide: `OPTIMIZATION_GUIDE.md`

### 📚 Additional Documentation

- **[FACTION_VEHICLES.md](FACTION_VEHICLES.md)** - Complete faction vehicles guide
- **[HIGH_CAPACITY_GUIDE.md](HIGH_CAPACITY_GUIDE.md)** - Optimization for 250+ players
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Detailed troubleshooting
- **[OPTIMIZATION_GUIDE.md](OPTIMIZATION_GUIDE.md)** - Performance guide

### 🌐 Translations

The system includes multi-language support:
- Spanish (es)
- English (en)

To add more languages, copy and translate files in the `locales/` folder.

---

## Español

### 📋 Descripción

R1MUS Parking es un sistema de estacionamiento avanzado para FiveM con QBCore. Reemplaza completamente los sistemas de garaje y llaves tradicionales con una solución más inmersiva y optimizada.

### ⚠️ IMPORTANTE: Reemplazos Necesarios

**Este sistema REEMPLAZA COMPLETAMENTE:**
- ❌ **qb-vehiclekeys** - El sistema incluye su propio manejo de llaves
- ❌ **qb-garages** - Los vehículos se guardan donde los estacionas

**Debes ELIMINAR o DESACTIVAR estos recursos antes de instalar R1MUS Parking.**

### ✨ Características Principales

#### 🔑 Sistema Base
- **Estacionamiento Persistente**: Los vehículos permanecen exactamente donde los dejas
- **Daños Persistentes**: Puertas rotas, ventanas, llantas ponchadas se mantienen
- **Sistema de Llaves Integrado**: Manejo automático de llaves sin recursos externos
- **Anti-Duplicación**: Previene exploits de duplicación de vehículos
- **Sincronización en Tiempo Real**: Actualización instantánea entre jugadores

#### 🚔 Vehículos de Facción
- Vehículos predefinidos para Policía, EMS y Mecánicos
- Aparecen automáticamente sin necesidad de estar en servicio
- Acceso restringido por trabajo
- Configuración flexible de modelos y ubicaciones

#### 🚤 Sistema de Barcos
- Detección automática de embarcaciones
- Validación de ubicación (solo en agua/muelles)
- Prevención de guardado en tierra

#### 🚧 Sistema de Decomiso
- Comando `/impound` para confiscar vehículos
- Los vehículos decomisados van al depósito
- Sistema de recuperación con multas

#### ⚡ Optimización Extrema
- Sistema de streaming para 250+ jugadores
- Renderizado solo de vehículos cercanos (150m)
- Caché de permisos para reducir carga
- Un solo thread principal en cliente

### 📦 Requisitos

- **Framework**: QBCore
- **Base de Datos**: MySQL con oxmysql
- **Dependencias**: 
  - qb-core
  - oxmysql
  - qb-target (opcional, para interacciones)

### 🛠️ Instalación

#### 1. Preparación
```bash
# PRIMERO: Desactiva o elimina estos recursos
ensure qb-vehiclekeys # ❌ ELIMINAR/COMENTAR
ensure qb-garages    # ❌ ELIMINAR/COMENTAR
```

#### 2. Instalación del Recurso
```bash
# Copia la carpeta r1mus_parking a tu carpeta de recursos
cd resources/[qb]
# Pega aquí r1mus_parking
```

#### 3. Base de Datos
Ejecuta el archivo `install.sql` en tu base de datos MySQL:
```sql
-- El archivo creará las tablas necesarias:
-- player_parked_vehicles
-- faction_vehicles
```

#### 4. Configuración del Servidor
En tu `server.cfg`:
```cfg
ensure r1mus_parking
```

#### 5. Reinicia el Servidor
Reinicia completamente tu servidor FiveM.

### ⚙️ Configuración

Toda la configuración se encuentra en `config.lua`:

#### Configuración General
```lua
Config.SaveInterval = 300000        -- Guardado automático cada 5 minutos
Config.VehicleCheckRadius = 50.0    -- Radio de detección
Config.MaxVehiclesPerPlayer = 10    -- Límite por jugador
Config.EnableFactionVehicles = true -- Activar vehículos de facción
```

#### Vehículos de Facción
```lua
Config.FactionVehicles = {
    ['police'] = {
        vehicles = {
            {model = 'police', coords = vector3(x, y, z), heading = 0.0}
        }
    }
}
```

### 📝 Comandos

#### Comandos de Jugador
- `/park` - Estaciona tu vehículo actual
- `/unpark` - Muestra lista de vehículos estacionados
- `/findcar [placa]` - Localiza tu vehículo

#### Comandos de Admin
- `/resetparking` - Reinicia el sistema de parking
- `/clearparking [playerid]` - Limpia vehículos de un jugador
- `/resetfactionvehicles` - Reinicia vehículos de facción
- `/impound [playerid]` - Decomisa el vehículo más cercano

### 🔧 Solución de Problemas

#### Los vehículos no aparecen
1. Verifica que eliminaste qb-garages y qb-vehiclekeys
2. Revisa la consola F8 por errores
3. Asegúrate que las tablas SQL se crearon correctamente

#### Vehículos de facción mal ubicados
1. Usa `/resetfactionvehicles`
2. Ajusta las coordenadas en `config.lua`

#### Problemas de rendimiento
1. Reduce `Config.StreamingDistance` a 100.0
2. Aumenta `Config.StreamingInterval` a 2000
3. Revisa la guía de optimización: `OPTIMIZATION_GUIDE.md`

### 📚 Documentación Adicional

- **[FACTION_VEHICLES.md](FACTION_VEHICLES.md)** - Guía completa de vehículos de facción
- **[HIGH_CAPACITY_GUIDE.md](HIGH_CAPACITY_GUIDE.md)** - Optimización para 250+ jugadores
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Solución detallada de problemas
- **[OPTIMIZATION_GUIDE.md](OPTIMIZATION_GUIDE.md)** - Guía de rendimiento

### 🌐 Traducciones

El sistema incluye soporte multiidioma:
- Español (es)
- Inglés (en)

Para añadir más idiomas, copia y traduce los archivos en la carpeta `locales/`.

---

### 💡 Advanced Features / Características Avanzadas

#### Integrated Key System / Sistema de Llaves Integrado
- Automatic keys when spawning vehicles / Llaves automáticas al sacar vehículos
- Share keys with `/givekeys` / Compartir llaves con `/givekeys`
- Configurable anti-theft system / Sistema anti-robo configurable

#### Job Integration / Integración con Trabajos
- Compatible with all QBCore jobs / Compatible con todos los trabajos de QBCore
- Job vehicles saved separately / Vehículos de trabajo se guardan separadamente
- Configurable job restrictions / Restricciones por trabajo configurables

### 🆘 Support / Soporte

If you encounter issues / Si encuentras problemas:
1. Check included documentation / Revisa la documentación incluida
2. Verify server logs / Verifica los logs del servidor
3. Ensure you removed qb-vehiclekeys and qb-garages / Asegúrate de haber eliminado qb-vehiclekeys y qb-garages

### 📄 License / Licencia

This is a premium product. Unauthorized redistribution is prohibited.
Este es un producto premium. La redistribución no autorizada está prohibida.

---

**Developed by R1MUS** | Version 2.0 | QBCore Compatible
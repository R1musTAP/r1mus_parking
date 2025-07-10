# 🚗 R1MUS Parking System


[English](#english) | [Español](#español)

---

## 🚀 Plug & Play: QBCore, Qbox, ESX

**R1MUS Parking** es un sistema universal de parking persistente y llaves para FiveM, compatible automáticamente con **QBCore**, **Qbox** y **ESX**. Detecta el framework al iniciar y adapta menús, notificaciones y funciones sin requerir cambios manuales.

**Incluye:**
- Traducciones completas (en/es) y fácil extensión a más idiomas
- Sistema de llaves y garaje universal (reemplaza cualquier recurso de llaves/garaje)
- Menú de recuperación de vehículos incautados con PED/NPC
- Persistencia real de posición, daños y llaves
- Optimización extrema para servidores grandes

**IMPORTANTE:**
- Elimina cualquier recurso de llaves o garaje anterior (qb-vehiclekeys, qb-garages, etc.)
- Solo arrastra, configura y usa. ¡Plug & Play!

---

---


## English


### 📋 Description

R1MUS Parking is a next-generation, universal parking and vehicle management system for FiveM. It fully replaces traditional garages and key systems, offering a realistic, persistent, and highly optimized experience. Now compatible with QBCore, Qbox, and ESX (auto-detect).


### ⚠️ IMPORTANT: Required Replacements

**This system COMPLETELY REPLACES:**
- ❌ Any key/garage resource (qb-vehiclekeys, qb-garages, esx_garage, etc.)

**REMOVE or DISABLE these before installing R1MUS Parking.**


### ✨ Main Features


#### 🔑 Core System
- **Framework auto-detection**: QBCore, Qbox, ESX (no config needed)
- **Persistent Parking**: Vehicles remain exactly where you leave them
- **Persistent Damage**: Broken doors, windows, flat tires are maintained
- **Integrated Key System**: Automatic key handling, no external scripts
- **Anti-Duplication**: Prevents vehicle duplication exploits
- **Real-Time Sync**: Instant updates between players


#### 🚔 Faction Vehicles
- Predefined vehicles for Police, EMS, Mechanic (or any job)
- All faction vehicles visible to all players (configurable)
- Job-restricted access (optional)
- Flexible model and location configuration


#### 🚤 Boat System
- Automatic boat detection and type saving (`car`/`boat`)
- Location validation (water/docks only)
- Prevents saving on land
- Lock/unlock system for boats (same as cars)


#### 🚧 Impound System
- `/impound` command to confiscate vehicles
- Two recovery modes:
  - **On Pay**: Vehicle is spawned in the depot only after paying the fine
  - **Always Visible**: All impounded vehicles are always spawned in the depot (configurable)
- **Recovery menu with PED at depot**: Interact with a PED/NPC to recover impounded vehicles
- Vehicles are organized to avoid collisions
- Recovery system with fines and menu


#### 🔔 Notification & Menu System
- Compatible with qb, origen_notify, okokNotify, mythic_notify, esx:showNotification, esx_menu_default, qb-menu, and custom systems
- Multi-language support (EN/ES, easily extendable)

#### ⚡ Extreme Optimization
- Streaming system for 250+ players
- Only renders nearby vehicles (150m)
- Permission caching to reduce load
- Single main thread on client


### 📦 Requirements

- **Framework**: QBCore, Qbox, or ESX (auto-detect)
- **Database**: MySQL with oxmysql
- **Dependencies**: 
  - qb-core or qbx_core or es_extended
  - oxmysql
  - qb-target (optional, for interactions)



### 🛠️ Installation (QBCore, Qbox, ESX)

#### 1. Preparation
```bash
# FIRST: Disable or remove any garage/key resources
ensure qb-vehiclekeys # ❌ REMOVE/COMMENT
ensure qb-garages    # ❌ REMOVE/COMMENT
ensure esx_garage    # ❌ REMOVE/COMMENT (if ESX)
```

#### 2. Resource Installation
```bash
# Copy r1mus_parking folder to your resources folder
cd resources/[qb] (or your custom folder)
# Paste r1mus_parking here
```


#### 3. Database
Run the `install.sql` file in your MySQL database:
```sql
-- The file will create necessary tables:
-- r1mus_parked_vehicles
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
Config.SaveInterval = 30000        -- Auto-save every 30 seconds
Config.MaxVehiclesPerPlayer = 10   -- Limit per player
Config.Locale = 'en'               -- Language: 'en' or 'es' (add more in locales/)
Config.NotifyType = 'qb'           -- Notification system: 'qb', 'origen', 'okok', 'mythic', 'custom'
```

#### Faction Vehicles
```lua
Config.FactionVehicles = {
    enabled = true,
    alwaysVisible = true, -- All faction vehicles visible to all
    lockToFaction = false, -- Anyone can use (set true to restrict)
    factions = {
        ['police'] = {
            vehicles = {
                {model = 'police', coords = vector3(x, y, z), heading = 0.0}
            }
        }
    }
}
```

#### Impound/Recovery
```lua
Config.Impound = {
    enabled = true,
    spawnMode = 'onpay', -- or 'always'
    location = vector3(409.0, -1625.0, 29.3),
    heading = 230.0,
    fee = 500,
    blip = { enabled = true, sprite = 68, color = 3, scale = 0.8, label = "Municipal Depot" }
}
```

#### Boat System
```lua
Config.BoatParking = {
    enabled = true,
    docks = { -- Add your docks here
        { coords = vector3(123.0, -800.0, 30.0), name = "Puerto Central", blip = { sprite = 410, color = 3, scale = 0.7 } }
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
- `/impound` - Impound nearest vehicle


### 🔧 Troubleshooting

#### Vehicles don't appear
1. Verify you removed qb-garages and qb-vehiclekeys
2. Check F8 console for errors
3. Ensure SQL tables were created correctly


#### Faction vehicles misplaced
1. Use `/resetfactionvehicles`
2. Adjust coordinates in `config.lua`

#### Impound/Recovery issues
1. Make sure the PED is present at the depot location
2. Use the PED to open the recovery menu
3. Check `Config.Impound` settings

#### Boat type not saved
1. Make sure you are using the latest version (boat detection improved)
2. Check debug logs if enabled

#### Performance issues
1. Reduce `Config.StreamingDistance` to 100.0
2. Increase `Config.StreamingInterval` to 2000

---


## Español


### 📋 Descripción

R1MUS Parking es un sistema universal de parking persistente y llaves para FiveM, compatible automáticamente con QBCore, Qbox y ESX. Reemplaza completamente los sistemas de garaje y llaves tradicionales con una solución más inmersiva, optimizada y multilenguaje.


### ⚠️ IMPORTANTE: Reemplazos Necesarios

**Este sistema REEMPLAZA COMPLETAMENTE:**
- ❌ Cualquier recurso de llaves o garaje (qb-vehiclekeys, qb-garages, esx_garage, etc.)

**Debes ELIMINAR o DESACTIVAR estos recursos antes de instalar R1MUS Parking.**

### ✨ Características Principales


#### 🔑 Sistema Base
- **Detección automática de framework**: QBCore, Qbox, ESX (no requiere configuración)
- **Estacionamiento Persistente**: Los vehículos permanecen exactamente donde los dejas
- **Daños Persistentes**: Puertas rotas, ventanas, llantas ponchadas se mantienen
- **Sistema de Llaves Integrado**: Manejo automático de llaves sin recursos externos
- **Anti-Duplicación**: Previene exploits de duplicación de vehículos
- **Sincronización en Tiempo Real**: Actualización instantánea entre jugadores


#### 🚔 Vehículos de Facción
- Vehículos predefinidos para Policía, EMS, Mecánicos (o cualquier trabajo)
- Visibles para todos los jugadores (configurable)
- Acceso restringido por trabajo (opcional)
- Configuración flexible de modelos y ubicaciones


#### 🚤 Sistema de Barcos
- Detección automática de embarcaciones y tipo (`car`/`boat`)
- Validación de ubicación (solo en agua/muelles)
- Prevención de guardado en tierra



#### 🚧 Sistema de Decomiso
- Comando `/impound` para confiscar vehículos (o integración con menú de trabajo)
- Dos modos de recuperación:
  - **Al Pagar**: El vehículo se spawnea en el depósito solo después de pagar la multa
  - **Siempre Visible**: Todos los vehículos decomisados están siempre spawneados en el depósito (configurable)
- Menú de recuperación con PED/NPC en el depósito
- Los vehículos se organizan para evitar colisiones
- Sistema de recuperación con multas y menú


#### ⚡ Optimización Extrema
- Sistema de streaming para 250+ jugadores
- Renderizado solo de vehículos cercanos (150m)
- Caché de permisos para reducir carga
- Un solo thread principal en cliente


### 📦 Requisitos

- **Framework**: QBCore, Qbox o ESX (auto-detección)
- **Base de Datos**: MySQL con oxmysql
- **Dependencias**: 
  - qb-core, qbx_core o es_extended
  - oxmysql
  - qb-target (opcional, para interacciones)


### 🛠️ Instalación (QBCore, Qbox, ESX)

#### 1. Preparación
```bash
# PRIMERO: Desactiva o elimina cualquier recurso de llaves/garaje
ensure qb-vehiclekeys # ❌ ELIMINAR/COMENTAR
ensure qb-garages    # ❌ ELIMINAR/COMENTAR
ensure esx_garage    # ❌ ELIMINAR/COMENTAR (si usas ESX)
```

#### 2. Instalación del Recurso
```bash
# Copia la carpeta r1mus_parking a tu carpeta de recursos
cd resources/[qb] (o tu carpeta personalizada)
# Pega aquí r1mus_parking
```


#### 3. Base de Datos
Ejecuta el archivo `install.sql` en tu base de datos MySQL:
```sql
-- El archivo creará las tablas necesarias:
-- r1mus_parked_vehicles
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
Config.Locale = 'es'               -- Idioma: 'en' o 'es' (agrega más en locales/)
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
- `/impound` - Decomisa el vehículo más cercano

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


### 📚 Additional Documentation

- **[FACTION_VEHICLES.md](FACTION_VEHICLES.md)** - Faction vehicles guide
- **[HIGH_CAPACITY_GUIDE.md](HIGH_CAPACITY_GUIDE.md)** - Optimization for 250+ players
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Troubleshooting
- **[OPTIMIZATION_GUIDE.md](OPTIMIZATION_GUIDE.md)** - Performance guide


### 🌐 Translations / Traducciones

Multi-language support:
- Spanish (es)
- English (en)

To add more languages, copy and translate the files in the `locales/` folder.
Para agregar más idiomas, copia y traduce los archivos en la carpeta `locales/`.

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

**Developed by R1MUS** | Version 2.0 | QBCore/Qbox/ESX Compatible
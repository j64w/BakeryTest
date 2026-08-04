# Arquitectura Técnica (Roblox Studio)

## Enfoque general
Arquitectura basada en **servicios** (ModuleScripts tipo Service),
siguiendo el patrón común en Roblox: lógica de servidor autoritativa,
cliente solo para input/feedback visual, comunicación vía RemoteEvents /
RemoteFunctions, y un framework ligero de tipo Knit o uno propio simple
para no reinventar demasiado en el MVP.

## Estructura de carpetas en Roblox Studio (Explorer)

```
ServerScriptService
└── Server
    ├── Main.server.lua              -- bootstrap, requiere e inicia todos los servicios
    └── Services
        ├── DataService.lua          -- guardado/carga de datos (DataStore)
        ├── EconomyService.lua       -- monedas, EXP, nivel
        ├── RecipeService.lua        -- catálogo de recetas y desbloqueos
        ├── StationService.lua       -- lógica de mesas y hornos (preparación/cocción)
        ├── ShelfService.lua         -- lógica de estantes (stock disponible)
        ├── CarryService.lua         -- item temporal que carga el jugador durante el loop
        ├── CustomerService.lua      -- spawn e IA de NPCs clientes
        ├── MissionService.lua       -- progreso y recompensas de misiones
        └── UpgradeService.lua       -- compra y aplicación de mejoras

ReplicatedStorage
├── Shared
│   ├── Modules
│   │   ├── RecipeData.lua           -- tabla de datos de recetas/productos
│   │   ├── LevelData.lua            -- EXP requerida por nivel
│   │   ├── StationData.lua          -- tiempos/capacidades base
│   │   ├── UpgradeData.lua          -- tabla de datos de mejoras
│   │   ├── MissionData.lua          -- tabla de datos de misiones
│   │   └── Enums.lua                -- constantes (rarezas, estados, etc.)
│   └── Net
│       └── Remotes.lua              -- definición centralizada de RemoteEvents/Functions
└── Assets
    ├── Models                       -- modelos de estaciones, decoraciones
    └── UI                           -- ScreenGuis reutilizables (si no usas StarterGui directo)

StarterPlayer
└── StarterPlayerScripts
    └── Client
        ├── Main.client.lua          -- bootstrap del cliente
        └── Controllers
            ├── UIController.lua         -- HUD (monedas, EXP, nivel, misiones)
            ├── StationController.lua    -- input en mesa/horno (interacción, prompts)
            ├── ShelfController.lua      -- input al colocar producto en estante
            └── NotificationController.lua -- popups de recompensa/desbloqueo

StarterGui
└── HUD                              -- interfaz principal (monedas, EXP, barra de nivel)

Workspace
└── Bakery
    ├── PreparationArea
    │   └── Table_01                 -- estación de mesa (con ProximityPrompt)
    ├── BakingArea
    │   └── Oven_01                  -- estación de horno (con ProximityPrompt)
    ├── DisplayArea
    │   └── Shelf_01                 -- estante (con slots definidos)
    ├── OfficeArea
    │   └── Computer_01              -- compra/desbloqueo de productos
    └── CustomerArea
        ├── EntrancePoint
        └── ExitPoint
```

## Servicios principales (server-side)

### DataService
- Carga y guarda datos del jugador (DataStore2 o ProfileService
  recomendado en lugar de DataStore crudo, para evitar pérdida de datos).
- Expone API simple: `GetData(player)`, `UpdateData(player, path, value)`.

### EconomyService
- Maneja monedas y experiencia.
- Calcula subida de nivel según tabla de EXP requerida por nivel.
- Dispara evento `LevelUp` cuando corresponde, que otros servicios
  (RecipeService, UpgradeService) escuchan para desbloquear contenido.

### RecipeService
- Mantiene qué recetas están desbloqueadas por jugador según su nivel.
- Expone `GetUnlockedRecipes(player)` y `IsRecipeUnlocked(player, recipeId)`.

### StationService
- Lógica de mesa: inicia preparación, valida receta desbloqueada, aplica
  tiempo de preparación (modificado por mejoras), entrega producto
  "crudo/listo para hornear".
- Lógica de horno: recibe producto, corre temporizador de cocción,
  entrega producto terminado.
- El estado de producto quemado queda reservado para post-MVP.

### ShelfService
- Recibe productos terminados y los coloca en slots de estante.
- Expone stock disponible para que CustomerService pueda "comprar".

### CarryService
- Mantiene el producto temporal que lleva el jugador entre estaciones.
- Expone `GetCarriedItem(player)`, `SetCarriedItem(player, item)` y
  `ClearCarriedItem(player)`.
- En el MVP solo permite 1 item a la vez. No se persiste en DataStore; si el
  jugador sale, pierde el producto en proceso.

### CustomerService
- Spawnea NPCs, corre su máquina de estados simple (entrar → buscar →
  comprar/esperar → salir).
- Al comprar, descuenta stock del ShelfService y llama a
  EconomyService para pagar al jugador.

### MissionService
- Escucha eventos de otros servicios (venta realizada, producto
  horneado, mejora comprada) y actualiza progreso de misiones activas.

### UpgradeService
- Valida costo y nivel requerido, cobra monedas vía EconomyService, y
  aplica el efecto de la mejora (velocidad, capacidad, etc.) sobre
  StationService/ShelfService/CustomerService según corresponda.

## Comunicación cliente-servidor
- Toda lógica de negocio (validación de compra, cocción, venta) vive en
  el servidor. El cliente solo dispara intenciones ("quiero preparar
  esto", "quiero comprar esta mejora") vía RemoteEvent/Function y el
  servidor responde con el resultado autoritativo.
- Usar `ProximityPrompt` en mesas y hornos para la interacción física
  (estándar de Roblox, evita raycasting manual).

## Remotes mínimos del MVP
| Remote | Tipo | Uso |
|---|---|---|
| `RequestPrepareProduct` | RemoteEvent | Cliente pide iniciar preparación |
| `RequestCollectFromTable` | RemoteEvent | Cliente pide recoger masa preparada |
| `RequestStartOven` | RemoteEvent | Cliente pide meter masa al horno |
| `RequestCollectFromOven` | RemoteEvent | Cliente pide recoger producto horneado |
| `RequestPlaceOnShelf` | RemoteEvent | Cliente pide colocar producto en estante |
| `RequestBuyRecipe` | RemoteEvent | Cliente pide comprar/desbloquear producto desde computadora |
| `StateUpdated` | RemoteEvent | Servidor envía cambios de HUD/estaciones |
| `Notify` | RemoteEvent | Servidor envía popups simples |

Los nombres pueden cambiar, pero la regla no: cada Remote representa una
intención del jugador y el servidor valida estado, distancia, capacidad y
receta desbloqueada.

## Persistencia de datos (esquema sugerido)
```lua
PlayerData = {
    Coins = 0,
    Experience = 0,
    Level = 1,
    UnlockedRecipes = {"bread_basic"},
    Upgrades = {
        Oven = { Speed = 1, Capacity = 1, Quality = 1 },
        Table = { Slots = 1, Speed = 1 },
        Shelf = { Capacity = 3 },
        Shop = { CustomerRate = 1 },
    },
    MissionProgress = {},
}
```

`CarriedItem`, timers activos de estaciones y NPCs vivos no deben guardarse
en DataStore para el MVP. Son estado de sesión.

## Eventos internos recomendados
- `ProductPrepared(player, recipeId)`
- `ProductBaked(player, recipeId)`
- `ProductShelved(player, recipeId)`
- `ProductSold(player, recipeId, coins, experience)`
- `LevelChanged(player, newLevel)`
- `StationStateChanged(player, stationId, newState)`

Usar eventos internos entre servicios evita que `MissionService`,
`EconomyService` y `CustomerService` queden acoplados directamente entre sí.

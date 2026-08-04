# Tool en el Inventario y Clientes Visuales Reales (v4)

Sigue a [17-fixes-ui-mesa-computadora.md](17-fixes-ui-mesa-computadora.md).

## 1. Lo que cargás ahora es una Tool real en tu inventario

Antes, "llevar" masa o pan horneado era solo un estado invisible en el
servidor (`CarryService`), reflejado únicamente por un texto en el HUD
("Hands: CarryingBaked"). Ahora, cada vez que:

- recogés la masa de la mesa (`RequestCollectFromTable`), o
- sacás el pan del horno (`RequestCollectFromOven`),

el servidor crea una **`Tool` real** y la pone en tu `Backpack` (tu
inventario/hotbar de Roblox), y la equipa de una para que la veas en la
mano al instante. La Tool tiene:

- Un `Handle` (bolita) del color de la receta (definido en
  `RecipeData.<receta>.Color`) si está horneada, o un color crema
  genérico si todavía es masa cruda.
- Un cartel flotante con el nombre ("Pan basico" o "Pan basico (masa)").
- `CanBeDropped = false`, para que no se pueda perder tirándola al piso
  por accidente.

Cuando la usás (la metés al horno, o la ponés en el estante), la Tool
se destruye automáticamente — `CarryService` la crea/destruye en el
mismo lugar donde ya se guardaba/limpiaba el estado, así que **no hubo
que tocar** `StationService` ni `ShelfService` para esto.

### Archivo tocado
- `src/server/Services/CarryService.luau` (reescrito)
- `src/shared/Modules/RecipeData.luau` (se agregó `Color` a cada receta)

## 2. Clientes visuales reales que usan el avatar de tus amigos

`CustomerService` dejó de ser una simulación invisible (un timer que
sumaba monedas de la nada). Ahora, cada vez que hay stock disponible:

1. Se construye un personaje real usando
   `Players:GetHumanoidDescriptionFromUserId` sobre un **amigo al azar
   del jugador** (`Players:GetFriendsAsync`), armado con
   `Players:CreateHumanoidModelFromDescription`. O sea: el cliente que
   entra a tu panadería literalmente tiene la cara/ropa de uno de tus
   amigos de Roblox.
2. Aparece en el `EntrancePoint`.
3. Camina hasta el **estante** (`Shelf_01`) — el producto — y se queda
   un instante "revisando".
4. Camina hasta la **caja registradora**, una parte nueva
   (`Register_01`, con su cartelito "Caja") ubicada junto al estante.
5. Al llegar a la caja se acredita la venta (monedas + EXP), igual que
   antes pero ahora atada a que el cliente **realmente llegue** a pagar.
6. Camina hasta el `ExitPoint` y se destruye.

### Red de seguridad (importante para probar en Studio)
Si el jugador no tiene amigos, o si `GetFriendsAsync` /
`GetHumanoidDescriptionFromUserId` fallan (esto es *normal* al probar
con **Play Solo** en Studio, porque el "jugador" de prueba no es una
cuenta real de Roblox y esas consultas fallan), el sistema cae a un
avatar clásico genérico con colores al azar (`HumanoidDescription`
en blanco). Nada se rompe, simplemente no vas a ver la cara de tus
amigos hasta probarlo en un servidor publicado con cuentas reales
logueadas.

### Límites y detalles de implementación
- Máximo 2 clientes visuales caminando a la vez por jugador
  (`MAX_CUSTOMERS_PER_PLAYER`), para no saturar la mesa/estante/caja de
  gente.
- El stock se reserva (`ShelfService:TryRemoveStock`) en el momento en
  que el cliente **empieza a caminar**, no cuando llega a la caja — así
  dos clientes nunca pelean por el mismo último producto.
- Cada tramo de camino tiene un timeout de 12s: si el `Humanoid` se
  traba o el `MoveTo` no dispara `MoveToFinished`, el cliente sigue el
  recorrido igual en vez de quedar parado para siempre.
- Los personajes no colisionan (`CanCollide = false` en todas sus
  partes) para que no empujen al jugador ni se traben entre ellos.

### Conocido / pendiente (no implementado todavía)
- Los NPCs no tienen script de animación (`Animate`), así que caminan
  "deslizándose" en vez de mover brazos y piernas. Para arreglarlo hay
  que copiarles un script `Animate` (el mismo que trae cualquier
  personaje de jugador) — no lo agregué porque depende de un asset que
  no está disponible en este entorno de edición.
- El estante y la caja son partes únicas y compartidas (igual que ya
  pasaba con la mesa y el horno): si varios jugadores prueban al mismo
  tiempo en el mismo servidor, sus clientes van a converger en el mismo
  punto físico del mapa. Es la misma limitación de MVP de siempre,
  documentada desde el principio.

### Archivos tocados
- `src/server/Services/CustomerService.luau` (reescrito)
- `default.project.json` — se agregó `Register_01` (con su cartel
  "Caja") dentro de `Bakery.CustomerArea`.

# Atención Manual en la Caja: Click, Bolsas y Cobro (v5)

Sigue a [18-tool-inventario-clientes-visuales.md](18-tool-inventario-clientes-visuales.md).

Reemplaza el cobro automático por un flujo manual de 3 pasos, y corrige
que el cliente atravesara la caja en vez de detenerse delante de ella.

**Nada de esto tocó `default.project.json`** — todo (el `ProximityPrompt`
de cobro, los `ClickDetector`, las bolsas) se crea por código, para no
repetir el problema de sincronización de la vuelta anterior. Lo único
que se usa del mapa es lo que ya tenías: `Register_01`, `Shelf_01`,
`EntrancePoint`, `ExitPoint`, y ahora también `ReplicatedStorage.Models.Bag`
(que ya tenías creado a mano).

## El nuevo recorrido del cliente

1. **Entra y camina hasta el estante** (igual que antes) — revisa el
   producto un instante.
2. **Camina hasta pararse delante de la caja**, no encima ni a través.
   Antes el punto de destino era el centro de `Register_01`; ahora se
   calcula un punto **frente** a la caja (del lado por donde viene el
   cliente), a `halfDepth + 1.8` studs de su cara, así nunca la atraviesa.
3. **Espera con un cartel "🛎 Click para atender"** flotando sobre su
   cabeza. No pasa nada hasta que el jugador le hace click (a él o a
   cualquier parte de su cuerpo — el click funciona en todo el modelo,
   no solo en un punto exacto).
4. **Aparecen las bolsas**: una por cada unidad que compró (si el
   cliente pidió 2 panes, aparecen 2 bolsas), clonadas de
   `ReplicatedStorage.Models.Bag`, apoyadas sobre el mostrador de la
   caja con una animación de flotación. Cada click hace un "pop"
   (se achica y desaparece) hasta que no queda ninguna.
5. **Se habilita el `ProximityPrompt` "Cobrar"** en la propia caja,
   mostrando la cantidad y el total (ej. "2x Pan basico · $10"). Al
   presionar `E`, se acredita la venta completa (monedas × cantidad,
   EXP × cantidad) y el cliente se va.

## Pedidos de más de una unidad
Antes cada visita vendía siempre 1 unidad. Ahora, al generarse el
cliente, se reserva una cantidad al azar entre 1 y 3 (limitada por el
stock real disponible) del mejor producto en el estante — eso es lo
que determina cuántas bolsas van a aparecer.

## Un cliente a la vez en la caja
Se agregó un "mutex" simple por jugador: si ya hay un cliente parado en
la caja, el siguiente cliente espera cerca del estante hasta que se
libere, en vez de superponerse con el primero.

## Redes de seguridad (para que nadie quede trabado)
Cada paso manual tiene un límite de espera; si el jugador nunca hace
click o nunca cobra, el cliente sigue su curso solo después de:
- 45s esperando que le hagan click para atenderlo.
- 60s esperando que se clickeen todas las bolsas.
- 45s esperando que se cobre con el `ProximityPrompt`.
- 90s esperando que se libere la caja si hay otro cliente ocupándola.

Así ningún cliente queda parado para siempre bloqueando la caja si el
jugador se distrae.

## Si `ReplicatedStorage.Models.Bag` no existe
El código lo busca con `FindFirstChild` (no `WaitForChild`, para no
trabar el servidor si falta); si no lo encuentra, tira un `warn` en el
Output y **se salta directamente el paso de las bolsas**, pasando de
"atender" a "cobrar" sin bolsas visibles. El juego sigue funcionando,
solo pierde ese paso visual.

## Archivo tocado
- `src/server/Services/CustomerService.luau` (reescrito por completo)

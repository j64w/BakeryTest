# Ingredientes Interactivos y Feedback Visual (v2)

Este documento describe los cambios hechos sobre el MVP para reemplazar la
espera pasiva en la mesa por una interacción real, y para que el jugador
siempre sepa cuánto falta para que algo esté listo.

## Qué cambió

### 1. Los ingredientes ahora aparecen físicamente en la mesa
Al elegir una receta en el menú ("Elegir producto"), el servidor ya no
arranca un simple temporizador: **hace aparecer una esfera flotante por
cada ingrediente** de la receta encima de `Table_01`, con su nombre en un
cartel y su propio `ProximityPrompt`.

- `bread_basic` → Harina, Agua, Levadura (3 ingredientes)
- `croissant` → Harina, Mantequilla, Agua, Azúcar (4 ingredientes)
- `brioche` → Harina, Mantequilla, Huevo, Leche, Azúcar (5 ingredientes)

El jugador debe acercarse y **presionar cada uno** (mantener `E` un
instante). Cada ingrediente:
- aparece con una animación de "pop" (crece desde cero),
- flota suavemente para que la mesa se vea viva,
- al presionarlo, suelta chispas de su color y vuela hacia el centro de la
  mesa (como si se echara a un bol) antes de desaparecer.

Cuando el último ingrediente fue presionado, la mesa entra en un breve
estado de "Amasando" (1.2s) y luego la masa queda lista para llevar al
horno — igual que antes, pero ahora ganada con interacción real en vez de
solo esperar.

### 2. Nuevo estado de mesa: `AwaitingIngredients`
Se agregó a `Enums.TableState`. El flujo completo de la mesa ahora es:

```
Idle → AwaitingIngredients (presionando ingredientes) → Preparing (amasando, 1.2s) → ReadyToCollect
```

### 3. Tiempo de espera siempre visible
Antes el tiempo restante solo se veía en un cartel flotante sobre la
estación, fácil de perder de vista. Ahora hay dos capas:

- **Cartel 3D mejorado**: tarjeta con esquinas redondeadas, número grande
  y en negrita ("5s") además de la barra de progreso.
- **Panel fijo en pantalla** (abajo, centrado): muestra "Mesa · Amasando —
  2s" y "Horno · Horneando — 6s" mientras algo esté en curso, sin
  importar hacia dónde mires ni la distancia a la estación. Desaparece
  solo cuando no hay nada cocinándose.

### 4. Más animaciones
- **Horno**: ahora tiene una puerta (`Door`) que se desliza hacia arriba
  al empezar a hornear y baja al terminar, más humo (`ParticleEmitter`)
  saliendo mientras cocina.
- **"Listo" con más impacto**: cuando la mesa o el horno pasan a
  `ReadyToCollect`, la tarjeta hace un rebote elástico y suelta un
  destello de partículas doradas.
- **Ingredientes**: pop-in, flotación, chispas al presionar y vuelo hacia
  el bol (ver punto 1).

## Archivos tocados
- `src/shared/Modules/IngredientData.luau` (nuevo) — nombre y color de
  cada ingrediente.
- `src/shared/Modules/RecipeData.luau` — se agregó `Ingredients` a cada
  receta.
- `src/shared/Modules/Enums.luau` — nuevo estado `AwaitingIngredients`.
- `src/shared/Net/Remotes.luau` — nuevo remoto `RequestPressIngredient`.
- `src/server/Services/StationService.luau` — lógica de aparición,
  presión y ensamblado de ingredientes; animación de puerta/humo delegada
  al cliente vía snapshot.
- `src/client/Controllers/StationFeedbackController.luau` — tarjetas
  mejoradas, panel fijo de tiempos, puerta del horno, humo, "pop" de
  listo.
- `src/client/Controllers/RecipeController.luau` — el menú ahora muestra
  la cantidad de ingredientes en vez del tiempo de preparación pasivo.
- `default.project.json` — se agregó la parte `Door` y el `Attachment`
  `SteamAttachment` dentro de `Oven_01`.

## Cómo probarlo en Roblox Studio
1. Sincronizar con Rojo (`rojo serve` + plugin, o `rojo build` según tu
   flujo habitual).
2. Entrar al juego, acercarte a la mesa y presionar `E` → elegir "Pan
   básico".
3. Deberían aparecer 3 esferas (Harina, Agua, Levadura) flotando sobre la
   mesa. Acércate a cada una y mantén `E` para "presionarla".
4. Al presionar la última, la mesa pasa a "Amasando..." y en ~1.2s queda
   lista para recoger.
5. Llevar la masa al horno: ahora la puerta sube y sale humo mientras
   hornea, y el panel inferior de la pantalla muestra los segundos
   restantes en todo momento.

## Ideas para seguir mejorando (no implementado aún)
- Requerir presionar los ingredientes en un orden específico para recetas
  más avanzadas (más dificultad/skill).
- Sonidos por ingrediente y al abrir/cerrar el horno.
- Que cada ingrediente tenga su propio pequeño mini-juego de precisión
  (ej. un timing bar) en vez de una sola presión, para recetas raras o
  épicas.
- Animación de personaje (amasar con las manos) usando `Humanoid:PlayEmote`
  o una animación custom mientras se procesa cada ingrediente.

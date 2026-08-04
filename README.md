# Bunny's Bakery

Roblox/Rojo base for the MVP described in `AI/`.

The current implementation includes:

- Shared data tables for recipes, levels and station balance.
- Server services for player data, economy, recipes, carried items, stations,
  shelves and basic customer sales.
- Client controllers for HUD, notifications and ProximityPrompt routing.
- A recipe computer where players can buy/unlock Croissant and Brioche.
- A prep table recipe picker for choosing which unlocked product to make.
- A simple `Workspace.Bakery` scene with table, oven, shelf and customer
  waypoints.

## Getting Started
To build the place from scratch, use:

```bash
rojo build -o "BunnysBakery.rbxlx"
```

Next, open `Vibecodinggg.rbxlx` in Roblox Studio and start the Rojo server:

```bash
rojo serve
```

For more help, check out [the Rojo documentation](https://rojo.space/docs).

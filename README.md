# MiniBlocks

A Luanti (Minetest) mod that lets you cut full blocks into 21 mini-forms
using standard tools.

## Features

- **21 unique shapes** generated from an 8-bit mask (2×2×2 grid)
- **Greedy meshing** — adjacent cubes merge into rectangles to reduce seams
- **Universal** — automatically registers all cube-like blocks from any mod
- **Tool-based cutting** — hold right-click with the right tool to slice a block
- **Crafting** — reassemble forms into full blocks or split them into particles
- **Colored glass** — 12 color variants, crafted with dye
- **Fully translatable** — includes Ukrainian and English

## How it works

Every block is divided into 8 mini-cubes (a 2×2×2 grid). Each shape is
described by an 8-bit mask. When you cut a block, you get 8 particles,
which you can craft into any of the 21 forms.

## Tools

| Tool    | Materials                      |
|---------|--------------------------------|
| Axe     | Wood, logs, planks             |
| Pickaxe | Stone, metal, glass, obsidian  |
| Sword   | Wool                           |

Hold **right-click** on a block with the matching tool to slice it.
The tool wears down as if you were mining normally.

## Crafting

- **8 particles → 1 full block**
- **1 particle ↔ Mini Block Form 1**
- **N particles → Form N** (shaped 3×3 recipe)
- **Form N → N particles** (shapeless)

Particles can only be obtained by cutting blocks with tools.

## Colored glass

Craft with **8 glass + 1 dye** to get 8 colored glass blocks. Available
in 12 colors: red, orange, yellow, green, cyan, blue, violet, magenta,
pink, brown, black, white.

## Installation

Place the `miniblocks` folder into your `mods/` directory. Enable it in
your world settings. Requires `default` (Minetest Game). Optional:
`dye` (for colored glass recipes).

## License

- **Code**: GNU General Public License v3.0 or later (see LICENSE)

This mod is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your
option) any later version.

### Media

This package contains **no media files** — no textures, sounds, or models
are included in the archive.

All textures and sounds used by this mod are referenced **at runtime** from
the Minetest Game `default` mod and are licensed under
[CC BY-SA 3.0](https://github.com/minetest/minetest_game/blob/master/LICENSE.txt)
by their respective authors.

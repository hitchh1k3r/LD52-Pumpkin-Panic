package main

import "core:math"
import rl "raylib"

TileDirt :: struct{}
TileGrass :: struct{}
TileSoil :: struct{}
TilePumpkin :: struct{
  growth : f32,
}
TileWater :: struct{}
TilePortal :: struct{}

Tile :: union {
  TileDirt,
  TileGrass,
  TileSoil,
  TilePumpkin,
  TileWater,
  TilePortal,
}

draw_tile :: proc(cell_pos : CellPos, tile_union : ^Tile) {
  pos := V3{ f32(cell_pos.x), 0, f32(cell_pos.y) }
  switch tile in tile_union {
    case TileWater:
      rl.DrawModel(models.tile, pos, 1, COLOR_TILE_WATER)

    case TileDirt:
      rl.DrawModel(models.tile, pos, 1, COLOR_TILE_DIRT)

    case TileGrass:
      rl.DrawModel(models.tile, pos, 1, COLOR_TILE_GRASS)

    case TileSoil:
      rl.DrawModel(models.tile, pos, 1, COLOR_TILE_SOIL)

    case TilePumpkin:
      rl.DrawModel(models.tile, pos, 1, COLOR_TILE_SOIL)
      vine_scale := math.remap(tile.growth, 0, 1, 0.3, 1.0)
      pumpkin_scale := vine_scale-0.1
      if vine_scale < 0.99 {
        pumpkin_scale = pumpkin_scale * pumpkin_scale * pumpkin_scale
      } else {
        pumpkin_scale = 1 - vine_scale
        pumpkin_scale = 1 - 3000*(pumpkin_scale * pumpkin_scale)
      }
      rl.DrawModel(models.vine, pos, vine_scale, rl.WHITE)
      rl.DrawModel(models.pumpkin, pos + vine_scale*V3{ 0, 0.375, 0 }, pumpkin_scale, rl.WHITE)

    case TilePortal:
      rl.DrawModel(models.tile, pos, 1, COLOR_TILE_GRASS)
      rl.DrawModel(models.portal_border, pos, 1, COLOR_TILE_PORTAL_STONE)
      rl.DrawModel(models.portal_fill, pos, 1, portal_color)
  }
}

update_tile :: proc(cell_pos : CellPos, tile_union : ^Tile) {
  #partial switch tile in tile_union {
    case TilePumpkin:
      update_pumpkin(cell_pos, &tile)
  }
}

update_pumpkin :: proc(cell_pos : CellPos, using pumpkin : ^TilePumpkin) {
  growth = min(growth + inventory.pumpkin_speed*rl.GetFrameTime(), 1.0)
}

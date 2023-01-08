package main

import "core:math"
import rl "raylib"

AutoType :: enum { Plant, Till, Water, Harvest }

AutoClicker :: struct {
  type : AutoType,
  pos : V3,
  dir : V3,
  cooldown : f32,
}

draw_auto_clicker :: proc(using auto_clicker : ^AutoClicker) {
  color : rl.Color
  switch type {
    case .Plant:
      color = { 0x78, 0x99, 0x49, 0xFF }
    case .Till:
      color = { 0x64, 0x27, 0x2C, 0xFF }
    case .Water:
      color = { 0x7E, 0x63, 0x8E, 0xFF }
    case .Harvest:
      color = { 0xF1, 0x8B, 0x49, 0xFF }
  }
  t := 0.25 + (0.75*clamp(cooldown, 0, 1))
  t = t * t
  color.a = u8(t * f32(color.a))
  rl.DrawModel(models.selector, { math.round(auto_clicker.pos.x), 0, math.round(auto_clicker.pos.z) }, 1, color)
}

update_auto_clicker :: proc(using auto_clicker : ^AutoClicker) {
  old_cell := V3_to_cell(pos)

  move:
  {
    new_pos := pos + rl.GetFrameTime()*dir
    new_cell := V3_to_cell(new_pos)
    if old_cell != new_cell {
      if new_cell not_in all_tiles {
        bounce_normal := old_cell-new_cell
        if bounce_normal.x != 0 {
          dir.x = -dir.x
        }
        if bounce_normal.y != 0 {
          dir.z = -dir.z
        }
        break move
      }
    }
    pos = new_pos
  }

  speed := f32(1.0)
  switch type {
    case .Plant:
      speed = 1.0 / 2.0
    case .Till:
      speed = 1.0 / 0.5
    case .Water:
      speed = 1.0 / 1.0
    case .Harvest:
      speed = 1.0 / 1.0
  }
  cooldown += speed*rl.GetFrameTime()
  if cooldown >= 1 {
    switch type {
      case .Plant:
        if tile, ok := all_tiles[old_cell].(TileSoil); ok {
          rl.PlaySound(sounds.plant)
          all_tiles[old_cell] = TilePumpkin{}
          cooldown = 0
        }

      case .Till:
        if tile, ok := all_tiles[old_cell].(TileDirt); ok {
          rl.PlaySound(sounds.auto_till)
          all_tiles[old_cell] = TileSoil{}
          cooldown = 0
        } else if tile, ok := all_tiles[old_cell].(TileGrass); ok {
          rl.PlaySound(sounds.auto_till)
          all_tiles[old_cell] = TileSoil{}
          cooldown = 0
        }

      case .Water:
        if tile, ok := (&(&all_tiles[old_cell]).(TilePumpkin)); ok {
          rl.PlaySound(sounds.water)
          tile.growth += 3 * inventory.pumpkin_speed
          cooldown = 0
        }

      case .Harvest:
        if tile, ok := all_tiles[old_cell].(TilePumpkin); ok {
          if tile.growth >= 1.0 {
            rl.PlaySound(sounds.harvest)
            all_tiles[old_cell] = TileDirt{}
            inventory.pumpkins += inventory.pumpkin_yeild
            cooldown = 0
          }
        }
    }
  }
}

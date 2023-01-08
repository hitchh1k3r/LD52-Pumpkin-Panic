package main

import "core:fmt"
import "core:slice"
import rl "raylib"

MapRegion :: enum {
  None,
  Start,
  Lake,
  Pond,
  South,
  East,
  Portal,
}

regions_gotten : bit_set[MapRegion]

AddTile :: struct {
  pos : CellPos,
  tile : Tile,
}

world_map : [MapRegion][]AddTile

load_map :: proc() {
  img := rl.LoadImage("res/map.png")
  defer rl.UnloadImage(img)
  img_data := ([^]u8)(img.data)
  pixel_size := rl.GetPixelDataSize(1, 1, img.format)

  slice_builder : [dynamic]AddTile
  for region in MapRegion {
    clear(&slice_builder)
    region_green := u8(20 * int(region))
    for y in 0..<img.height {
      for x in 0..<img.width {
        r := img_data[pixel_size * (x + y*img.width) + 0]
        g := img_data[pixel_size * (x + y*img.width) + 1]
        b := img_data[pixel_size * (x + y*img.width) + 2]
        if g == region_green {
          cell_pos := CellPos{ int(x), int(y) }
          if r != 0 {
            if region == .Start {
              min_cell.x = min(min_cell.x, cell_pos.x)
              max_cell.x = max(max_cell.x, cell_pos.x)
              min_cell.y = min(min_cell.y, cell_pos.y)
              max_cell.y = max(max_cell.y, cell_pos.y)
            }
            switch r {
              case 100:
                append(&slice_builder, AddTile{ cell_pos, TileGrass{} })
              case 200:
                append(&slice_builder, AddTile{ cell_pos, TileWater{} })
              case 250:
                append(&slice_builder, AddTile{ cell_pos, TilePortal{} })
            }
          }
        }
      }
    }
    world_map[region] = slice.clone(slice_builder[:])
  }
}

map_add_region :: proc(region : MapRegion) {
  regions_gotten |= { region }
  if story_progress == .Halloween && regions_gotten == { .Start, .Lake, .Pond, .South, .East } {
    story_progress = .Ghost_Spotted
  }
  for add in world_map[region] {
    all_tiles[add.pos] = add.tile
    min_cell.x = min(min_cell.x, add.pos.x)
    max_cell.x = max(max_cell.x, add.pos.x)
    min_cell.y = min(min_cell.y, add.pos.y)
    max_cell.y = max(max_cell.y, add.pos.y)
  }
}

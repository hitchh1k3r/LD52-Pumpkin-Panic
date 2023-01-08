package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:strings"
import "core:c"
import rl "raylib"

DEBUG :: false

GAME_TITLE :: "Pumpkin Panic"
WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720


V3 :: rl.Vector3
CellPos :: [2]int


COLOR_SELECT             :: rl.Color{ 0x13, 0x90, 0xAC, 0x75 }

COLOR_TILE_GRASS         :: rl.Color{ 0xAB, 0xCF, 0x5F, 0xFF }
COLOR_TILE_DIRT          :: rl.Color{ 0x62, 0x4A, 0x30, 0xFF }
COLOR_TILE_SOIL          :: rl.Color{ 0x2F, 0x21, 0x10, 0xFF }
COLOR_TILE_WATER         :: rl.Color{ 0x0B, 0x54, 0x72, 0xFF }
COLOR_TILE_PORTAL_STONE  :: rl.Color{ 0xB5, 0x8F, 0xB6, 0xFF }
COLOR_TILE_PORTAL_FILL_A :: rl.Color{ 0xE5, 0xAE, 0x3E, 0xFF }
COLOR_TILE_PORTAL_FILL_B :: rl.Color{ 0x9B, 0xCF, 0x6F, 0xFF }

COLOR_NEWS_BG            :: rl.Color{ 0xB8, 0x92, 0x6F, 0xFF }
COLOR_NEWS_TEXT          :: rl.Color{ 0x3C, 0x31, 0x45, 0xFF }

COLOR_UI_WATER           :: rl.Color{ 0x13, 0x90, 0xAC, 0xFF }

COLOR_UI_ACT_TIMER       :: rl.Color{ 0xF1, 0x8B, 0x49, 0xFF }
COLOR_UI_ACT_OVERLOAD    :: rl.Color{ 0xBF, 0x2F, 0x37, 0xFF }

COLOR_BG_DAWN            :: rl.Color{ 0xF1, 0x8B, 0x49, 0xFF }
COLOR_BG_MIDDAY          :: rl.Color{ 0x30, 0xBA, 0xB3, 0xFF }
COLOR_BG_DUSK            :: rl.Color{ 0xBF, 0x2F, 0x37, 0xFF }
COLOR_BG_MIDNIGHT        :: rl.Color{ 0x1C, 0x11, 0x25, 0xFF }

// GLOBAL STATE ////////////////////////////////////////////////////////////////////////////////////

  game_controls : enum { Farming, News_Headlines, News_Classifieds, Ending }
  headline := Headline.Intro
  classifieds : [10]ClassifiedAd
  all_tiles : map[CellPos]Tile
  daytime : f32
  portal_color : rl.Color

  min_cell := CellPos{ max(int), max(int) }
  max_cell := CellPos{ min(int), min(int) }
  inventory : struct {
    water : int,
    water_capacity : int,
    water_effect : f32,

    day : int,
    pumpkins : int,
    papers : int,

    pumpkin_yeild : int,
    pumpkin_speed : f32,

    auto_clicker : [dynamic]AutoClicker,
  }

main :: proc() {
  // setup raylib
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, GAME_TITLE)
    rl.SetConfigFlags({ .VSYNC_HINT, .WINDOW_ALWAYS_RUN })
    defer rl.CloseWindow()
    rl.InitAudioDevice()
    defer rl.CloseAudioDevice()
    rl.SetExitKey(.NULL)

    camera := rl.Camera3D{
      fovy = 60,
      position = { 0, 6, 4 },
      target = { 0, 0, 0 },
      projection = .PERSPECTIVE,
      up = { 0, 1, 0 },
    }
    load_graphics()
    load_sounds()
    load_map()

  // setup game state
    game_controls = .News_Headlines
    headline_text[headline].callback()
    inventory.water_capacity = 13
    inventory.water_effect = 0.05
    inventory.pumpkin_yeild = 1
    inventory.pumpkin_speed = 0.05
    inventory.day = 1
    daytime = 0.4
    when DEBUG {
      inventory.pumpkins = 5000
    }

  for !rl.WindowShouldClose() {
    update_hacks()
    if game_controls == .Ending {
      draw_ending()
      continue
    }
    // UPDATE
      dist := (f32(max_cell.y - min_cell.y) + 1.25) / (2*math.tan_f32(math.RAD_PER_DEG*30))
      camera.position = 0.5 * { f32(min_cell.x+max_cell.x), 0, f32(min_cell.y+max_cell.y) } + (dist * V3{ 0, 7, 3 } / math.sqrt_f32(7*7 + 3*3))
      camera.target = 0.5 * { f32(min_cell.x+max_cell.x), 0, f32(min_cell.y+max_cell.y) } + (dist * V3{ 0, -0.25, 0 })
      rl.UpdateCamera(&camera)

      if game_controls == .Farming {
        daytime += 0.01667 * rl.GetFrameTime()
        when DEBUG {
          if rl.IsKeyDown(.SPACE) {
            daytime += 5 * rl.GetFrameTime()
          }
        }
        days : f32
        days, daytime = math.modf_f32(daytime)
        if days > 0 {
          inventory.day += int(days)
          rl.PlaySound(sounds.paper_delivery)
          inventory.papers = min(5, inventory.papers + int(days))
        }

        for cell in all_tiles {
          update_tile(cell, &all_tiles[cell])
        }

        for clicker in &inventory.auto_clicker {
          update_auto_clicker(&clicker)
        }
      }

      // raycast
        action := Action.None
        mouse_cell : CellPos
        if game_controls == .Farming {
          ray := rl.GetMouseRay(rl.GetMousePosition(), camera)
          hit := rl.GetRayCollisionQuad(ray, { f32(min_cell.x)-0.5, 0, f32(min_cell.y)-0.5 }, { f32(max_cell.x)+0.5, 0, f32(min_cell.y)-0.5 }, { f32(max_cell.x)+0.5, 0, f32(max_cell.y)+0.5 }, { f32(min_cell.x)-0.5, 0, f32(max_cell.y)+0.5 })
          if hit.hit {
            mouse_cell = V3_to_cell(hit.point)

            if mouse_cell in all_tiles {
              switch tile in &all_tiles[mouse_cell] {
                case TileDirt:
                  action = .Till
                  if rl.IsMouseButtonPressed(.LEFT) {
                    rl.PlaySound(sounds.till)
                    all_tiles[mouse_cell] = TileSoil{}
                  }

                case TileGrass:
                  action = .Till
                  if rl.IsMouseButtonPressed(.LEFT) {
                    rl.PlaySound(sounds.till)
                    all_tiles[mouse_cell] = TileSoil{}
                  }

                case TileSoil:
                  action = .Plant
                  if rl.IsMouseButtonPressed(.LEFT) {
                    rl.PlaySound(sounds.plant)
                    all_tiles[mouse_cell] = TilePumpkin{}
                  }

                case TilePumpkin:
                  if tile.growth >= 1.0 {
                    action = .Harvest
                    if rl.IsMouseButtonPressed(.LEFT) {
                      rl.PlaySound(sounds.harvest)
                      all_tiles[mouse_cell] = TileDirt{}
                      inventory.pumpkins += inventory.pumpkin_yeild
                    }
                  } else if inventory.water > 0 {
                    action = .WaterCrop
                    if rl.IsMouseButtonPressed(.LEFT) {
                      rl.PlaySound(sounds.water)
                      inventory.water -= 1
                      tile.growth += inventory.water_effect
                    }
                  }

                case TileWater:
                  action = .FillWater
                  if rl.IsMouseButtonPressed(.LEFT) {
                    rl.PlaySound(sounds.gather_water)
                    inventory.water = inventory.water_capacity
                  }

                case TilePortal:
                  action = .Harvest_Portal
                  if rl.IsMouseButtonPressed(.LEFT) {
                    rl.PlaySound(sounds.harvest)
                    game_controls = .Ending
                    game_time = play_time
                    open_file_select()
                  }
              }
            }
          }
        }

    // DRAW
    rl.BeginDrawing()
      color_lerp :: proc(a, b : rl.Color, t : f32) -> rl.Color {
        return rl.Color{
          u8((1-t)*f32(a.r) + t*f32(b.r)),
          u8((1-t)*f32(a.g) + t*f32(b.g)),
          u8((1-t)*f32(a.b) + t*f32(b.b)),
          u8((1-t)*f32(a.a) + t*f32(b.a)),
        }
      }
      bg_color := COLOR_BG_DAWN
      bg_interp := 4*daytime
      if bg_interp < 1 {
        bg_color = color_lerp(COLOR_BG_DAWN, COLOR_BG_MIDDAY, bg_interp)
      } else if bg_interp < 2 {
        bg_color = color_lerp(COLOR_BG_MIDDAY, COLOR_BG_DUSK, bg_interp-1)
      } else if bg_interp < 3 {
        bg_color = color_lerp(COLOR_BG_DUSK, COLOR_BG_MIDNIGHT, bg_interp-2)
      } else {
        bg_color = color_lerp(COLOR_BG_MIDNIGHT, COLOR_BG_DAWN, bg_interp-3)
      }
      portal_interp := 0.5*(1 + math.sin(math.TAU*60*daytime))
      portal_color = color_lerp(COLOR_TILE_PORTAL_FILL_A, COLOR_TILE_PORTAL_FILL_B, portal_interp)
      rl.ClearBackground(bg_color)
      rl.BeginMode3D(camera)
        update_lighting()
        // draw tiles
          for tile_cell in all_tiles {
            draw_tile(tile_cell, &all_tiles[tile_cell])
          }
        // draw auto clickers
          for auto_clicker in &inventory.auto_clicker {
            draw_auto_clicker(&auto_clicker)
          }
        // draw selector
          if action != .None {
            rl.DrawModel(models.selector, { f32(mouse_cell.x), 0, f32(mouse_cell.y) }, 1, COLOR_SELECT)
          }
      rl.EndMode3D()

      // draw mouse HUD
        if action == .WaterCrop || action == .FillWater {
          rl.DrawRing(rl.GetMousePosition() + { 5, 10 }, 15.0, 22.0, 180.0, 180.0-(f32(inventory.water)/f32(inventory.water_capacity) * 360.0), 16, COLOR_UI_WATER)
        }
        if action != .None {
          rl.DrawText(action_text[action], i32(rl.GetMousePosition().x)+7, i32(rl.GetMousePosition().y)-11, 20, rl.BLACK)
          rl.DrawText(action_text[action], i32(rl.GetMousePosition().x)+5, i32(rl.GetMousePosition().y)-13, 20, rl.WHITE)
        }

      rl.DrawRing({ 75, -20 }, 88, 102, -60, 80, 16, rl.BLACK)
      rl.DrawRing({ 75, -20 }, 90, 100, -56, 80, 16, rl.RAYWHITE)
      bar_interp := 2*daytime
      if bar_interp < 1 {
        rl.DrawRing({ 75, -20 }, 90, 98, -56, 80, 16, bg_color)
        rl.DrawRing({ 75, -20 }, 90, 98, -56, (bar_interp*136)-56, 16, COLOR_BG_DUSK)
      } else {
        rl.DrawRing({ 75, -20 }, 90, 98, -56, 80, 16, bg_color)
        rl.DrawRing({ 75, -20 }, 90, 98, -56, ((bar_interp-1)*136)-56, 16, COLOR_BG_DAWN)
      }

      if game_controls == .News_Headlines {
        rl.DrawRectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, rl.Color{ 0, 0, 0, 200 })
        draw_newspaper_headline()
      } else if game_controls == .News_Classifieds {
        rl.DrawRectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, rl.Color{ 0, 0, 0, 200 })
        draw_newspaper_classified()
      } else {
        if inventory.papers > 0 {
          hover := game_controls == .Farming && mouse_over(WINDOW_WIDTH-100-(12*inventory.papers), WINDOW_HEIGHT-70, 80+(12*inventory.papers), 90)
          for i in 0..<inventory.papers {
            x := WINDOW_WIDTH-100-i32(12*i)
            y := WINDOW_HEIGHT-70+i32(4*i)
            width := 80+i32(4*i)
            if hover && i == inventory.papers-1 {
              x -= 3
              y -= 15
            }
            rl.DrawRectangle(x-2, y-2, width+4, 94, COLOR_NEWS_TEXT)
            rl.DrawRectangle(x, y, width, 90, COLOR_NEWS_BG)
            rl.DrawRectangle(x+3, y+3, 25, 25, COLOR_NEWS_TEXT)
            rl.DrawRectangle(x+3+25+3, y+3, width-3-25-3-3, 6, COLOR_NEWS_TEXT)
            rl.DrawRectangle(x+3+25+3+5, y+3+6+2, width-3-25-3-3-5, 4, COLOR_NEWS_TEXT)
            rl.DrawRectangle(x+3+25+3, y+3+6+2+4+2, width-3-25-3-3, 4, COLOR_NEWS_TEXT)
            rl.DrawRectangle(x+3+25+3, y+3+6+2+4+2+4+2, width-3-25-3-3-10, 4, COLOR_NEWS_TEXT)
            rl.DrawRectangle(x+3, y+3+6+2+4+2+4+2+4+2+1, width-3-3, 8, COLOR_NEWS_TEXT)
            rl.DrawRectangle(x+3+15, y+3+6+2+4+2+4+2+4+2+1+8+2, width-3-3-15, 4, COLOR_NEWS_TEXT)
            rl.DrawRectangle(x+3, y+3+6+2+4+2+4+2+4+2+1+8+2+4+2, width-3-3, 4, COLOR_NEWS_TEXT)
            rl.DrawRectangle(x+3, y+3+6+2+4+2+4+2+4+2+1+8+2+4+2+4+2, width-3-3, 4, COLOR_NEWS_TEXT)
            rl.DrawRectangle(x+3, y+3+6+2+4+2+4+2+4+2+1+8+2+4+2+4+2+4+2, width-3-3, 4, COLOR_NEWS_TEXT)
            rl.DrawRectangle(x+3, y+3+6+2+4+2+4+2+4+2+1+8+2+4+2+4+2+4+2+4+2, width-3-3, 4, COLOR_NEWS_TEXT)
            rl.DrawRectangle(x+3, y+3+6+2+4+2+4+2+4+2+1+8+2+4+2+4+2+4+2+4+2+4+2, width-3-3, 4, COLOR_NEWS_TEXT)
            rl.DrawRectangle(x+3, y+3+6+2+4+2+4+2+4+2+1+8+2+4+2+4+2+4+2+4+2+4+2+4+2, width-3-3, 4, COLOR_NEWS_TEXT)
            rl.DrawRectangle(x+3, y+3+6+2+4+2+4+2+4+2+1+8+2+4+2+4+2+4+2+4+2+4+2+4+2+4+2, width-3-3, 4, COLOR_NEWS_TEXT)
          }
          if hover && rl.IsMouseButtonPressed(.LEFT) {
            inventory.papers -= 1
            rl.PlaySound(sounds.paper_open)
            if inventory.pumpkins >= 600 && story_progress == .Bad_Stuff {
              story_progress = .Portal
            }
            headline = rand.choice(headline_pool[story_progress])
            headline_text[headline].callback()
            game_controls = .News_Headlines
          }
        }
      }

      if inventory.pumpkins > 0 || story_progress != .Start {
        text := temp_fmt_cstring("%v", inventory.pumpkins)
        width := rl.MeasureText(text, 30)
        rl.DrawText(text, WINDOW_WIDTH - width - 10, 10, 30, rl.WHITE)
      }

      text := temp_fmt_cstring("Day %v", inventory.day)
      rl.DrawText(text, 14, 9, 50, rl.BLACK)
      rl.DrawText(text, 10, 5, 50, rl.RAYWHITE)

      when DEBUG {
        rl.DrawFPS(5, WINDOW_HEIGHT-20)
      }
    rl.EndDrawing()
  }
}

// SANDBOX /////////////////////////////////////////////////////////////////////////////////////////

  game_time : f32
  draw_ending :: proc() {
    rl.BeginDrawing()
      rl.ClearBackground(rl.BLACK)
      centered_text :: proc(cstr : cstring, y, size : i32, color : rl.Color) {
        width := rl.MeasureText(cstr, size)
        rl.DrawText(cstr, (WINDOW_WIDTH-width)/2, y, size, color)
      }
      sec_to_time :: proc(sec : f32) -> string {
        if sec > 60*60 {
          return fmt.tprintf("%v hrs %v mins", int(sec)/(60*60), (int(sec)%(60*60))/60)
        }
        if sec > 60 {
          return fmt.tprintf("%v mins %v secs", int(sec)/60, int(sec)%60)
        }
        return fmt.tprintf("%v secs", int(sec))
      }
      window_name :: proc(window : rl.W32_HWND) -> string {
        name : [512]c.wchar_t
        name_len := rl.W32_GetWindowTextW(window, &name[0], len(name))
        if name_len > 0 {
          u8_name : [512]u8
          for i in 0..<name_len {
            u8_name[i] = u8(name[i])
          }
          window_name := string(u8_name[:name_len])
          return strings.clone(window_name)
        }
        return ""
      }

      @static window_names : [7]string
      @static last_window : rl.W32_HWND
      active_window := rl.W32_GetActiveWindow()
      if active_window != last_window {
        last_window = active_window
        for _, i in window_names {
          if window_names[i] != "" {
            delete(window_names[i])
          }
          window_names[i] = ""
        }

        win_info : rl.W32_WINDOWINFO
        win_info.cbSize = size_of(rl.W32_WINDOWINFO)

        next_wind := active_window
        if next_wind != nil {
          window_names[0] = window_name(next_wind)
          all_windows:
          for i in 1..<len(window_names) {
            for {
              next_wind = rl.W32_GetWindow(next_wind, 2)
              if next_wind == nil {
                break all_windows
              }
              if !rl.W32_GetWindowInfo(next_wind, &win_info) {
                break all_windows
              }
              if win_info.dwStyle & 0x10000000 == 0x10000000 {
                window_names[i] = window_name(next_wind)
                break
              }
            }
          }
        }
      }

      centered_text("YOU HAVE BEEN HARVESTED", 10, 80, rl.RAYWHITE)
      monitor := rl.GetCurrentMonitor()
      monitor_width := rl.GetMonitorPhysicalWidth(monitor)
      monitor_height := rl.GetMonitorPhysicalHeight(monitor)
      monitor_diag := math.sqrt(f32(monitor_width*monitor_width) + f32(monitor_height*monitor_height)) / 10
      cstr : cstring
      cstr = temp_fmt_cstring("Play Time: %v\n"+
                              "Pumpkins Harvested: %v\n"+
                              "Monitor Count: %v\n"+
                              "Monitor Size (cm): %v\n"+
                              "File Included: %v\n"+
                              "Open Windows:\n"+
                              "  %v\n  %v\n  %v\n  %v\n  %v\n  %v\n  %v",
                              sec_to_time(game_time), 0, rl.GetMonitorCount(), monitor_diag, harvest_file, window_names[0], window_names[1], window_names[2], window_names[3], window_names[4], window_names[5], window_names[6])
      rl.DrawText(cstr, 50, 100, 20, rl.GRAY)

      pumpkoins := 0.0001 * play_time
      cstr = temp_fmt_cstring("Pumpkins Spent: %v\n"+
                              "Pumpkins Watered: %v\n"+
                              "Monitor Resolution: %vx%v\n"+
                              "Pumpkoins crypto-mined: %v\n"+
                              "\n"+
                              "\n",
                              0, 0, rl.GetMonitorWidth(monitor), rl.GetMonitorHeight(monitor), pumpkoins)
      rl.DrawText(cstr, (WINDOW_WIDTH/2)+25, 100, 20, rl.GRAY)
      centered_text("MADE IN 48 HOURS", WINDOW_HEIGHT - 200, 40, rl.GRAY)
      centered_text("FOR LUDUM DARE 52", WINDOW_HEIGHT - 160, 40, rl.GRAY)
      centered_text("BY, HITCHH1k3R", WINDOW_HEIGHT - 120, 40, rl.GRAY)
      centered_text("THANKS FOR PLAYING", WINDOW_HEIGHT - 70, 60, rl.RAYWHITE)

      when DEBUG {
        rl.DrawFPS(5, WINDOW_HEIGHT-20)
      }
    rl.EndDrawing()
  }

  reveal_around :: proc(cell_pos : CellPos) {
    OFFSETS :: []CellPos{
      { -1, -1 },
      {  0, -1 },
      {  1, -1 },
      { -1,  0 },
      {  1,  0 },
      { -1,  1 },
      {  0,  1 },
      {  1,  1 },
    }
    for offset in OFFSETS {
      target_cell := cell_pos + offset
      if target_cell not_in all_tiles {
        if rand.float64() > 0.9 {
          all_tiles[target_cell] = TileWater{}
        } else {
          all_tiles[target_cell] = TileGrass{}
        }
        min_cell.x = min(min_cell.x, target_cell.x)
        min_cell.y = min(min_cell.y, target_cell.y)
        max_cell.x = max(max_cell.x, target_cell.x)
        max_cell.y = max(max_cell.y, target_cell.y)
      }
    }
  }

  V3_to_cell :: proc(pos : V3) -> CellPos {
    return CellPos{ int(math.round(pos.x)), int(math.round(pos.z)) }
  }

  cell_to_V3 :: proc(cell_pos : CellPos) -> V3 {
    return V3{ f32(cell_pos.x), 0, f32(cell_pos.y) }
  }

  temp_fmt_cstring :: proc(format : string, args : ..any) -> cstring {
    @static text_buff : [4096]u8
    str := fmt.bprintf(buf = text_buff[:len(text_buff)-1], fmt = format, args = args)
    text_buff[len(str)] = 0
    return strings.unsafe_string_to_cstring(str)
  }

  mouse_over :: proc(#any_int x, y, width, height : int) -> bool {
    mx := int(rl.GetMousePosition().x)
    my := int(rl.GetMousePosition().y)
    return mx >= x && mx <= x+width && my >= y && my <= y+height
  }

  draw_newspaper_headline :: proc() {
    if DEBUG && rl.IsMouseButtonPressed(.RIGHT) {
      headline = Headline((int(headline)+1) % len(Headline))
    }

    NEWS_SIZE_X :: 500
    NEWS_SIZE_Y :: 650
    NEWS_MIN_X :: (WINDOW_WIDTH  - NEWS_SIZE_X)/2
    NEWS_MIN_Y :: (WINDOW_HEIGHT - NEWS_SIZE_Y)/2
    NEWS_MAX_X :: (WINDOW_WIDTH  + NEWS_SIZE_X)/2
    NEWS_MAX_Y :: (WINDOW_HEIGHT + NEWS_SIZE_Y)/2

    rl.DrawRectangle(NEWS_MIN_X-3, NEWS_MIN_Y-3, NEWS_SIZE_X+3+3, NEWS_SIZE_Y+3+3, COLOR_NEWS_TEXT)
    rl.DrawRectangle(NEWS_MIN_X, NEWS_MIN_Y, NEWS_SIZE_X, NEWS_SIZE_Y, COLOR_NEWS_BG)

    rl.DrawText("THE PUMPKIN PRESS", NEWS_MIN_X+25, NEWS_MIN_Y+10, 40, COLOR_NEWS_TEXT)

    rl.DrawRectangle(NEWS_MIN_X+10, NEWS_MIN_Y+60, (NEWS_SIZE_X-20)/2, (NEWS_SIZE_X-20)/2, COLOR_NEWS_TEXT)

    rl.DrawRectangle(NEWS_MIN_X+(NEWS_SIZE_X/2)+10, NEWS_MIN_Y+65, NEWS_SIZE_X/2-20, 20, COLOR_NEWS_TEXT)

    news_lines :: proc(x, y, width, height, indent, end_gap, size, spacing : i32, color : rl.Color) {
      y_offset := i32(0)
      rl.DrawRectangle(x+indent, y+y_offset, width-indent, size, color)
      for y_offset = spacing; y_offset <= height-spacing; y_offset += spacing {
        rl.DrawRectangle(x, y+y_offset, width, size, color)
      }
      rl.DrawRectangle(x, y+y_offset, width-end_gap, size, color)
    }

    news_lines(NEWS_MIN_X+(NEWS_SIZE_X/2)+10, NEWS_MIN_Y+95, NEWS_SIZE_X/2-20, 5*15, 40, 60, 5, 15, COLOR_NEWS_TEXT)
    news_lines(NEWS_MIN_X+(NEWS_SIZE_X/2)+10, NEWS_MIN_Y+185, NEWS_SIZE_X/2-20, 7*15, 40, 100, 5, 15, COLOR_NEWS_TEXT)

    rl.DrawText(headline_text[headline].title, NEWS_MIN_X+20, NEWS_MIN_Y+320, 20, COLOR_NEWS_TEXT)

    rl.DrawText(headline_text[headline].body, NEWS_MIN_X+40, NEWS_MIN_Y+380, 10, COLOR_NEWS_TEXT)
    news_lines(NEWS_MIN_X+10, NEWS_MIN_Y+395, NEWS_SIZE_X-20, NEWS_SIZE_Y-395-30, 0, 180, 4, 10, COLOR_NEWS_TEXT)

    if (mouse_over(NEWS_MIN_X+NEWS_SIZE_X-42, NEWS_MIN_Y+NEWS_SIZE_Y-42, 42, 42) || !mouse_over(NEWS_MIN_X, NEWS_MIN_Y, NEWS_SIZE_X, NEWS_SIZE_Y)) {
      rl.DrawRectangle(NEWS_MIN_X+NEWS_SIZE_X-42, NEWS_MIN_Y+NEWS_SIZE_Y-42, 42, 42, COLOR_NEWS_TEXT)
      rl.DrawTriangle({ NEWS_MIN_X+NEWS_SIZE_X-39, NEWS_MIN_Y+NEWS_SIZE_Y-39 },
                      { NEWS_MIN_X+NEWS_SIZE_X-39, NEWS_MIN_Y+NEWS_SIZE_Y },
                      { NEWS_MIN_X+NEWS_SIZE_X, NEWS_MIN_Y+NEWS_SIZE_Y-39 }, COLOR_NEWS_BG)

      if rl.IsMouseButtonPressed(.LEFT) {
        rl.PlaySound(sounds.paper_close)
        game_controls = .News_Classifieds
      }
    } else {
      rl.DrawRectangle(NEWS_MIN_X+NEWS_SIZE_X-30, NEWS_MIN_Y+NEWS_SIZE_Y-30, 30, 30, COLOR_NEWS_TEXT)
      rl.DrawTriangle({ NEWS_MIN_X+NEWS_SIZE_X-27, NEWS_MIN_Y+NEWS_SIZE_Y-27 },
                      { NEWS_MIN_X+NEWS_SIZE_X-27, NEWS_MIN_Y+NEWS_SIZE_Y },
                      { NEWS_MIN_X+NEWS_SIZE_X, NEWS_MIN_Y+NEWS_SIZE_Y-27 }, COLOR_NEWS_BG)
    }
  }

  draw_newspaper_classified :: proc() {
    NEWS_SIZE_X :: 500
    NEWS_SIZE_Y :: 650
    NEWS_MIN_X :: (WINDOW_WIDTH  - NEWS_SIZE_X)/2
    NEWS_MIN_Y :: (WINDOW_HEIGHT - NEWS_SIZE_Y)/2
    NEWS_MAX_X :: (WINDOW_WIDTH  + NEWS_SIZE_X)/2
    NEWS_MAX_Y :: (WINDOW_HEIGHT + NEWS_SIZE_Y)/2

    rl.DrawRectangle(NEWS_MIN_X-3, NEWS_MIN_Y-3, NEWS_SIZE_X+3+3, NEWS_SIZE_Y+3+3, COLOR_NEWS_TEXT)
    rl.DrawRectangle(NEWS_MIN_X, NEWS_MIN_Y, NEWS_SIZE_X, NEWS_SIZE_Y, COLOR_NEWS_BG)

    rl.DrawText("CLASSIFIEDS", NEWS_MIN_X+100, NEWS_MIN_Y+10, 40, COLOR_NEWS_TEXT)

    im_ad :: proc(title, body : cstring, cost : int, x, y, width, height : i32) -> bool {
      hover := mouse_over(x, y, width, height)
      x, y := x, y
      pop := i32(0)

      rl.DrawRectangle(x-2, y-2, width+2+2, height+2+2, COLOR_NEWS_TEXT)
      if hover {
        x -= 1
        y -= 1
        pop = 1
      }
      rl.DrawRectangle(x, y, width, height, COLOR_NEWS_BG)

      rl.DrawText(title, x+5, y+5, 20, COLOR_NEWS_TEXT)
      rl.DrawText(body, x+10, y+30, 10, COLOR_NEWS_TEXT)

      if inventory.pumpkins < cost {
        x += pop
        y += pop
        pop = 0
        hover = false
      }

      text : cstring
      if cost == 0 {
        text = "Free"
      } else if cost == 1 {
        text = "Cost 1 Pumpkin"
      } else {
        text = temp_fmt_cstring("Cost %v Pumpkins", cost)
      }
      text_width := rl.MeasureText(text, 10)

      rl.DrawRectangle(x+width-text_width-10+pop, y+height-20+pop, text_width+8, 18, COLOR_NEWS_TEXT)
      rl.DrawRectangle(x+width-text_width-8, y+height-18, text_width+4, 14, COLOR_NEWS_BG)
      rl.DrawText(text, x+width-text_width-6, y+height-16, 10, COLOR_NEWS_TEXT)

      return hover && rl.IsMouseButtonPressed(.LEFT)
    }

    AD_LEFT :: NEWS_MIN_X+10
    AD_RIGHT :: NEWS_MIN_X+20+(NEWS_SIZE_X-30)/2
    AD_WIDTH :: (NEWS_SIZE_X-30)/2
    AD_HEIGHT :: 100

    idx := 0
    for row in i32(0)..<5 {
      if classifieds[idx].available {
        if im_ad(classifieds[idx].title, classifieds[idx].body, classifieds[idx].cost, AD_LEFT, NEWS_MIN_Y+10+50+(row*(AD_HEIGHT+10)), AD_WIDTH, AD_HEIGHT) {
          rl.PlaySound(sounds.paper_order)
          inventory.pumpkins -= classifieds[idx].cost
          classifieds[idx].available = false
          classifieds[idx].callback(classifieds[idx].user_data)
        }
      }
      idx += 1

      if classifieds[idx].available {
        if im_ad(classifieds[idx].title, classifieds[idx].body, classifieds[idx].cost, AD_RIGHT, NEWS_MIN_Y+10+50+(row*(AD_HEIGHT+10)), AD_WIDTH, AD_HEIGHT) {
          rl.PlaySound(sounds.paper_order)
          inventory.pumpkins -= classifieds[idx].cost
          classifieds[idx].available = false
          classifieds[idx].callback(classifieds[idx].user_data)
        }
      }
      idx += 1
    }

    if headline != .Intro || !classifieds[0].available {
      if (mouse_over(NEWS_MIN_X+NEWS_SIZE_X-42, NEWS_MIN_Y+NEWS_SIZE_Y-42, 42, 42) || !mouse_over(NEWS_MIN_X, NEWS_MIN_Y, NEWS_SIZE_X, NEWS_SIZE_Y)) {
        rl.DrawRectangle(NEWS_MIN_X+NEWS_SIZE_X-42, NEWS_MIN_Y+NEWS_SIZE_Y-42, 42, 42, COLOR_NEWS_TEXT)
        rl.DrawTriangle({ NEWS_MIN_X+NEWS_SIZE_X-39, NEWS_MIN_Y+NEWS_SIZE_Y-39 },
                        { NEWS_MIN_X+NEWS_SIZE_X-39, NEWS_MIN_Y+NEWS_SIZE_Y },
                        { NEWS_MIN_X+NEWS_SIZE_X, NEWS_MIN_Y+NEWS_SIZE_Y-39 }, COLOR_NEWS_BG)

        if rl.IsMouseButtonPressed(.LEFT) {
          rl.PlaySound(sounds.paper_close)
          game_controls = .Farming
        }
      } else {
        rl.DrawRectangle(NEWS_MIN_X+NEWS_SIZE_X-30, NEWS_MIN_Y+NEWS_SIZE_Y-30, 30, 30, COLOR_NEWS_TEXT)
        rl.DrawTriangle({ NEWS_MIN_X+NEWS_SIZE_X-27, NEWS_MIN_Y+NEWS_SIZE_Y-27 },
                        { NEWS_MIN_X+NEWS_SIZE_X-27, NEWS_MIN_Y+NEWS_SIZE_Y },
                        { NEWS_MIN_X+NEWS_SIZE_X, NEWS_MIN_Y+NEWS_SIZE_Y-27 }, COLOR_NEWS_BG)
      }
    }
  }

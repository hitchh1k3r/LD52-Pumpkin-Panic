package main

import "core:strings"
import "core:c"
import "core:fmt"
import rl "raylib"

/*
@(private="file")
last_window : rl.W32_HWND
@(private="file")
last_volume : u32
*/

harvest_file : string

open_file_select :: proc() {
  filter_buffer := [?]c.wchar_t {
    '*','.','t','x','t',0,'*','.','t','x','t',0,
  }
  file_name : [2048]c.wchar_t
  open_dialogue : rl.W32_OPENFILENAMEW
  open_dialogue.lStructSize = size_of(rl.W32_OPENFILENAMEW)
  open_dialogue.hwndOwner = rl.W32_HWND(rl.GetWindowHandle())
  open_dialogue.lpstrFile = &file_name[0]
  open_dialogue.nMaxFile = len(file_name)
  open_dialogue.lpstrFilter = &filter_buffer[0]
  open_dialogue.nFilterIndex  = 1
  if rl.W32_GetOpenFileNameW(&open_dialogue) {
    u8_file : [2048]u8
    len := 0
    for c, i in file_name {
      if c == 0 {
        break
      }
      len += 1
      u8_file[i] = u8(c)
    }
    harvest_file = strings.clone(string(u8_file[:len]))
  } else {
    harvest_file = "-none-"
  }
}

play_time := f32(0)

update_hacks :: proc() {
  // WINDOW DETECTION HACKS
  window := rl.W32_GetActiveWindow()
  if window == rl.GetWindowHandle() {
    play_time += rl.GetFrameTime()
  }
  /*
  if window != last_window {
    last_window = window
    name : [512]c.wchar_t
    name_len := rl.W32_GetWindowTextW(window, &name[0], len(name))
    if name_len > 0 {
      u8_name : [512]u8
      for i in 0..<name_len {
        u8_name[i] = u8(name[i])
      }
      window_name := string(u8_name[:name_len])
      if strings.has_suffix(window_name, " - Discord") {
        server_idx := strings.last_index_byte(window_name, '|')
        if server_idx > 0 {
          server := window_name[server_idx+2:len(window_name)-len(" - Discord")]
          fmt.println("DISCORD SERVER:", server)
        } else {
          fmt.println("DISCORD UNKNOWN:", window_name)
        }
      } else if strings.has_suffix(window_name, " - Google Chrome") {
        fmt.println("CHROME WINDOW:", window_name[:len(window_name)-len(" - Google Chrome")])
      } else {
        fmt.println("UNKNOWN WINDOW:", window_name)
      }
    }
  }
  */
}

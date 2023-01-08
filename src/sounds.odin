package main

import rl "raylib"

sounds : struct {
  auto_till : rl.Sound,
  paper_close : rl.Sound,
  paper_open : rl.Sound,
  paper_delivery : rl.Sound,
  paper_order : rl.Sound,
  plant : rl.Sound,
  till : rl.Sound,
  harvest : rl.Sound,
  water : rl.Sound,
  gather_water : rl.Sound,
}

load_sounds :: proc() {
  sounds.auto_till = rl.LoadSound("res/AutoTill.wav")
  sounds.paper_close = rl.LoadSound("res/ClosePaper.wav")
  sounds.paper_open = rl.LoadSound("res/OpenPaper.wav")
  sounds.paper_delivery = rl.LoadSound("res/PaperDeliver.wav")
  sounds.paper_order = rl.LoadSound("res/Buy.wav")
  sounds.plant = rl.LoadSound("res/Plant.wav")
  sounds.till = rl.LoadSound("res/Till.wav")
  sounds.harvest = rl.LoadSound("res/Harvest.wav")
  sounds.water = rl.LoadSound("res/AutoWater.wav")
  sounds.gather_water = rl.LoadSound("res/GaterWater.wav")
}

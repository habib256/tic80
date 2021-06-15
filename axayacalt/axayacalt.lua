-- title:  Axayacalt Tomb
-- author: VERHILLE Arnaud - gist974@gmail.com
-- desc: Axayacalt's Tomb Port for TIC-80
-- graphics: 24x24 tiles & sprites by Petitjean & Shurder
-- script: Lua
--
-- player.state : 0->wait // 1->walk // 2->swim
--    // 3->Aim // 4->Jump // 5->Inventory // 6->Dead
player = {
  x,
  y,
  dir,
  state = 0,
  life = 10,
  O2 = 300,
  greenKey = 0,
  blueKey = 0,
  redKey = 0,
  yellowKey = 0
}
monsters = nil -- This a Lua Linked List
doors = nil -- This a Lua Linked List
chests = nil -- This a Lua Linked List
camera = {x = 0, y = 0}
input = -1
game = {state = 5, init = -1, time = 0}

-- --------------------
-- FONCTION PRINCIPALE
-- --------------------
function TIC()
  game.time = game.time + 1
  if game.state == -1 then flyBy() end -- flyBy Mode
  if game.state == 0 then playMap(72, 08, 81, 13) end -- Attract Mode
  if game.state == 1 then playMap(0, 0, 66, 67) end -- Original Map
  if game.state == 2 then playMap(66, 16, 87, 33) end -- Arena Map
  if game.state == 3 then playMap(64, 33, 89, 50) end -- The Cave
  if game.state == 4 then playMap(64, 51, 88, 66) end -- The Keys
   if game.state == 5 then playMap(89, 01, 120, 17) end -- The Keys 2
end

function playMap(x1, y1, x2, y2)
  if game.init == -1 then
    initFromMap(x1, y1, x2, y2)
    game.init = 1
  end
  if player.state == 5 then -- INVENTORY MODE
    if btnp(6) then -- Triangle to Quit INVENTORY MODE
      input = 6
      player.state = 0
    end
  else -- PLAYING MODE
    updateMonster()
    updatePlayer()
    updateCamera()
    checkInteraction()
  end

  cls(0)
  drawMap(camera.x, camera.y)
  drawMonsters()
  drawHUD()
  drawPlayer()
end

-- INIT FROM MAP
-- --------------------
function initFromMap(x1, y1, x2, y2)
  for i = x1, x2 do
    for j = y1, y2 do
      val = peek(0x08000 + i + j * 240)
      if val == 49 then -- Some monsters to add from the map
        monsters = {
          next = monsters,
          x = i,
          y = j,
          dir = 0
        }
      end
      if val == 64 then -- Player starting position
        player.x = i
        player.y = j
        player.dir = -1
      end
    end
  end
end

-- FLYBY
-- -------------------------
function flyBy()
  cls(0)
  if btn(0) then camera.y = camera.y - 1 end
  if btn(1) then camera.y = camera.y + 1 end
  if camera.y < 0 then camera.y = 0 end
  if camera.y > 135 then camera.y = 135 end
  if btn(2) then camera.x = camera.x - 1 end
  if btn(3) then camera.x = camera.x + 1 end
  if camera.x < 0 then camera.x = 0 end
  if camera.x > 239 then camera.x = 239 end
  drawMap(camera.x, camera.y)
  -- show coordinates
  c = string.format('(%03i,%03i)', toInt(camera.x),
                    toInt(camera.y))
  rect(0, 0, 52, 8, 0)
  print(c, 0, 0, 12, 1)
end

function checkInteraction()
  -- collide with Monsters
  local m = monsters
  while m do
    if m.x == player.x then
      if m.y == player.y then
        player.life = player.life - 1
      end
    end
    m = m.next
  end
  -- IF GREEN KEY
  if mget(player.x, player.y) == 239 then
    player.greenKey = 1
  end
  -- IF BLUE KEY
  if mget(player.x, player.y) == 255 then
    player.blueKey = 1
  end
  -- IF RED KEY
  if mget(player.x, player.y) == 223 then
    player.redKey = 1
  end
  -- IF YELLOW KEY
  if mget(player.x, player.y) == 207 then
    player.yellowKey = 1
  end
end

function updateCamera()
  if game.state == 0 then -- Attract Mode Fixed Camera
    camera.x = 72
    camera.y = 8
  else -- Camera Follow the player
    camera.x = player.x - 5
    camera.y = player.y - 2
  end
end

-- ----------------------------------
-- PLAYER UPDATE with INPUTS
-- ---------------------------------
function updatePlayer()

  if btnp(6) then -- Triangle
    input = 6
    player.state = 5 -- Inventory
  end

  -- Important!! player speed !
if game.time % 15 == 0 then

  player.state = 0

if btn(7) then -- Shoot Button Carre
    input = 7
    player.state = 3 -- Aiming
    move = 0
end

if btn(5) then
  input = 5
  player.state = 3 -- Aiming Cercle
end

if btn(4) then
  input = 4
  player.state = 4 -- Jump Croix
end

  -- Avance vers le haut
  if btn(0) then
    input = 0
    player.dir = 0
    if playerCanMove(player.x, player.y - 1) == 1 then
      player.y = player.y - 1
      player.state = 1
    end
  end
  -- Avance vers le bas
  if btn(1) then
    input = 1
    player.dir = 2
    if playerCanMove(player.x, player.y + 1) == 1 then
      player.y = player.y + 1
      player.state = 1
    end
  end
  -- Avance vers la gauche
  if btn(2) then
    input = 2
    player.dir = 3
    if playerCanMove(player.x - 1, player.y) == 1 then
      player.x = player.x - 1
      player.state = 1
    end
  end
  -- Avance vers la droite
  if btn(3) then
    input = 4
    player.dir = 1
    if playerCanMove(player.x + 1, player.y) == 1 then
      player.x = player.x + 1
      player.state = 1
    end
  end



  -- if WATER you have to SWIM
  if isWater(player.x, player.y) == 1 then
    player.state = 2 -- SWIM
    if player.O2 == 0 then
      player.life = player.life - 1
    else
      player.O2 = player.O2 - 1
    end
  else
    player.O2 = 300
  end

  -- if PEAK and not jumping -> Dead
  if mget(player.x, player.y + 1) == 7 then
    player.life = 0
  end

end -- Wait

end

function playerCanMove(x, y)
  val = mget(x, y)
  if val == 1 or val == 2 or val == 3 or val == 39 or
    val == 10 or val == 11 or val == 12 or val == 23 or
    val == 15 or val == 17 or val == 20 or val == 21 or
    val == 22 or val == 37 or val == 18 then return -1 end

  if val == 34 then -- Green Door
    if player.greenKey == 0 then
      return -1
    else
      return 1
    end
  end

  if val == 35 then -- Blue Door      
    if player.blueKey == 0 then
      return -1
    else
      return 1
    end
  end

  if val == 33 then -- Red Door
    if player.redKey == 0 then
      return -1
    else
      return 1
    end
  end

  if val == 36 then -- Yellow Door
    if player.yellowKey == 0 then
      return -1
    else
      return 1
    end

  end

  if player.state == 3 then -- AIMING
    return 0
  else
    return 1
  end
end

function isWater(x, y)
  val = mget(x, y)
  if val == 14 then -- Water tiles
    return 1
  else
    return -1
  end
end

-- ----------------------
-- MONSTERS UPDATE
-- ----------------------
function updateMonster()

  if game.time % 20 == 0 then

    local m = monsters
    while m do
      if m.dir == 0 then
        if monsterCanMove(m.x + 1, m.y) == 1 then
          m.x = m.x + 1
          m.dir = 0
        else
          m.dir = toInt(math.random(0, 3))
        end
      end
      if m.dir == 1 then
        if monsterCanMove(m.x, m.y - 1) == 1 then
          m.y = m.y - 1
          m.dir = 1
        else
          m.dir = toInt(math.random(0, 3))
        end
      end
      if m.dir == 2 then
        if monsterCanMove(m.x - 1, m.y) == 1 then
          m.x = m.x - 1
          m.dir = 2
        else
          m.dir = toInt(math.random(0, 3))
        end
      end
      if m.dir == 3 then
        if monsterCanMove(m.x, m.y + 1) == 1 then
          m.y = m.y + 1
          m.dir = 3
        else
          m.dir = toInt(math.random(0, 3))
        end
      end
      m = m.next
    end
  end

end

function monsterCanMove(x, y)
  val = mget(x, y)
  if val == 1 or val == 2 or val == 3 or val == 8 or val ==
    9 or val == 39 or val == 10 or val == 11 or val ==
    12 or val == 23 or val == 15 or val == 17 or val ==
    20 or val == 21 or val == 22 or val == 37 or val ==
    18 or val == 14 then
    return 0
  else
    return 1
  end
end

-- -----------------------------
-- DRAW PLAYER
-- -----------------------------
function drawPlayer()

  if player.state == 0 then
    -- En Face
    spr(256, (player.x - camera.x) * 24,
        (player.y - camera.y) * 24, 15, 1, 0, 0, 3, 3)
    spr(271, (player.x - camera.x) * 24 + 8,
        (player.y - camera.y) * 24 + 4, 15, 1, 0, 0, 1,
        1)
  end

  if player.state == 1 then -- Walk 
    -- Vers le haut
    if player.dir == -1 then
      spr(304 + game.time % 30 // 15 * 3,
          (player.x - camera.x) * 24,
          (player.y - camera.y) * 24, 15, 1, 0, 0, 3, 3)
    end
    -- Vers le haut
    if player.dir == 0 then
      spr(304 + game.time % 30 // 15 * 3,
          (player.x - camera.x) * 24,
          (player.y - camera.y) * 24, 15, 1, 0, 0, 3, 3)
    end
    -- vers la droite	
    if player.dir == 1 then
      spr(259 + game.time % 30 // 15 * 3,
          (player.x - camera.x) * 24,
          (player.y - camera.y) * 24, 15, 1, 0, 0, 3, 3)
    end
    -- Vers le bas 
    if player.dir == 2 then
      spr(304 + game.time % 30 // 15 * 3,
          (player.x - camera.x) * 24,
          (player.y - camera.y) * 24, 15, 1, 0, 0, 3, 3)
      spr(271, (player.x - camera.x) * 24 + 8,
          (player.y - camera.y) * 24 + 4, 15, 1, 0, 0,
          1, 1)
    end
    -- Ver la gauche
    if player.dir == 3 then
      spr(259 + game.time % 30 // 15 * 3,
          (player.x - camera.x) * 24,
          (player.y - camera.y) * 24, 15, 1, 1, 0, 3, 3)
    end
  end

  -- Swimming mode
  if player.state == 2 then -- Swimming mode
    if player.dir == -1 then
      spr(265 + game.time % 30 // 15 * 3,
          (player.x - camera.x) * 24,
          (player.y - camera.y) * 24, 15, 1, 0, 0, 3, 3)
      spr(271, (player.x - camera.x) * 24 + 9,
          (player.y - camera.y) * 24 + 3 + game.time %
            30 // 15, 15, 1, 0, 0, 1, 1)
    end
    if player.dir >= 0 then
      spr(265 + game.time % 30 // 15 * 3,
          (player.x - camera.x) * 24,
          (player.y - camera.y) * 24, 15, 1, 0,
          player.dir, 3, 3)
    end
  end

  -- Aiming mode
  if player.state == 3 then
    if player.dir == -1 then
      spr(256, (player.x - camera.x) * 24,
          (player.y - camera.y) * 24, 15, 1, 0, 0, 3, 3)
      spr(271, (player.x - camera.x) * 24 + 8,
          (player.y - camera.y) * 24 + 4, 15, 1, 0, 0,
          1, 1)
    end
    if player.dir == 0 then
      spr(313, (player.x - camera.x) * 24,
          (player.y - camera.y) * 24, 15, 1, 0, 0, 3, 3)
    end
    if player.dir == 1 then
      spr(310, (player.x - camera.x) * 24,
          (player.y - camera.y) * 24, 15, 1, 0, 0, 3, 3)
    end
    if player.dir == 2 then
      spr(316, (player.x - camera.x) * 24,
          (player.y - camera.y) * 24, 15, 1, 0, 0, 3, 3)
    end
    if player.dir == 3 then
      spr(310, (player.x - camera.x) * 24,
          (player.y - camera.y) * 24, 15, 1, 1, 0, 3, 3)
    end
  end

  if player.state == 4  then -- JUMP
    -- En Face
    if player.dir == 0 then
      spr(412, (player.x - camera.x) * 24, (player.y - camera.y) * 24-2, 15, 1,
      0, 0, 3, 3)
    end
    if player.dir == 1 then
      spr(364, (player.x - camera.x) * 24, (player.y - camera.y) * 24-2, 15, 1,
      0, 0, 3, 3)
    end
    if player.dir == 2 then
      spr(412, (player.x - camera.x) * 24, (player.y - camera.y) * 24-2, 15, 1,
      0, 0, 3, 3)
    end
    if player.dir == 3 then
      spr(364, (player.x - camera.x) * 24, (player.y - camera.y) * 24-2, 15, 1,
      1, 0, 3, 3)
    end
  end
  

  if player.state == 5 then -- INVENTORY WINDOW DRAW
    -- En Face
    spr(256, 3 * 24, (player.y - camera.y) * 24, 15, 1,
        0, 0, 3, 3)
    spr(271, 3 * 24 + 8, (player.y - camera.y) * 24 + 4,
        15, 1, 0, 0, 1, 1)
  end
end

-- -----------------------------
-- DRAW MONSTERS
-- -----------------------------
-- print(game.time%30//15,75,2*24,10,2,2)

function drawMonsters()
  local m = monsters
  while m do
    if m.dir == -1 then
      spr(352 + game.time % 30 // 15 * 3,
          (m.x - camera.x) * 24, (m.y - camera.y) * 24,
          15, 1, m.dir, 0, 3, 3)
    end
    if m.dir == 0 then -- Right
      spr(352 + game.time % 30 // 15 * 3,
          (m.x - camera.x) * 24, (m.y - camera.y) * 24,
          15, 1, m.dir, 0, 3, 3)
    end
    if m.dir == 1 then -- UP
      spr(361, (m.x - camera.x) * 24,
          (m.y - camera.y) * 24, 15, 1, 0, 0, 3, 3)
    end
    if m.dir == 2 then -- Left
      spr(352 + game.time % 30 // 15 * 3,
          (m.x - camera.x) * 24, (m.y - camera.y) * 24,
          15, 1, 1, 0, 3, 3)
    end
    if m.dir == 3 then -- Down
      spr(358, (m.x - camera.x) * 24,
          (m.y - camera.y) * 24, 15, 1, 0, 0, 3, 3)
    end
    m = m.next
  end
end

-- ----------------
-- DRAW HUD 
-- ----------------
function drawHUD()
  if game.state == 0 then -- Attract Mode
    print("Axayacalt's", 75, 1 * 24 + 6, 10, 2, 2)
    print("Tomb", 125, 2 * 24, 10, 2, 2)
    print("A TIC-80 game by gist974", 50, 5 * 24 + 2, 1,
          1, 1)
    print("Graphics: Petitjean & Shurder", 35,
          5 * 24 + 10, 1, 1, 1)
  else -- INGAME HUD
    if player.state == 5 then -- Show HUD 5 only in Inventory
      rect(2 * 24, 1 * 24, 5 * 24, 3 * 24, 8) -- Main Rect
      rectb(2 * 24, 1 * 24, 5 * 24, 3 * 24, 12)

      rect(2 * 24 + 12, 1 * 24 + 8, 19, 7, 1) -- HUD Life
      spr(26, 2 * 24 + 6, 1 * 24 + 8, 15, 1, 0, 0, 1, 1)
      print(player.life, 2 * 24 + 16, 1 * 24 + 9, 12, 1,
            1)

      rect(3 * 24 + 18, 1 * 24 + 8, 24, 7, 1) -- HUD O2
      spr(25, 3 * 24 + 12, 1 * 24 + 8, 15, 1, 0, 0, 1, 1)
      print(player.O2, 3 * 24 + 22, 1 * 24 + 9, 12, 1, 1)

      print("Keys", 5 * 24, 1 * 24 + 9, 12, 1, 1)
      if player.greenKey == 1 then
        spr(239, 5 * 24, 1 * 24 + 18, 12, 1, 1)
      end
      if player.blueKey == 1 then
        spr(255, 5 * 24 + 10, 1 * 24 + 18, 12, 1, 1)
      end
      if player.redKey == 1 then
        spr(223, 5 * 24 + 20, 1 * 24 + 18, 12, 1, 1)
      end
      if player.yellowKey == 1 then
        spr(207, 5 * 24 + 30, 1 * 24 + 18, 12, 1, 1)
      end

      print("Gold", 5 * 24, 2 * 24 + 14, 12, 1, 1)
      spr(126, 5 * 24, 3 * 24, 12, 1, 1, 0, 2, 2)
    else
      -- HUD Life
      rect(211, 3, 19, 7, 1)
      spr(26, 208, 2, 15, 1, 0, 0, 1, 1)
      print(player.life, 218, 4, 12, 1, 1)

      if player.state == 2 then -- Show HUD O2 only if swimming
        rect(211, 13, 25, 7, 1)
        spr(25, 208, 12, 15, 1, 0, 0, 1, 1)
        print(player.O2, 218, 14, 12, 1, 1)
      end
    end
  end
end

-- ------------------------------
-- DRAW MAP
-- -----------------------------
function drawMap(x, y) -- draw 64x64 Sprite Map
  x = toInt(x)
  y = toInt(y)
  for i = 0, 9 do
    for j = 0, 5 do
      -- Get the mini-sprite value from TIC-80 map
      val = peek(0x08000 + (i + x) + (j + y) * 240)
      if i + x < 0 then val = 17 end
      if i + x > 239 then val = 17 end
      if j + y < 0 then val = 17 end
      if j + y > 135 then val = 17 end
      drawMapSprite(val, i, j)
    end
  end
end

-- DRAW SPRITES
-- --------------------------------------------------
function drawMapSprite(val, i, j)
  -- Wall 1 
  if val == 1 then
    spr(65, i * 24, j * 24, -1, 1, 0, 0, 3, 3)
  end
  -- Secret Wall 1
  if val == 2 then
    spr(65, i * 24, j * 24, -1, 1, 0, 0, 3, 3)
    spr(2, i * 24 + 8, j * 24 + 8, -1, 1, 0, 0, 1, 1)
  end
  -- Wall 2 
  if val == 3 then
    spr(68, i * 24, j * 24, -1, 1, 0, 0, 3, 3)
  end
  -- Stairs left
  if val == 4 then
    spr(71, i * 24, j * 24, -1, 1, 0, 0, 2, 3)
    spr(72, i * 24 + 16, j * 24, -1, 1, 0, 0, 1, 3)
  end
  -- Stairs center
  if val == 5 then
    spr(72, i * 24, j * 24, -1, 1, 0, 0, 1, 3)
    spr(72, i * 24 + 8, j * 24, -1, 1, 0, 0, 1, 3)
    spr(72, i * 24 + 16, j * 24, -1, 1, 0, 0, 1, 3)
  end
  -- Stairs right
  if val == 6 then
    spr(72, i * 24, j * 24, -1, 1, 0, 0, 1, 3)
    spr(72, i * 24 + 8, j * 24, -1, 1, 0, 0, 2, 3)
  end
  -- Pikes
  if val == 7 then
    spr(160, i * 24, j * 24, -1, 1, 0, 0, 3, 3)
  end
  -- Little Skull
  if val == 8 then
    spr(204, i * 24, j * 24, -1, 1, 0, 0, 3, 2)
  end
  -- Big Skull
  if val == 9 then
    spr(236, i * 24, j * 24, -1, 1, 0, 0, 3, 2)
  end
  -- Aztec Statue
  if val == 10 then
    spr(163, i * 24, j * 24, -1, 1, 0, 0, 3, 3)
  end
  -- Weird Statue
  if val == 11 then
    spr(118, i * 24, j * 24, -1, 1, 0, 0, 3, 3)
  end
  -- Pedestal
  if val == 12 then
    spr(166, i * 24, j * 24, -1, 1, 0, 0, 3, 3)
  end
  -- Book
  if val == 13 then
    spr(13, i * 24 + 8, j * 24 + 16, -1, 1, 0, 0, 1, 1)
  end
  -- Water
  if val == 14 then
    spr(112, i * 24, j * 24, -1, 1, 0, 0, 3, 3)
  end
  -- Pillar
  if val == 15 then
    spr(208, i * 24, j * 24, -1, 1, 0, 0, 3, 3)
  end
  -- Tree
  if val == 17 then
    spr(78, i * 24 + 8, j * 24, -1, 1, 0, 0, 2, 3)
  end
  -- Rotated Stairs up
  if val == 16 then
    spr(71, i * 24, j * 24, -1, 1, 0, 1, 1, 3)
    spr(72, i * 24, j * 24 + 8, -1, 1, 0, 1, 1, 3)
    spr(72, i * 24, j * 24 + 16, -1, 1, 0, 1, 1, 3)
  end
  -- Rotated Stairs center
  if val == 32 then
    spr(72, i * 24, j * 24, -1, 1, 0, 1, 1, 3)
    spr(72, i * 24, j * 24 + 8, -1, 1, 0, 1, 1, 3)
    spr(72, i * 24, j * 24 + 16, -1, 1, 0, 1, 1, 3)
  end
  -- Rotated Stairs right
  if val == 48 then
    spr(72, i * 24, j * 24, -1, 1, 0, 1, 1, 3)
    spr(72, i * 24, j * 24 + 8, -1, 1, 0, 1, 2, 3)
  end
  -- Mine
  if val == 18 then
    spr(115, i * 24, j * 24, -1, 1, 0, 0, 3, 3)
  end
  -- Boulder
  if val == 19 then
    spr(470, i * 24, j * 24, -1, 1, 0, 0, 3, 3)
  end
  -- Little Chest
  if val == 20 then
    spr(121, i * 24, j * 24 + 8, -1, 1, 0, 0, 3, 2)
  end
  -- Little Chest Open
  if val == 21 then
    spr(153, i * 24, j * 24 + 8, -1, 1, 0, 0, 3, 2)
  end
  -- Big Chest
  if val == 22 then
    spr(185, i * 24, j * 24 + 7, -1, 1, 0, 0, 3, 2)
  end

  -- Pretty Statue
  if val == 23 then
    spr(126, i * 24 + 4, j * 24 + 8, -1, 1, 0, 0, 2, 2)
  end
  -- Red Door
  if val == 33 then
    if player.redKey == 0 then
      spr(211, i * 24, j * 24, -1, 1, 0, 0, 3, 3)
      spr(223, i * 24 + 8, j * 24 + 8, -1, 1, 0, 0, 1, 1)
    end
  end
  -- Green Door
  if val == 34 then
    if player.greenKey == 0 then
      spr(211, i * 24, j * 24, -1, 1, 0, 0, 3, 3)
      spr(239, i * 24 + 8, j * 24 + 8, -1, 1, 0, 0, 1, 1)
    end
  end
  -- Blue Door
  if val == 35 then
    if player.blueKey == 0 then
      spr(211, i * 24, j * 24, -1, 1, 0, 0, 3, 3)
      spr(255, i * 24 + 8, j * 24 + 8, -1, 1, 0, 0, 1, 1)
    end
  end
  -- Yellow Door
  if val == 36 then
    if player.yellowKey == 0 then
      spr(211, i * 24, j * 24, -1, 1, 0, 0, 3, 3)
    end
  end
  -- Spacechip way
  if val == 38 then
    spr(188, i * 24, j * 24, -1, 1, 0, 0, 3, 1)
    spr(188, i * 24, j * 24 + 16, -1, 1, 0, 2, 3, 1)
  end
  if game.state == -1 then -- It's flyBy Mode
    -- Gobelin Sprite	  
    if val == 49 then
      spr(352, i * 24, j * 24, 15, 1, 0, 0, 3, 3)
    end
    -- Player Sprite	  
    if val == 64 then
      spr(256, i * 24, j * 24, 15, 1, 0, 0, 3, 3)
      spr(271, i * 24 + 8, j * 24 + 4, 15, 1, 0, 0, 1, 1)
    end
  end
  -- Big Desk	  
  if val == 37 then
    spr(27, i * 24 - 32 + 3, j * 24, -1, 1, 0, 0, 5, 3)
    spr(27, i * 24 + 8 + 3, j * 24, -1, 1, 1, 0, 5, 3)
  end
  -- Yellow Key
  if val == 207 then
    if player.yellowKey == 0 then
      spr(val, i * 24 + 8, j * 24 + 8, -1, 1, 0, 0, 1, 1)
    end
  end
  -- Red Key
  if val == 223 then
    if player.redKey == 0 then
      spr(val, i * 24 + 8, j * 24 + 8, -1, 1, 0, 0, 1, 1)
    end
  end
  -- Green Key
  if val == 239 then
    if player.greenKey == 0 then
      spr(val, i * 24 + 8, j * 24 + 8, -1, 1, 0, 0, 1, 1)
    end
  end
  -- Blue Key
  if val == 255 then
    if player.blueKey == 0 then
      spr(val, i * 24 + 8, j * 24 + 8, -1, 1, 0, 0, 1, 1)
    end
  end
  -- Big Arch	  
  if val == 55 then
    spr(74, i * 24 - 24 + 3, j * 24 - 24, -1, 1, 0, 0,
        4, 3)
    spr(74, i * 24 + 11, j * 24 - 24, -1, 1, 1, 0, 4, 3)
    spr(124, i * 24 - 15, j * 24, -1, 1, 1, 0, 2, 3)
    spr(124, i * 24 + 22, j * 24, -1, 1, 1, 0, 2, 3)
  end
  -- SpaceShip Control	  
  if val == 80 then
    spr(172, i * 24 + 5, j * 24 - 24 + 8, -1, 1, 0, 0,
        2, 1)
    spr(217, i * 24, j * 24, -1, 1, 1, 0, 3, 3)
  end

end

-- FONCTION UTILITAIRES
-- -------------------------------
function toInt(n)
  local s = tostring(n)
  local i, j = s:find('%.')
  if i then
    return tonumber(s:sub(1, i - 1))
  else
    return n
  end
end

-- Linear Interpolation
function lerp(a, b, mu) return a * (1 - mu) + b * mu end

-- <TILES>
-- 001:ffffffffffffffffff0ff0ffffffffffff0ff0fffff00fffffffffffffffffff
-- 002:4444444444044044444444444440044400000000044444400440044004044040
-- 003:ffffffffffffffffff0ff0ffffffffffffffffffff0000ffffffffffffffffff
-- 004:fffffffffff00000fff0eeeefff0eeeeff000000ff0eeeeef00eeeeef0000000
-- 005:ffffffff00000000eeeeeeeeeeeeeeee00000000eeeeeeeeeeeeeeee00000000
-- 006:ffffffff00000fffeeee0fffeeee0fff000000ffeeeee0ffeeeee00f0000000f
-- 007:000000000000000000e00e000ee0ee0000e00e00f0e00e0ff0e00e0fffffffff
-- 008:00000000000cc00000cccc000c0cc0c00cccccc000cccc0000c00c0000000000
-- 009:0000000000cccc000cccccc0cc0cc0cccccccccc0cccccc00c0cc0c000000000
-- 010:0400004000400400040440400004400000444400040440400004400000400400
-- 011:0444444004044040004444000004400004444440040440400004400000444400
-- 012:00000000022222200eeeeee000e44e0000e44e0000eeee000eeeeee00ee00ee0
-- 013:4444444440000004400000044040440440000004404404044000000444444444
-- 014:000000000aa00aa0a000a00000000000000000000aa00aa0a000a00000000000
-- 015:0000000000ffff000ff00ff00f0ee0f00f0ee0f00ff00ff000ffff0000000000
-- 016:ffffffff00ffffff0000ffff0ee0000f0ee0ee0f0ee0ee0f0ee0ee0f0ee0ee0f
-- 017:0006000000666000006660000066600000666000000200000002000000222000
-- 018:00dddd00000ee000d00ee00ddeeffeeddeeffeedd00ee00d000ee00000dddd00
-- 019:0000000000eeee000eee0ee00eeee0e00eeeeee00eeeeee000eeee0000000000
-- 020:0000000000000000000000000044440004400440044444400444444000000000
-- 021:0000000000000000044444400400004004000040044444400444444000000000
-- 022:0000000000444400044444400440044004444440044444400444444000000000
-- 023:0000000000000000004004000044440000444400000440000004400000444400
-- 025:f9aaaa9f9aa99aa99a999ccc9a999cac9a9999ac9aa99ac999aaac99f9999ccc
-- 026:f00000ff0220220f2222222022222c202222c2200222220ff02220ffff020fff
-- 027:000000000000000000000000000000000000000000000fff0000ffff0000ff00
-- 028:0000000000000000000000000000000000000000ffffffffffffffff00000000
-- 029:0000000000000000000000000000000000000000ffffffffffffffff00000000
-- 030:0000000000000000000000000000000000000000ffffffffffffffff00000000
-- 031:0000000000000000000000000000000000000000ffffffffffffffff00000000
-- 032:0ee0ee0f0ee0ee0f0ee0ee0f0ee0ee0f0ee0ee0f0ee0ee0f0ee0ee0f0ee0ee0f
-- 033:2200002222222222020000200200002002000020020000202222222222000022
-- 034:6600006666666666060000600600006006000060060000606666666666000066
-- 035:9900009999999999090000900900009009000090090000909999999999000099
-- 036:4400004444444444040000400400004004000040040000404444444444000044
-- 037:0000000000000000ffffffffeeeeeeeeeffffffeef0000feff0000ffff0000ff
-- 038:fffffffff4f44f4fffffffff0000000000000000fffffffff4f44f4fffffffff
-- 039:0000000002000020002002000002200000022000002002000200002000000000
-- 043:0000ff010000ff010000ff000000ffff0000ffff0000000000000f0d00000f0d
-- 044:010101010101010100000000ffffffffffffffff000000000d0d0d0f0d0d0d0f
-- 045:010101010101010100000000f0101010f010101000000000ffff0fff000f0f00
-- 046:010101010101010100000000ffffff0fffffff0f00000000ff0fffff0f0f0000
-- 047:111101111111011100000000ffffffffffffffff00000000fffffffff0000f00
-- 048:0ee0ee0f0ee0ee0f0ee0ee0f0ee0ee0f0ee0000f0000ffff00ffffffffffffff
-- 049:0000000000333000033030000333333003333330033300000033330000000000
-- 050:0004400000440400044444400400440004400440004444000004400000440400
-- 051:0000000000011100001010101111111111000011111111110011110000000000
-- 055:044444404444444444444444eee00eee0e0000e00e0000e00e0000e0fff00fff
-- 059:00000f0d00000f0000000fff00000fff0000000000000f0f0000f0f00000ff0f
-- 060:0d0d0d0f0000000fffffffffffffffff000000000f0f0f0ff0f0f0f00f0f0f0f
-- 061:0f0f0f0f0fff0fff00000000000000000000000000000000f0000000f0000000
-- 062:0f0f00f00f0ffff00f0000000fffffff00000000000000000000000000000000
-- 063:f00f0f00ffff0fff00000000ffffffff00000000000000000000000000000000
-- 064:0000000000444400040440400444444004044040044004400044440000000000
-- 065:fff0fff0f0000000f0eeeeee00ee000ef0ee040ef0ee000ef0eeee0e00e000e0
-- 066:ffffffff00000000eeeeeeee000ee000040ee040000ee000e0eeee0e00000000
-- 067:0fff0fff0000000feeeeee0fe000ee00e040ee0fe000ee0fe0eeee0f0e000e00
-- 068:fff0fff0f0000000f0dddddd00d00000f0d0eee0f0d0e0e0f0d0e0ee00d0e000
-- 069:ffffffff00000000dddddddd00000000eee00eeee0e00e0ee0eeee0e00000000
-- 070:0fff0fff0000000fdddddd0f00000d000eee0d0f0e0e0d0fee0e0d0f000e0d00
-- 071:0000000000000000000000000000000000000000fffff0ff000000000eeeeeee
-- 072:0000000000000000000000000000000000000000fff0ffff00000000eeeeeeee
-- 073:0000000000000000000000000000000000000000ff0fffff00000000eeeeeee0
-- 074:0000000000000000000000000000000000000000000000440000044400000444
-- 075:0000000000000000000000000000000000000000000440004044440440444404
-- 076:0000000000000000000000000000000000000000440004404440444444404444
-- 077:0000000000000000000000000000000000440004044440440444404404440000
-- 078:0000000000000000000006060000006000000006000000600000060600006060
-- 079:0000000000000000000000006000000006000000606000000606000060600000
-- 080:0000000000000000000440000044440004400440440440440000000000000000
-- 081:f0e04000f0e000e0f0eeeee0f0e000e0f0e04000f0e000eef0eeee00f0000e04
-- 082:4444444444044044444444444440044400000000040440400440044004444440
-- 083:00040e0f0e000e0f0eeeee0f0e000e0f00040e0fee000e0f00eeee0f40e0000f
-- 084:f0d0eee0f0d000e0f0d0eee0f0d0e000f0d0e000f0d0eee0f0d000e0f0d0eee0
-- 085:4444444444444444440440444444444444044044400000044444444444444444
-- 086:0eee0d0f0e000d0f0eee0d0f000e0d0f000e0d0f0eee0d0f0e000d0f0eee0d0f
-- 087:0eeeeeee0eeeeeee0eeeeeee00000000f0eeeeeef0eeeeeef0eeeeeef0eeeeee
-- 088:eeeeeeeeeeeeeeeeeeeeeeee00000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 089:eeeeeee0eeeeeee0eeeeeee000000000eeeeee0feeeeee0feeeeee0feeeeee0f
-- 090:0000044400000444000000000000004400000004000000000000004400000444
-- 091:4044440440444404000000004044440440444404000000004444404444444044
-- 092:44404444444000000000444444404444444044440000044044000000444440dd
-- 093:04440888000008880444000004444044044440440044000400000000dddddddd
-- 094:0000060600006060000606060000606000060606000060600006060600006060
-- 095:0600000060600000060600006060600006060000606000000606000060600000
-- 097:00dd0e00f0dd0ee0f0000ee0f0ee0eee00ee0000f0eeeeeef0000000fff0fff0
-- 098:00000000ffffffff00000000040ee04000000000eeeeeeee00000000ffffffff
-- 099:00e0dd000ee0dd0f0ee0000feee0ee0f0000ee00eeeeee0f0000000f0fff0fff
-- 100:00d0e000f0d0e0eef0d0e0e0f0d0eee000d00000f0ddddddf0000000fff0fff0
-- 101:00000000e0eeee0ee0e00e0eeee00eee00000000dddddddd00000000ffffffff
-- 102:000e0d00ee0e0d0f0e0e0d0f0eee0d0f00000d00dddddd0f0000000f0fff0fff
-- 103:00000000ff0eeeeeff0eeeeeff0eeeee000eeeeeff000000ff000000ff000000
-- 104:00000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
-- 105:00000000eeeee0ffeeeee0ffeeeee0ffeeeee000000000ff000000ff000000ff
-- 106:0000044400000044000000000000440400044404000444040000440400000000
-- 107:4444404444444044000000004444440444444404444444044444440400000000
-- 108:444400dd44000ddd00000ddd4400000044440ee044440ee044400ee000000000
-- 109:0000000004444444000000000404040400000000040404040040404000000000
-- 110:0000060600006060000000060000000000000000000000020000000200000022
-- 111:0606000060606000060600002200000022000000220000002200000002000000
-- 112:00000000000aaa0000aa0aa0a0aa00a0aaa00aa00000000000000000000aaa00
-- 113:00000000000aaa0000aa0aa0a0aa00a0aaa00aa00000000000000000000aaa00
-- 114:00000000000aaa0000aa0aa0a0aa00a0aaa00aa00000000000000000000aaa00
-- 115:000000000000000000d0d0d0000d0d0000d0d0d0000d0d0000d0d0d00000000d
-- 116:0dddddd00d0000d00004400000000000000440000000000000ffff00d0f00f0d
-- 117:00000000000000000d0d0d0000d0d0000d0d0d0000d0d0000d0d0d00d0000000
-- 118:0000000000004444444444404444444440044440400444000444440004004440
-- 119:0444440044000444004440004444444404444400004440000044400004404400
-- 120:0000000044400000444444404444444044440040044400400444440044400400
-- 121:0000000000000000000000000000000000000000000004440000400000044044
-- 122:0000000000000000000000000000000000000000444444440000000004444440
-- 123:0000000000000000000000000000000000000000444000000004000044044000
-- 124:000dddd0000dddd00000000000eeeeee00eeeeee0000000000eeeeee00eeeeee
-- 125:00dddd0000dddd00000000000eeeeee00eeeeee0000000000eeeeee00eeeeee0
-- 126:0000000000400040040404040040000004040444004004040404044400400400
-- 127:0000000004000400404040400000040044404040404004004440404000400400
-- 128:00aa0aa0a0aa00a0aaa00aa00000000000000000000aaa0000aa0aa0a0aa00a0
-- 129:00aa0aa0a0aa00a0aaa00aa00000000000000000000aaa0000aa0aa0a0aa00a0
-- 130:00aa0aa0a0aa00a0aaa00aa00000000000000000000aaa0000aa0aa0a0aa00a0
-- 131:0000000ddd000000d00000ffd04040f0d04040f0d00000ffdd0000000000000d
-- 132:d0ffff0d00000000f0dddd0ff0d00d0ff0d00d0ff0dddd0f00000000d0ffff0d
-- 133:d0000000000000ddff00000d0f04040d0f04040dff00000d000000ddd0000000
-- 134:0400444400444444004004440040044400044440000440440004444000000444
-- 135:4440444444000444444444440000000400000000444444440444440040000044
-- 136:4440040044444000440040004400400044440000404400004444000044000000
-- 137:0004000000000404000404400000040400040000000440440000000000000000
-- 138:0000000004044040404444040404404000000000444444440000000000000000
-- 139:0000400040400000044040004040000000004000440440000000000000000000
-- 140:0000000000eeeeee00eeeeee0000000000eeeeee00eeeeee00000000000dddd0
-- 141:000000000eeeeee00eeeeee0000000000eeeeee00eeeeee00000000000dddd00
-- 142:0000004404440444004404440440004400004440004444440040404400000000
-- 143:4400000044404440444044004400044004440000444444004404040000000000
-- 144:aaa00aa00000000000000000000aaa0000aa0aa0a0aa00a0aaa00aa000000000
-- 145:aaa00aa00000000000000000000aaa0000aa0aa0a0aa00a0aaa00aa000000000
-- 146:aaa00aa00000000000000000000aaa0000aa0aa0a0aa00a0aaa00aa000000000
-- 147:0000000d00d0d0d0000d0d0000d0d0d0000d0d0000d0d0d00000000000000000
-- 148:d0f00f0d00ffff00000000000004400000000000000440000d0000d00dddddd0
-- 149:d00000000d0d0d0000d0d0000d0d0d0000d0d0000d0d0d000000000000000000
-- 150:0004440000444000044400000444000004444440004444000000000000000fff
-- 151:0fffff00f0fff0f0ff0f0ff0ff0f0ff0fffffff00fffff00fffffff0ffffffff
-- 152:04440000004440000004440000044400444444000444400000000000ff000000
-- 153:0000000000004444000400000004044000040400000404000004040000044044
-- 154:0000000044444444000000004444444400000000000000000000000004444440
-- 155:0000000044440000000040000440400000404000004040000040400044044000
-- 156:000dddd000000000000dddd0000dddd00000000000ffffff00ffffff00000000
-- 157:00dddd000000000000dddd0000dddd00000000000ffffff00ffffff000000000
-- 158:0000000d000000d000000d0d00000d0d000000dd000000000000000000000000
-- 159:dd0000000dd000000dddddddd0000000d00fffff000fffff00000000000d0d0d
-- 161:00000000000000000000000000000000000000000000000002000000dd200000
-- 162:00000000000000000000000000000000000000000000000002000000dd200000
-- 163:0044044000400400004404400004004000440440000000000044404000404440
-- 164:4444444440044004440440440000000044444444400440044444444444044044
-- 165:0440440000400400044044000400400004404400000000000404440004440400
-- 166:0000000000033333000303030000d0d00000dddd000000000000dddd0000d000
-- 167:000000003333333303033030d0d00d0ddddddddd00000000d044440dd040040d
-- 168:0000000033333000303030000d0d0000dddd000000000000dddd0000000d0000
-- 169:0004000000000404000404400000040400040000000440440000000000000000
-- 170:0000000004044040404444040404404000000000044444400000000000000000
-- 171:0000400040400000044040004040000000004000440440000000000000000000
-- 172:0000444400004040000004040004444400444040044404044444444400404040
-- 173:4440000040400000040000004444000040444000040444004444444040404000
-- 174:0ddddd00ddd0ddd0d00000d0d0eee0d0d0e0e0ddd00000d0ddd0ddd0ddddddd0
-- 175:000d0d0d000d0d0d000d0d0d000d0d0d000d0d0d00000000000fffff000fffff
-- 176:000000000000020000002dd000000d0000000d0000000d0000000d0000000d00
-- 177:0d0002000d00dd200d000d000d000d000d000d000d000d000d000d000d000d00
-- 178:0d0000000d0000000d0000000d0000000d0000000d0000000d0000000d000000
-- 179:0000000000444040004044400040400400400040004400040000044000000444
-- 180:4040040444444444004444000404404040400404040440404040040004044040
-- 181:0000000004044400044404004004040004000400400044000440000044400000
-- 182:0000d0d00000ddd0000000000000000000000000000000000000000000000000
-- 183:d040040dd044440dd000000d0dddddd0d000000ddd0dd0dddd0dd0dddd0dd0dd
-- 184:0d0d00000ddd0000000000000000000000000000000000000000000000000000
-- 185:0000000000e0eeee0ee000000ee0eee00ee0eee0000000000ff0fff00f000000
-- 186:0eeeeee0ee0000eeee0440eeee0000eeeeeeeeee00000000ffffffff00000000
-- 187:00000000eeee0e0000000ee00eee0ee00eee0ee0000000000fff0ff0000000f0
-- 188:00000000fff0fff0f0000000f0eeeeee00ee000ef0ee040ef0ee000ef0eeeeee
-- 189:00000000ffffffff00000000eeeeeeee000ee000040ee040000ee000eeeeeeee
-- 190:000000000fff0fff0000000feeeeee0fe000ee00e040ee0fe000ee0feeeeee0f
-- 192:00ee0d00f0ee0d00f0000d00f0ee0d0000ee0000f0eeeeeef0000000fff0fff0
-- 193:0d000d000d000d000d000d000d000d0000000000eeeeeeee00000000ffffffff
-- 194:0d00ee000d00ee0f0d00000f0d00ee0f0000ee00eeeeee0f0000000f0fff0fff
-- 195:0000044400004444000004040000000000000004000440040004440400044444
-- 196:0404404004044040044004400000000044044044440440444404404444044044
-- 197:4440000044440000404000000000000040000000400440004044400044444000
-- 198:0000000000000000000dddd0000d00d0000dd0d0000dd0dd000dd00000000000
-- 199:dd0dd0dddd0dd0dddd0dd0dddd0dd0dd000dd000dd0dd0dddd0dd0dd00000000
-- 200:00000000000000000dddd0000d00d0000d0dd000dd0dd000000dd00000000000
-- 201:000eeeee0f0e000e0f0e04000f0e000e000eeeee0f0000000ff0fff000000000
-- 202:eeeeeeee000ee00004000040000ee000eeeeeeee00000000ffffffff00000000
-- 203:eeeee000e000e0f00040e0f0e000e0f0eeeee000000000f00fff0ff000000000
-- 204:000000000000000000000000000000000000000c000000c0000000c0000000c0
-- 205:000000000000000000000000000000000c0c000000c0c00c00c0c0cc00c0c0cc
-- 206:0000000000000000000000000000000000000000cccc00000c0cc000ccccc000
-- 207:0000000004444400040004000444440000040000000440000004000000000000
-- 208:0000000000000000000000ff00000f000000f0ee000f0e0000f0e00f00f0e0ff
-- 209:00000000ffffffff000000000eeeeeeeee00000e00088800ff08880f0f08880f
-- 210:00000000f00000000ff00000000f0000eee0f000000e0f00ff00e0f00ff0e0f0
-- 211:fff0fff0f0000000f0eeeeee00eeeeeef0ee0000f0ee0404f0ee004000ee0404
-- 212:ffffffff00000000eeeeeeeeeeeeeeee00000000040440404040040400000000
-- 213:0fff0fff0000000feeeeee0feeeeee000000ee0f4040ee0f0400ee0f4040ee00
-- 214:4444444440000000404444444040404040440404404040404004040040404400
-- 215:4040404004040404444444444000004000000004000000000000000000000000
-- 216:4040404004040404444040404044040404044040404044040404044004404044
-- 217:4400000444040404400000440040404400000000040400400000044004044440
-- 218:4444444440444044404440440000000400000000000000000000000000000000
-- 219:0000044004040440400000404040400000000000400404004400000044440400
-- 220:000c000c00c0cc0c00000000000cccc000c00000000000000000000000000000
-- 221:0cc0c0cc00cc0c0000000000000000000000000c00000cc00000000c00000000
-- 222:c0ccc00cccc00cc0c0c0000c0000c0000000cc00000000000000000000000000
-- 223:0000000002222200020002000222220000020000000220000002000000000000
-- 224:00f0e0f000f0e0ff0f00e0000f0e00880f0e08880f0e00880f00e00000f0e0ff
-- 225:0f08880fff08880f0000000088044408880444088804440800000000ff08880f
-- 226:00f0e0f0fff0e0f00000e00f88800e0f88880e0f88800e0f0000e00ffff0e0ff
-- 227:f0ee0040f0ee0404f0ee0040f0ee0404f0ee0404f0ee0040f0ee0404f0ee0040
-- 228:0444444004044040044444400004400004444440040440400004400004444440
-- 229:0400ee0f4040ee0f0400ee0f4040ee0f4040ee0f0400ee0f4040ee0f0400ee0f
-- 230:4044440040444000400000004444440040000400400004004000400040040000
-- 232:0444404400444044000040440000404400004044000040440000404400004044
-- 233:0000044044440040444400004404400004004000440040004400400004440000
-- 235:4400000040044440000444400044044000400400004004400040044000044400
-- 236:000000000000000000000000000000000000000c000000c0000000c000000c00
-- 237:000000000000000000000000000000000cc0000cc00cc0ccc0c000ccc0c0c0cc
-- 238:000000000000000000000000ccccc0000ccc0c0000c00cc00ccc0cc0c0c0ccc0
-- 239:0000000006666600060006000666660000060000000660000006000000000000
-- 240:00f0e0f000f0e0ff00f0e00f000f0e000000f0ee00000f00000000ff00000000
-- 241:0f08880f0f08880fff08880f00088800ee00000e0eeeeeee00000000ffffffff
-- 242:00f0e0f00ff0e0f0ff00e0f0000e0f00eee0f000000f00000ff00000f0000000
-- 243:00ee0404f0ee0040f0ee0404f0ee000000eeeeeef0eeeeeef0000000fff0fff0
-- 244:00000000404004040404404000000000eeeeeeeeeeeeeeee00000000ffffffff
-- 245:4040ee000400ee0f4040ee0f0000ee0feeeeee00eeeeee0f0000000f0fff0fff
-- 246:4440000040000000404400004044000040444400404444004044440044444400
-- 248:0000404400004044000040440000404404444044044400440444044404444444
-- 249:4440000044400000040000004440000044400000444440004444444044444440
-- 251:0000444000004440000004000000444000004440004444404444444044444440
-- 252:00000c0c00000c0c000c0c0c0ccc00c000cc000000c000000000000000000000
-- 253:0c00c00c0c00c00c0cc00c0000000000000c00000cccc000cc0c0c0000000000
-- 254:cccccc000c0c0c0000000000ccccc0c00000000c00000ccc0000c0c000000000
-- 255:0000000009999900090009000999990000090000000990000009000000000000
-- </TILES>

-- <SPRITES>
-- 000:fffffffffffffffffffffffffffffffffffffff0fffffff0fffffff0fffffff0
-- 001:ffffffffffffffffffffffff0000000f04444400444444404444444044444440
-- 002:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 003:fffffffffffffffffffffffffffffffffffffff0fffffff0fffffff0fffffff0
-- 004:ffffffffffffffffffffffff000000ff04444400444444404444404044404440
-- 005:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 006:fffffffffffffffffffffffffffffffffffffff0fffffff0fffffff0fffffff0
-- 007:ffffffffffffffffffffffff000000ff04444400444444404444404044404440
-- 008:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 009:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 010:fffffffffffffffffffffffff000000000444440044444440444444404444444
-- 011:ffffffffffffffffffffffffffffffff0fffffff0fffffff0fffffff0fffffff
-- 012:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000
-- 013:fffffffffffffffff00000000044444004444444044444440444444404444444
-- 014:ffffffffffffffffffffffff0fffffff0fffffff0fffffff0fffffff00000fff
-- 015:04444400444444404404044044444440440004400444440000444000ffffffff
-- 016:fffffff0fffffff0fffffff0fffffff0ffffff00fffff004fffff044fff00044
-- 017:4444444004444400004440009900099009909900090909040909090409090904
-- 018:ffffffffffffffffffffffffffffffffffffffff0fffffff40ffffff4000ffff
-- 019:fffffff0fffffff0ffffffffffffff00ffff0004fff00404ff004400ff044440
-- 020:444400000444440f0044400f9990090f00990900090999040909090409090900
-- 021:ffffffffffffffffffffffff000fffff0400ffff0440ffff0440ffff0000ffff
-- 022:fffffff0fffffff0fffffffffffffff0ffffff00ffffff04ffffff04ffffff00
-- 023:444400000444440f0044400f9990090f0099090f090999000909090044090904
-- 024:ffffffffffffffffffffffffffffffffffffffffffffffff0fffffff0fffffff
-- 025:fffffffffffffffffffffffffffffff0ffffff00fffff004ffff0044ffff0444
-- 026:0444444400444440f00444000090009040990990409090900090909040909090
-- 027:0fffffff0fffffffffffffff00ffffff400fffff4400ffff04400fff44440fff
-- 028:ffff0404ffff0444ffff0044fffff004ffffff00fffffff0ffffffffffffffff
-- 029:004444404004440000900090409909904090909000909090f0909090f0909090
-- 030:04040fff44440fff04400fff4400ffff400fffff00ffffffffffffffffffffff
-- 031:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 032:fff04440fff00444ffff0440ffff0000fffffffffffffff0fffffff0fffffff0
-- 033:09090900099099040900090000d0d0000d000d0f00d0d000ddd0ddd000000000
-- 034:4440ffff4400ffff440fffff000fffffffffffffffffffffffffffffffffffff
-- 035:ff000400ffff0000ffffff0dffffff0dffffff0dffffff00ffffffffffffffff
-- 036:0909090f0909090fd0d0d0000d0d0d0d0000d0dd0ff00dd0ffff0000ffffffff
-- 037:ffffffffffffffff0fffffff0fffffff0fffffff0fffffffffffffffffffffff
-- 038:fffffff0fffffff0fffffff0ffffff00ffffff0dffffff0dffffff0dffffff00
-- 039:4409090404090900d0d0d0d00d000d00d000d0000000ddd0dd000000000fffff
-- 040:0fffffff0fffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 041:ffff0404ffff0000ffffffffffffffffffffffffffffffffffffffffffffffff
-- 042:0090909000990990f0900090f00d0d00f0d000d0f0dd0dd0f0dd0dd0f0000000
-- 043:04040fff00000fffffffffffffffffffffffffffffffffffffffffffffffffff
-- 044:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 045:f0990990f0900090f00d0d0000dd0dd00ddd0ddd0dd000dd0d0fff0d00fffff0
-- 046:ffffffffffffffffffffffff0fffffff0fffffff0fffffff0fffffff0fffffff
-- 047:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 048:fffffffffffffffffffffffffffffffffffffff0fffffff0fffffff0fffffff0
-- 049:ffffffffffffffffffffffff0000000f04444400444444404444444044444440
-- 050:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 051:fffffffffffffffffffffffffffffffffffffff0fffffff0fffffff0fffffff0
-- 052:ffffffffffffffffffffffff0000000f04444400444444404444444044444440
-- 053:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 054:fffffffffffffffffffffffffffff000ffff0044ffff0444ffff0440ffff0444
-- 055:ffffffffffffffffffffffff0000ffff44400fff44440fff40440fff44440fff
-- 056:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 057:fffffffffffffffffffffffffffffff0ffffff00ffffff04ffffff04ffffff04
-- 058:ffffffffffffffffffffffff000000ff4444400f4444440f4040440f4444440f
-- 059:fffffffffffffffffffffffffffffffff000ffff00400fff04440fff04040fff
-- 060:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 061:ffffffffffffffffffffffffff000000f0044444f0444444f0440404f0444444
-- 062:ffffffffffffffffffffffff0fffffff00ffffff40ffffff40ffffff40ffffff
-- 063:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 064:fffffff0fffffff0fffffff0fffffff0ffffff00fffff004fffff044fff00044
-- 065:4444444004444400004440009900099009909900090909040909090409090900
-- 066:ffffffffffffffffffffffffffffffff0fffffff0fffffff00ffffff40ffffff
-- 067:fffffff0fffffff0fffffffffffffff0ffffff00ffffff04fffff004fffff040
-- 068:44444440044444000044400f9900099009909900090909040909090409090904
-- 069:ffffffffffffffffffffffffffffffff0fffffff00ffffff40ffffff4000ffff
-- 070:ffff0440ffff0044ffff0004ffff0990fff00099ff004090ff04409000044090
-- 071:00440fff44400fff44000fff00990fff09900000909040449090440490904444
-- 072:ffffffffffffffffffffffffffffffff0000000f444444004440044044444400
-- 073:ffffff04ffffff00ffffff00ffffff09fffff000ffff0040ffff0440ff000440
-- 074:4000440f4444400f0444000f9000990f99099000909090409090904490909004
-- 075:04040fff04440fff04440fff04440fff044400ff040440ff444400ff444440ff
-- 076:ffffffffffff0000ffff0444ffff0044ffff0444fff00444fff04044fff04440
-- 077:f044000400044444000044400099000904099099440909094409090940090909
-- 078:40ffffff00ffffff00ffffff90ffffff000fffff0400ffff0440ffff044000ff
-- 079:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 080:fff04440fff00444ffff0440ffff0000fffffff0fffffff0ffffffffffffffff
-- 081:09090904099099040900090000d0d00fddd00d0f00000d0ffff0d000fff0ddd0
-- 082:40ffffff40ffffff00ffffffffffffffffffffffffffffffffffffffffffffff
-- 083:fffff044fffff044fffff000fffffffffffffffffffffffffffffff0fffffff0
-- 084:09090900099099040900090000d0d0000d00ddd00d00000000d0ffffddd0ffff
-- 085:4440ffff4400ffff440fffff000fffffffffffffffffffffffffffffffffffff
-- 086:0444009000444099f0440090f000000dfffff0d0ffff000dffff0dddffff0000
-- 087:9090044009904440009000000d00ffff00d0ffff0d000fff0ddd0fff00000fff
-- 088:4000000f00ffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 089:ff044400ff004440fff04400fff00000fffffff0ffffff00ffffff0dffffff00
-- 090:90909000990990f0900090ff0d0d00ffd000d0ff0d0d000fdd0ddd0f0000000f
-- 091:440440ff004440fff00000ffffffffffffffffffffffffffffffffffffffffff
-- 092:fff04440fff04440fff04440fff04040fff04040fff04440fff00400ffff000f
-- 093:00090909ff099099ff090009ff00d0d0ff0d000df000d0d0f0ddd0ddf0000000
-- 094:004440ff044400ff00440fff00000fff0fffffff00ffffffd0ffffff00ffffff
-- 095:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 096:ffffffffffffffffffffffffffffff00ffffff04ffffff00fffffff0fffffff0
-- 097:ffffffffffffffff000000000444444040444004440444004444004404440000
-- 098:ffffffffffffffffffffffff0fffffff00ffffff40ffffff40ffffff40ffffff
-- 099:ffffffffffffffffffffff00ffffff04ffffff00fffffff0fffffff0ffffffff
-- 100:ffffffff00000000044444404044400444044400444400440444000000004400
-- 101:ffffffffffffffff0fffffff00ffffff40ffffff40ffffff40ffffff000fffff
-- 102:fffffffffffffffffff000f0fff04000fff04404fff00440ffff0440ffff0044
-- 103:ffffffffffffffff000000004444444400444400400440040444444000000000
-- 104:ffffffffffffffff0f000fff00040fff40440fff04400fff0440ffff4400ffff
-- 105:fffffffffffffffffffffffffff000f0fff04000fff04404fff00444ffff0444
-- 106:ffffffffffffffffffffffff0000000044444440444444444444444444444444
-- 107:fffffffffffffffffffffffff000ffff0040ffff0440ffff4400ffff440fffff
-- 108:fffffffffffffffffffffffffffffffffffffff0fffffff0fffffff0fffffff0
-- 109:ffffffffffffffffffffffff000000ff04444400444444404444404044404440
-- 110:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 111:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 112:fffffffffffffff0fffff000ffff0044fff00444fff04440f0004400f0444400
-- 113:0000440000440044440440004040440004040404404040440404040440404000
-- 114:000fffff440fffff000ffffff000ffff004000ff404440ff444400ff444440ff
-- 115:ffffff00fffff004ffff0044ffff0444ffff0440ffff0044fffff004ffff0040
-- 116:0444004444044000404044040404040440404044040404044044040444444400
-- 117:440fffff000fffff040fffff400fffff440fffff400fffff040fffff000fffff
-- 118:ffff0000ff000444ff044400f0044004f0440000f0440f00f0440f04f0440f00
-- 119:4444444404044040404444040444444040444404404444040444444040444404
-- 120:0000ffff444000ff004440ff4004400f00f0440f00f0440f4004440000404040
-- 121:ffff0044ffff0000ff000444ff044400f0044004f0440000f0440f04f0440f00
-- 122:4444444444444440040404044044404004444404404440400444440440444040
-- 123:400fffff000fffff44000fff04440fff004400ff000440ff0044400f0404040f
-- 124:fffffff0fffffff0ffffff00ffff0004fff00404fff04400fff04440fff00400
-- 125:444400000444440f0044400f0990090f00990900090999040909090409090900
-- 126:ffffffffffffffffffffffff000fffff0400ffff0440ffff0440ffff0000ffff
-- 127:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 128:f0044400f0444000f0000000ffff0044fff00444fff04444fff00404ffff0000
-- 129:040404004440444444000044440f0044400f0404400f0000040fffff000fffff
-- 130:004400ff000440ff400000ff44400fff04040fff00000fffffffffffffffffff
-- 131:f0000444f0444440f0444400f044000ff04040fff00000ffffffffffffffffff
-- 132:0444404400440404f0004004fff00000ffffff04ffffff04ffffff00ffffffff
-- 133:00ffffff400fffff440fffff44000fff444400ff404040ff000000ffffffffff
-- 134:f04400f000444000040404000404000000000044fff00444fff04040fff00000
-- 135:0404404044000044440ff044440ff044440ff044440000444040040400000000
-- 136:000040400ff000000fffffff000fffff4400ffff44400fff04040fff00000fff
-- 137:f04400f000444000040404000404000000000044fff00444fff04040fff00000
-- 138:04040400440004444400444444004040440000004440ffff4040ffff0000ffff
-- 139:0004040f0000000f4400ffff4040ffff0000ffffffffffffffffffffffffffff
-- 140:ffff0000fffff000ffff00d0fff00dddfff0ddd0fff00000ffffffffffffffff
-- 141:0909090f09090900d0d0d0d00d000d0d000f0000fffffff0ffffffffffffffff
-- 142:0000ffff0dd0ffffddd0ffffdd00ffffd00fffff00ffffffffffffffffffffff
-- 143:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 144:0000000f440044004000400440000444404044444040444400004000fff00040
-- 145:ffffffff0000ffff444000ff4444400f44004400400400400000004040404040
-- 146:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 147:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 148:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 149:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 150:ff0000ffff0440ffff0400f0ff040000ff040404ff040404ff000000fff00440
-- 151:fffffffff0000000004444404444444440044400004040400000400040404040
-- 152:fff0000ffff0440f00f0040f4000040f4404040f0404040f0000000f404400ff
-- 153:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 154:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 155:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 156:fffffffffffffffffffffffffffffffffffffff0fffffff0fffffff0fffffff0
-- 157:ffffffffffffffffffffffff0000000f04444400444444404404044044444440
-- 158:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 159:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 160:f0444400f0444444f0000000f044004000400000044004000440000004400400
-- 161:0000000044444400000044400004044000000040000400000000004400400044
-- 162:ffffffffffffffff00ff000f4000040040404440400044404000444040404400
-- 163:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 164:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 165:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 166:fff04040ff004444ff040000f0000444f0400444f00000040040040404444004
-- 167:0000000044040404040404040000000040444440404040404044444044040404
-- 168:004040ff4444400f0000040f0444000044440040440000004404004044000000
-- 169:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 170:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 171:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 172:fff000f0ff004000ff044400ff044404ff004404fff00000ffffffffffffffff
-- 173:4400044004444400004440000900090409909904090909000909090f0909090f
-- 174:f000fffff0400fff04440fff04440fff04400fff0000ffffffffffffffffffff
-- 175:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 176:044000000440444400404444f00004440000000004440004444440004444444f
-- 177:00000444444004444040004040000000000000000004004000000000fffffff0
-- 178:0000000f0ff0000f0000440f4004440f0044440f0044440f0444400f000000ff
-- 179:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 180:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 181:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 182:044040000444000000000000fffff040fffff000fffff040fffff000fffff044
-- 183:4404440404444444000040000000000000040400000000000004040044440444
-- 184:40004040000444400004044000404440000000000040ffff0000ffff4440ffff
-- 185:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 186:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 187:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 188:fffffffffff0000ffff0dd00fff0ddd0fff00dddffff0dddffff0000ffffffff
-- 189:0909090f0909090f09090900d0d0d0d00d000d0d000f000d0fffff00ffffffff
-- 190:ffffffff0000ffff0dd0ffffddd0ffffdd00ffffdd0fffff000fffffffffffff
-- 191:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 192:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 193:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 194:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 195:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 196:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 197:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 198:fffff44fffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 199:4f44f44fffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 200:4f44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 201:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 202:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 203:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 204:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 205:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 206:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 207:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 208:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 209:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 210:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 211:fffffffffffffffffffffffffffffffffffffffffffffff4ffffff4ffffff4ff
-- 212:fffffffffffffffffff44444f44444444fffffffffffffffffffffffffffffff
-- 213:ffffffffffffffff444fffff444fffffffffff44ff4fff44f44f4f40f44f4f40
-- 214:000000000000000000000000000000ee0000ee0e000eee0e000eeeee00eeeeee
-- 215:0000000000000000eeeeeeeeeeeeeeeeeeeee00eeeeeeee0eeeeeee0eeeeeeee
-- 216:000000000000000000000000e0000000eee000000eee000000ee0000000ee000
-- 217:ffffffffffffffffffffffffffffffffffffff00fffff004fffff044fffff044
-- 218:ffffffffffffffffffffffffffffffff00000fff444400ff444440ff040440ff
-- 219:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 220:ffffffffffffffffffffffffffffffffffffff00fffff004fffff044fffff044
-- 221:ffffffffffffffffffffffffffffffff00000fff444400ff444440ff040440ff
-- 222:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 224:fffff4fffff4f4ff444044fff4f4f4fff4fff4fff4ffffff4444ffff44444fff
-- 225:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4
-- 226:f4ff444ff4f44f44f4f4fff4f4f4f4f4f4f4f44ff4f4ffff44f444ff44fff4ff
-- 227:ffff4fffffff4fffffff4ffffffff4fff444ff4f44004ff440404f444044ff40
-- 228:ffffffffffffffffffffffffffffffffffffffffffffffff4444444f0000004f
-- 229:f44f4040f44f4044f44f4444f44f4f44f44f4f40ffff4f404f4fff40ffff4f44
-- 230:00eeeeee0eeeeeee0eeeeeee0eeeeeee0eeeeeee0eeee0ee0eeee0ee00eeee0e
-- 231:e0eeeeee0eeeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 232:00eee000eeeee000eeeeee00eeeeee00eeeeee00eeeeee00eeeeee00eee0e000
-- 233:fffff0440000004004040004004400000444009900440009f0000409ff040409
-- 234:444440ff000040ff000400ff444000ff000990ff9099000f0909040009090440
-- 235:ffffffffffffffffffffffffffffffffffffffffffffffffffffffff0fffffff
-- 236:fffff0440000004004040004004400000444009900440009f0000409ff040409
-- 237:444440ff000040ff000400ff44400f0000099004909900400909044009090440
-- 238:ffffffffffffffff00000fff444400ff0000400f400004000040404000000040
-- 240:4fff4fff4fff4f44ff4f4f404f4f4f404f4f4f44ff4f4fffffff4444fffff444
-- 241:fffff4444444f40400044404440444044444f444ffffff444444440044444444
-- 242:44f4f4ff04f4f4ff04f4f4ff04f4f4ff44f4f4ff4ff4f4ff0444ffff44ffffff
-- 243:44fff440f44ff444ff44ff44fff44fffffff444ffffff444ffffffffffffffff
-- 244:4444404f0444404f4000004f4444444fffffffff44444444ffffffffffffffff
-- 245:4f4fff44ffff4fff4f4ffffff4ff4ffffff4ffff444fffffffffffffffffffff
-- 246:00eeee0e000eee0e000eeee00000eeee00000eee0000000e0000000000000000
-- 247:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeeeeeeeeeeeee0eeeeee000000000
-- 248:ee0ee000ee0e0000e0ee00000ee00000ee000000000000000000000000000000
-- 249:ff000409ffff0009ffffff09ffffff09ffffff00ffffff0dfffff000fffff0dd
-- 250:090900440909000490990f0400090f04d0d00f04000d0f00d0d000ffd0ddd0ff
-- 251:00000fff44440fff44000fff4040ffff0400ffff000fffffffffffffffffffff
-- 252:ff000409ffff0009ffffff09ffffff09ffffff00ffffff0dfffff000fffff0dd
-- 253:09090040090900449099000400090f00d0d00fff000d0fffd0d000ffd0ddd0ff
-- 254:4004004000000040444444004400000f000fffffffffffffffffffffffffffff
-- </SPRITES>

-- <MAP>
-- 000:101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:100000000000000010101010000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000101111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:100000000000000010101010001010101010405060101010101010101010405060101010101000100010101010101010101010101010101010101010101022101111111111111111111111111111111111111111111111111111111111fe0000000011111111111110101010101010101010101010111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:100000000000000062626262001000610000000013000061001000001300000000000000001000100010000000000000000000000031000000100000000000101111111111111111000000000000000000000000001111111111111111000000000000111111000020000000000000000000000010101111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:100000000000000010101010001000000000000000000000001000001300000000000000001000100010001000101010101010001010101010100010101000101111111111110000000000000000001111111100001111111111111111111111110000111100000010101010101010100000000000101011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:101010101010101010101010001000610000000000000061001000410000410041000041001000100010101000100000000010001000000000100000011000101111111100000000000000000000001111111111001111111111111111111111111100111100000022000000000000100000000000101011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:101010101010101010101010001010101010101010101010101010101010101010101010101000100000000000100000004110001000000000100004021000101111110000000000111110304060301011111111001111111111111111111111111100111100000010411300ff0041100000000000001011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:10101010101010101010101000000000000000000000000000000000000000000000000000000010001010101010000000001000220000130010000003100010111111610000611111111000000000101111111100111111111111111111111111110011110000001010101010101010000000a100001011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:1000000013001000000000102010b0000000b01010101040601010101010101040601010101000100000000000220000004110001000000000100010101000101111111300000011101010405050601010101141004111111111111100000000001100110000000032000000000000100000725272001011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:1071000000003200800000130010000000000010000000000013800010000000000000000010001010101010101000130000100010000080001000000000fe101111116100006111107100727272727272100000000011111111110000000000000000000000000010411300fd0041100000000000001011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:10c0000000001000000000000010b0000000b01000f000000000f0001000f000000000f000100010004100410010101010101000101010101010101010101010111111111111111130c000008072720000300000000011111111110400000000000000000000000010101010101010100000000000001011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:100000000013100000000000801000000000001000000000000000001000000080000000001000100000000000000020000000000000000000220000000000101111111111111111101300000000800004200000000011111111110000000000000000000000000012000000000000100000000000001011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:1010101010101040506010100010b0000000b01000f013000000f0001000f000000000f01310001000000000001310101010101010101010001000f013f000101111111111111111101010101010701010100000001111111111110000000000000000000000000010411300fc0041100000000000001011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:100000000000000000000010001000000000001000000000000000001000000000000000001000102210101010101000000000000000001000101300000000101111111111111111900000000000727272900000001111111111111100000000000000000000000010101010101010100000000000101011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:1000101010101010101000101010b0000000b01010101040601010101010101040601010101000100000100000000000000000000000130000100000000000101111111111111111000000000000000000000000001111111111111100000000000000000000000042000000000000000000000010101111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:100010ff0000000000100010000000000000000000100000000000000000000000000000000000100000100000000000f00000f00000130000100000710000101100000000000000000000000000000000000000111111111111111111000041000041000000000010101010101010101010101010111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:10001000f00000f013100010000030405060300000100010101010101032103210101010101000100000100000100000000000000000001000100000c00000101100001111111111000000000000000000001111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:100010000000000000100010000030e0e0e0300000100010008013000000100000000000001000100000100000101300000000000000001000100000000000101100111111111111111111111100111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 018:100010000000000000010010000030e0e0e030000010001000f00000f000100000000000801000100000100000100000f00000f00000131000101010101010101100111110101010101010101020101010101010101011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 019:100010000000000013030010101010101010101010100010000000000080100000000000001000100000100000100000000000000000001000000000000000101100111110130000800000000000000000800000001011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 020:10001000000000000010001000000000000000000010001000f00000f000100000000000001000100000100000101010101010104060101000101040506010101100111110003040506010101010101040506030001011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 021:10001000f00000f00010001000b000b000b000b000100010000000130000108000000000001000100000100000000000000010000000001000100000000000101100111110001000000001a00000130000000010001011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 022:10001013000000000010001000000000000000000010001000f00000f0001000000000008010001000001010405060101000104100004110001000f000f000101100111110001013000002000000000000000010801011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 023:100010101010101010100010000000727272000000100010000000000000100000000080001000100000100000000000100010000000001000102300000000101100111110001000000002130000000000000010001011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 024:1000000000000000000000100000007273720000001000101010101010101010101010101010001000001000000080001000100000000010001000f000f000101100111110001000000002000000000013000010001011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 025:103210101010101010101010000000000000000000100000000000100000000000000000001000100000100000000000100010410000411000100000000000101100111110001000001303a00400800000000010001011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 026:10000000000000000000001000b000b000b000b0001010221010003200000000000000000010001000001010405060101000100000000010001000f000f000101100111110003040506010101010701040506030e01011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 027:10101010101010103210001000000000000000000010000000100010000000725272000000100010000010000000000010001010222210100010000000000010110011111013000000000000000000000000e0e0e01011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 028:10b00000000000b000100010101010101010101010100000001000100013000000000000001000100000104100000041100010000000001000100072527200101100111110e0e0101010101010101010101010e0e01011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 029:100000727272000100100010000000000000800000100072001000100000000000000000fd1000100000100000000000100010000000001000102300000000101100111110e0e0e021e0e0e0e0e021e0e0e0e0e0e01011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 030:100000727372000300100001008000725272000000100005001000101010101010101010101000100000100000000000100010101010101000101010101010101100111110e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e01011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 031:10b00000000000b00010000300000000000000000010000000100020000000000000000000000010000010000000000010000000000000000020000000000010110011111021e0e0e0e0e021e0e0e0e0e021e0e0e01011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:101010101010101010101010101010101010101010101010101010101070104050601070101010104060101010101010101010101010101010101010101020101100111110101010101010101010101010101010101011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 033:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 034:100010101010101010101010101010101010101010101010101010101070701010107070101070701010707010101010101010101010101010101010101010101111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 035:100010000000000000000000000000001000000000000000000000001000000000000000100000000000000000000000000000000000001000000000000000101100001111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 036:100010001010101040506010101010001000303030405060303030001000800000000000100010101010101010406010101010101010001000f000f0000000101100000000101010101010101010101010101010101010101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 037:10001000100000000000000000001000100030e0e0e0e0e0e0e030001013000000000000100010000000000000000000000000000010001000000000001000101100000000000000000000000000130000000000000000101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 038:100010001000a00000a00000a0001000100030e0e0e0e0e0e0e030001010101000101010100010001010101010406010101010100010001000f000f0001000101111000000000000000000000000000000000000000000101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 039:10000000100000000000000000001000100030e0e0e0e0e0e0e030001000000000000000100010001080000000000000800000100010001000000000001000101111110000101010101010101010101010405050505060101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 040:101010101010101010101010101010001000303030303030303030001000a0000000a00010001000100000800080000000000010001000104210001042100010111111000010130000000000fee0e01010000000000000101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 041:10000000000000000000000000001000120000000000000000000000100000000000000010001000100080000000008000000010001000100010001000100010111111000410000000000000e0e0e01010405050505060101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 042:10e01010101010101010101010e010101010101010e0e0e010101010101010e0e0e0101010001000101010101040601010101010001000100010001000100010111111000010000000000000e0e0e00113000000000000101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 043:10e0e0e0e0e0e0e0e0e0e0e010e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e010001000000000001000001000000000001000100010001000100010111111000010000000000000e0e0e00200000000000000101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 044:1010101010101010101010e010e010101010101010e0e0e01010101010101010101010e010001010101010101000001010101010101000100010001000100010111111000010000000000000e0e0e00200000000000000101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 045:1000000000000000120010e010e010000000000010e0e0e010e0e0e0e0e0e0e0e0e0e0e01000100000001300000000000000001300100010001000100010001011111100001010221000e0e0e0e0e00200000013000000101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 046:100010001000100010e010e010e01000f000f01310e0e0e010e01010101010101010101010001013000000131000131013000000001000100000000000100010111111130000000010e0e0e0e0e0e00200000000000000101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 047:100010001000100010e0e0e010e010000000000010e0e0e010e010e0e0e0e0e0e0e0e0e010001000130000001000801000001300001000101010421010100010111111000000000010e0e0e0e0e0e00300000000000000101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 048:10001000100010001010101010e010101010e0e010e0e0e010e010e010101010101010e0100010101010101010000010101010101010001000000000001000101111111300000000101010101010101010101010101010101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 049:10001000100010000000000010e0e0e0e0e0e0e010e0e0e010e010e01000000000d010e0100010000000000000000000000000000010001000f000f0001000101111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 050:10001000100010101010100010101010101010e010e0e0e010e010e01013000000c010e010001000f000f0001080001000f000f00010001013000000001000101111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 051:10001000100000000000100000000000000010e010e0e0e010e010e010e0e010101010e0100010000000000010000010000013000010001000f000f0001000101111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 052:10001000101010101000101010701070100010e010e0e0e010e0e0e010e0e0e0e0e0e0e0100010101010101010424210101010100010001000000000131000101111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 053:10001000000010001000000000000000100010e010e0e0e0101010101010101010101010100010001000000000000000000000100010001000000000001000101111111010101010101010101010101010101010101010101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 054:10001010101010001010101010101000100010e010e0e0e01021e0e0e0e01000410041000000100010004100410000410041001000100010101042101010001011111110f01300f010f000f010f000f010000000000000101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 055:10001000000010000000000000000000100010e010e0e0e010e0e0e021e0100000000000101010001010101010101010101010100010101000a000a0001000101111111000ff00001000fd001000fc0010000000000071101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 056:10001000100010101010101010101010100010e010e0e0e010e02110e0e01000f000f0001000000000000000000000000000001000000000130000000010001011111110000000001000000010000000100000000000c0101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 057:10000000100000000000000000100000000010e010e0e0e010e0e010e0e0100000000000101010101010101010101010101010101010101010101010101000101111111013000000101300001013000010000000000000101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 058:10101010101010701070102010101010101010e010e0e0e010e0e010e0211000f000f000100000001300100000000000000010101010101010000000000000101111111010102210101032101010121010104210101010101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 059:10000000000000001313000000100000120010e010e0e0e01021e010e0e01000000000001000000000001000f0000000f00010101010101010000000101010101111111111000000130000001300000000000000000000001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 060:1013800013001300000000000010800010e010e010e0e0e010e0e01021e0100072527200100000000013100000000013000010101010a000000000000000a0101111111100000000000000000000000000000000000000001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 061:1000000000000000000000000010fc0010e0e0e010e0e0e010e02110e0e0100000000000000013000000000000000000000010101010000000725272000000101111111100000000000000000000000000000000000000001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 062:1010e0e0e010101010101010101010101010101010e0e0e010e0e010e021101010101010101010101010101010e0e0e0101010101010a000000000000000a0101111111100000000000011111111110000000000000000001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 063:10e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e010e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0101010100000007252720000001011111111fe000000001111111111111111000000000000001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 064:10e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e010e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e010101010a000000000000000a0101111111111110000111111111111111111110000000004001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 065:101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101111111111111111111111111111111111110000000000001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 066:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 067:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:9ceffffeb853100122468aceeeddcba9
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:a030b050b070b080b080c080c070d050e030b020b030a030a05090609080809080b070c060b060a060906080607070609050a040a030b020c020d010507000000000
-- </SFX>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffea75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>


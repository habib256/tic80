-- title:  Axayacalt Tomb
-- author: VERHILLE Arnaud - gist974@gmail.com
-- desc: Axayacalt's Tomb Port for TIC-80
-- graphics: 24x24 tiles & sprites by Petitjean & Shurder
-- script: Lua

------------- PLAYER AND CO INIT --------------------------
-- player.state : 0->wait // 1->walk // 2->swim
--    // 3->Aim // 4->Jump // 5->Inventory // 6->Dead
player = {x, y, dir, state = 0, life = 10, O2 = 80, greenKey = 0, blueKey = 0, redKey = 0, yellowKey = 0, score = 0}

monsters = nil -- This a Lua Linked List
doors = nil -- This a Lua Linked List
chests = nil -- This a Lua Linked List
camera = {x = 0, y = 0}
input = -1
game = {state = 5, init = -1, time = 0}

-- INIT FROM MAP
-- --------------------
function initFromMap(x1, y1, x2, y2)
  local objTypes = {
    [49] = {list="monsters", props={dir=0}},
    [64] = {list="player", props={dir=-1}},
    [2] = {list="doors", props={color="secret", open=0}},
    [33] = {list="doors", props={color="red", open=0}},
    [34] = {list="doors", props={color="green", open=0}},
    [35] = {list="doors", props={color="blue", open=0}},
    [36] = {list="doors", props={color="yellow", open=0}},
    [20] = {list="chests", props={type="little", inside="score", open=0}},
    [21] = {list="chests", props={type="little", inside="nothing", open=1}},
    [22] = {list="chests", props={type="big", inside="nothing", open=0}}
  }
  for i = x1, x2 do
    for j = y1, y2 do
      local val = peek(0x08000 + i + j * 240)
      local obj = objTypes[val]
      if obj then
        local newObj = {x=i, y=j, next=_G[obj.list]}
        for k,v in pairs(obj.props) do newObj[k] = v end
        if obj.list == "player" then
          for k,v in pairs(newObj) do player[k] = v end
        else
          _G[obj.list] = newObj
        end
      end
    end
  end
end

-- SELECT BASIC LOOP FONCTIONS  --

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

-- CAMERA --

function updateCamera()
  if game.state == 0 then -- Attract Mode Fixed Camera
    camera.x = 72
    camera.y = 8
  else -- Camera Follow the player
    camera.x = player.x - 5
    camera.y = player.y - 2
  end
end

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

-- INTERACTION --

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

-- PLAYER CONTROL --

function updatePlayer()

  if btnp(6) then -- Triangle
    input = 6
    player.state = 5 -- Inventory
    -- if attractmode then run original game
    if game.state == 0 then
      game.state = 1
      game.init = -1
    end
  end

  -- Important!! player speed !
  if game.time % 15 == 0 then

    player.state = 0

    if btn(5) then
      input = 5
      player.state = 3 -- Aiming Cercle
    end

    if btn(4) then
      input = 4
      player.state = 4 -- Jump Croix
    end

    if btn(7) then -- Shoot Button Carre
      input = 7
      player.state = 3 -- Aiming
      if player.dir == 0 then -- Vise vers le haut
        if doorIsOpen(player.x, player.y - 1) then
          chgDoorState(player.x, player.y - 1)
        end
        if chestIsHere(player.x, player.y - 1) then
          chgChestState(player.x, player.y - 1)
        end
      end
      if player.dir == 1 then -- Vise vers le droite
        if doorIsOpen(player.x + 1, player.y) then
          chgDoorState(player.x + 1, player.y)
        end
        if chestIsHere(player.x + 1, player.y) then
          chgChestState(player.x + 1, player.y)
        end
      end
      if player.dir == 2 then -- Vise vers le bas
        if doorIsOpen(player.x, player.y + 1) then
          chgDoorState(player.x, player.y + 1)
        end
        if chestIsHere(player.x, player.y + 1) then
          chgChestState(player.x, player.y + 1)
        end
      end
      if player.dir == 3 then -- Vise vers la gauche
        if doorIsOpen(player.x - 1, player.y) then
          chgDoorState(player.x - 1, player.y)
        end
        if chestIsHere(player.x - 1, player.y) then
          chgChestState(player.x - 1, player.y)
        end
      end

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
      if player.state == 4 then
      else
        player.life = 0
      end
    end
  end -- Wait
end

function playerCanMove(x, y)
  val = mget(x, y)
  if val == 1 or val == 3 or val == 39 or val == 10 or
    val == 11 or val == 12 or val == 23 or val == 15 or
    val == 17 or val == 20 or val == 21 or val == 22 or
    val == 37 or val == 18 then return -1 end

  if val == 2 then -- Secret Door
    if doorIsOpen(x, y) == 0 then
      return -1
    else
      return 1
    end
  end

  if val == 34 then -- Green Door
    if player.greenKey == 0 then
      return -1
    else
      if doorIsOpen(x, y) == 0 then
        return -1
      else
        return 1
      end
    end
  end

  if val == 35 then -- Blue Door      
    if player.blueKey == 0 then
      return -1
    else
      if doorIsOpen(x, y) == 0 then
        return -1
      else
        return 1
      end
    end
  end

  if val == 33 then -- Red Door
    if player.redKey == 0 then
      return -1
    else
      if doorIsOpen(x, y) == 0 then
        return -1
      else
        return 1
      end
    end
  end

  if val == 36 then -- Yellow Door
    if player.yellowKey == 0 then
      return -1
    else
      if doorIsOpen(x, y) == 0 then
        return -1
      else
        return 1
      end
    end

  end

  if player.state == 3 then -- AIMING
    return 0
  else
    if doorIsOpen(x, y) == 0 then
      return -1
    else
      return 1
    end
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

-- DOORS AND CHEST --
function doorIsOpen(x, y)
  local d = doors
  while d do
    if d.x == x and d.y == y then
      if d.open == 1 then
        return 1
      else
        return 0
      end
    end
    d = d.next
  end
end

function chgDoorState(x, y)
  local d = doors
  while d do
    if d.x == x and d.y == y then
      if d.color == "secret" or (player[d.color.."Key"] == 1) then
        d.open = 1 - d.open
        return
      end
    end
    d = d.next
  end
end

-- -------------- CHESTS -------------

function chestIsHere(x, y)
  local c = chests
  while c do
    if c.x == x and c.y == y then return 1 end
    c = c.next
  end
  return 0
end

function chgChestState(x, y)
  local c = chests
  while c do
    if c.x == x and c.y == y then
      if c.open == 0 then
        if c.inside == "life" then
          player.life = player.life + 5
          c.inside = "nothing"
        end
        if c.inside == "score" then
          player.score = player.score + 100
          c.inside = "nothing"
        end

        c.open = 1
      else
        c.open = 0
      end
    end
    c = c.next
  end
end


-- MONSTER AI  --

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
  local blockedTiles = {1,2,3,8,9,10,11,12,14,15,17,18,20,21,22,23,37,39}
  local val = mget(x, y)
  
  if val >= 33 and val <= 36 then
    return doorIsOpen(x, y)
  end
  
  for _, tile in ipairs(blockedTiles) do
    if val == tile then return 0 end
  end
  
  return 1
end

-- DRAWING --

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
    -- Vers la gauche
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

  if player.state == 4 then -- JUMP
    -- En Face
    if player.dir == 0 then
      spr(412, (player.x - camera.x) * 24,
          (player.y - camera.y) * 24 - 2, 15, 1, 0, 0,
          3, 3)
    end
    if player.dir == 1 then
      spr(364, (player.x - camera.x) * 24,
          (player.y - camera.y) * 24 - 2, 15, 1, 0, 0,
          3, 3)
    end
    if player.dir == 2 then
      spr(412, (player.x - camera.x) * 24,
          (player.y - camera.y) * 24 - 2, 15, 1, 0, 0,
          3, 3)
    end
    if player.dir == 3 then
      spr(364, (player.x - camera.x) * 24,
          (player.y - camera.y) * 24 - 2, 15, 1, 1, 0,
          3, 3)
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

-- DRAW MONSTERS

function drawMonsters()
  local m = monsters
  while m do
    local sprite = 352
    local flip = 0
    
    if m.dir == 1 then sprite = 361
    elseif m.dir == 3 then sprite = 358
    else
      sprite = sprite + game.time % 30 // 15 * 3
      flip = m.dir == 2 and 1 or 0
    end
    
    spr(sprite, (m.x - camera.x) * 24, (m.y - camera.y) * 24, 15, 1, flip, 0, 3, 3)
    m = m.next
  end
end

-- DRAW HUD 

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
      -- spr(126, 5 * 24, 3 * 24, 12, 1, 1, 0, 2, 2)
      print(player.score, 5 * 24, 2 * 24 + 16 + 10, 4,
            1, 1)
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

-- DRAW MAP

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
  drawDoors()
  drawChests()
end

function drawDoors()
  local doorColors = {
    green = 239,
    blue = 255, 
    red = 223,
    yellow = 207,
    secret = 2
  }

  local d = doors
  while d do
    if d.open == 0 then
      local keySprite = doorColors[d.color] or 65
      local x = (d.x - camera.x) * 24
      local y = (d.y - camera.y) * 24
      
      spr(211, x, y, -1, 1, 0, 0, 3, 3)
      
      if d.color ~= "secret" then
        spr(keySprite, x + 8, y + 8, -1, 1, 0, 0, 1, 1)
      end
    end
    d = d.next
  end
end

function drawChests()
  local c = chests
  while c do
    local spriteId = c.type == "big" and 185 or (c.open == 0 and 121 or 153)
    local yOffset = c.type == "big" and 7 or 8
    spr(spriteId, (c.x - camera.x) * 24, (c.y - camera.y) * 24 + yOffset, -1, 1, 0, 0, 3, 2)
    if c.type == "big" then return end
    c = c.next
  end
end

-- DRAW SPRITES
-- --------------------------------------------------
function drawMapSprite(val, i, j)
  local sprites = {
    [1] = {65, 0, 0, 3, 3},
    [3] = {68, 0, 0, 3, 3},
    [4] = {{71, 0, 0, 2, 3}, {72, 16, 0, 1, 3}},
    [5] = {{72, 0, 0, 1, 3}, {72, 8, 0, 1, 3}, {72, 16, 0, 1, 3}},
    [6] = {{72, 0, 0, 1, 3}, {72, 8, 0, 2, 3}},
    [7] = {160, 0, 0, 3, 3},
    [8] = {204, 0, 0, 3, 2},
    [9] = {236, 0, 0, 3, 2},
    [10] = {163, 0, 0, 3, 3},
    [11] = {118, 0, 0, 3, 3},
    [12] = {166, 0, 0, 3, 3},
    [13] = {13, 8, 16, 1, 1},
    [14] = {112, 0, 0, 3, 3},
    [15] = {208, 0, 0, 3, 3},
    [17] = {78, 8, 0, 2, 3},
    [16] = {{71, 0, 0, 1, 3, 0, 1}, {72, 0, 8, 1, 3, 0, 1}, {72, 0, 16, 1, 3, 0, 1}},
    [32] = {{72, 0, 0, 1, 3, 0, 1}, {72, 0, 8, 1, 3, 0, 1}, {72, 0, 16, 1, 3, 0, 1}},
    [48] = {{72, 0, 0, 1, 3, 0, 1}, {72, 0, 8, 2, 3, 0, 1}},
    [18] = {115, 0, 0, 3, 3},
    [19] = {470, 0, 0, 3, 3},
    [23] = {126, 4, 8, 2, 2},
    [38] = {{188, 0, 0, 3, 1}, {188, 0, 16, 3, 1, 0, 2}},
    [37] = {{27, -29, 0, 5, 3}, {27, 11, 0, 5, 3, 1, 0}},
    [55] = {{74, -21, -24, 4, 3}, {74, 11, -24, 4, 3, 1, 0}, {124, -15, 0, 2, 3, 1, 0}, {124, 22, 0, 2, 3, 1, 0}},
    [80] = {{172, 5, -16, 2, 1}, {217, 0, 0, 3, 3, 1, 0}}
  }
  
  local keys = {
    [207] = "yellowKey",
    [223] = "redKey",
    [239] = "greenKey",
    [255] = "blueKey"
  }
  
  if sprites[val] then
    for _, s in ipairs(type(sprites[val][1]) == "table" and sprites[val] or {sprites[val]}) do
      spr(s[1], i*24 + (s[2] or 0), j*24 + (s[3] or 0), -1, 1, s[6] or 0, s[7] or 0, s[4], s[5])
    end
  elseif keys[val] and player[keys[val]] == 0 then
    spr(val, i*24 + 8, j*24 + 8, -1, 1, 0, 0, 1, 1)
  elseif game.state == -1 and (val == 49 or val == 64) then
    spr(val == 49 and 352 or 256, i*24, j*24, 15, 1, 0, 0, 3, 3)
    if val == 64 then spr(271, i*24 + 8, j*24 + 4, 15, 1, 0, 0, 1, 1) end
  end
end

-- FONCTIONS UTILITAIRES
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


-- title:  Axayacalt Tomb
-- author: VERHILLE Arnaud - gist974@gmail.com
-- desc: Axayacalt's Tomb Port for TIC-80
-- graphics: 24x24 tiles & sprites by Petitjean & Shurder
-- script: Lua


-- Configuration globale du jeu
GAME_CONFIG = {
    STATES = {
        FLYBY = -1,
        ATTRACT = 0,
        GAME = 1,
        ARENA = 2,
        CAVE = 3,
        KEYS = 4,
        KEYS2 = 5
    },
    PLAYER_STATES = {
        WAIT = 0,
        WALK = 1,
        SWIM = 2,
        AIM = 3,
        JUMP = 4,
        INVENTORY = 5,
        DEAD = 6
    },
    ENTITY_TYPES = {
        MONSTER = "monster",
        DOOR = "door",
        CHEST = "chest"
    }
}

-- Gestionnaire d'entités
EntityManager = {
    entities = {},
    
    create = function(self, type, x, y, properties)
        local entity = {
            type = type,
            x = x,
            y = y,
            properties = properties or {}
        }
        table.insert(self.entities, entity)
        return entity
    end,
    
    findAt = function(self, x, y)
        for _, entity in ipairs(self.entities) do
            if entity.x == x and entity.y == y then
                return entity
            end
        end
        return nil
    end,
    
    remove = function(self, entity)
        for i, e in ipairs(self.entities) do
            if e == entity then
                table.remove(self.entities, i)
                break
            end
        end
    end,
    
    update = function(self)
        for _, entity in ipairs(self.entities) do
            if entity.update then
                entity:update()
            end
        end
    end,
    
    draw = function(self)
        for _, entity in ipairs(self.entities) do
            if entity.draw then
                entity:draw()
            end
        end
    end
}

-- Joueur
player = {
    x = 0,
    y = 0,
    dir = -1,
    state = GAME_CONFIG.PLAYER_STATES.WAIT,
    life = 10,
    O2 = 80,
    greenKey = 0,
    blueKey = 0,
    redKey = 0,
    yellowKey = 0,
    score = 0,
    
    update = function(self)
        -- La logique de mise à jour du joueur sera déplacée ici
    end,
    
    draw = function(self)
        -- La logique de dessin du joueur sera déplacée ici
    end
}

-- Caméra
camera = {
    x = 0,
    y = 0,
    
    update = function(self)
        if game.state == GAME_CONFIG.STATES.ATTRACT then
            self.x = 72
            self.y = 8
        else
            self.x = player.x - 5
            self.y = player.y - 2
        end
    end
}

-- État du jeu
game = {
    state = GAME_CONFIG.STATES.ATTRACT,
    init = -1,
    time = 0,
    
    update = function(self)
        self.time = self.time + 1
    end
}

input = -1

-- -------------------------
-- FONCTIONS PRINCIPALES
-- -------------------------

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
  -- Réinitialiser les entités
  EntityManager.entities = {}
  
  -- Parcourir la zone de la carte spécifiée
  for j = y1, y2 do
    for i = x1, x2 do
      val = mget(i, j)
      if val == 49 then -- MONSTER
        EntityManager:create(GAME_CONFIG.ENTITY_TYPES.MONSTER, i, j, {
          dir = 0,
          move = 0,
          color = 8
        })
      elseif val == 64 then -- PLAYER
        player.x = i
        player.y = j
        player.dir = -1
      elseif val == 2 then -- SECRET WALL
        EntityManager:create(GAME_CONFIG.ENTITY_TYPES.DOOR, i, j, {
          color = "secret",
          open = 0
        })
      elseif val == 33 then -- RED DOOR
        EntityManager:create(GAME_CONFIG.ENTITY_TYPES.DOOR, i, j, {
          color = "red",
          open = 0
        })
      elseif val == 34 then -- GREEN DOOR
        EntityManager:create(GAME_CONFIG.ENTITY_TYPES.DOOR, i, j, {
          color = "green",
          open = 0
        })
      elseif val == 35 then -- BLUE DOOR
        EntityManager:create(GAME_CONFIG.ENTITY_TYPES.DOOR, i, j, {
          color = "blue",
          open = 0
        })
      elseif val == 36 then -- YELLOW DOOR
        EntityManager:create(GAME_CONFIG.ENTITY_TYPES.DOOR, i, j, {
          color = "yellow",
          open = 0
        })
      elseif val == 20 then -- BIG CHEST
        EntityManager:create(GAME_CONFIG.ENTITY_TYPES.CHEST, i, j, {
          type = "big",
          open = 0,
          content = "life"
        })
      elseif val == 21 then -- SMALL CHEST
        EntityManager:create(GAME_CONFIG.ENTITY_TYPES.CHEST, i, j, {
          type = "small",
          open = 0,
          content = "score"
        })
      end
    end
  end
  
  -- Définir une position par défaut pour le joueur en mode Attract
  if game.state == 0 then
    player.x = 75
    player.y = 10
  end
end

----------------------------
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
  -- Collision avec les monstres
  for _, monster in ipairs(EntityManager.entities) do
    if monster.type == GAME_CONFIG.ENTITY_TYPES.MONSTER then
      if monster.x == player.x and monster.y == player.y then
        player.life = player.life - 1
      end
    end
  end

  -- Récupération des clés
  local val = mget(player.x, player.y)
  if val == 239 then -- GREEN KEY
    player.greenKey = 1
  elseif val == 255 then -- BLUE KEY
    player.blueKey = 1
  elseif val == 223 then -- RED KEY
    player.redKey = 1
  elseif val == 207 then -- YELLOW KEY
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
    local door = EntityManager:findAt(x, y)
    if door and door.type == GAME_CONFIG.ENTITY_TYPES.DOOR then
      return door.properties.open and 1 or -1
    end
    return -1
  end

  if val == 33 or val == 34 or val == 35 or val == 36 then
    local door = EntityManager:findAt(x, y)
    if door and door.type == GAME_CONFIG.ENTITY_TYPES.DOOR then
      return door.properties.open and 1 or -1
    end
    return -1
  end

  if player.state == 3 then -- AIMING
    return 0
  else
    local door = EntityManager:findAt(x, y)
    if door and door.type == GAME_CONFIG.ENTITY_TYPES.DOOR then
      return door.properties.open and 1 or -1
    end
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

-- ------------------------------------
-- ---------------- DOORS -------------
-- ------------------------------------

function doorIsOpen(x, y)
  local door = EntityManager:findAt(x, y)
  if door and door.type == GAME_CONFIG.ENTITY_TYPES.DOOR then
    return door.properties.open == 1
  end
  return false
end

function chgDoorState(x, y)
  local door = EntityManager:findAt(x, y)
  if door and door.type == GAME_CONFIG.ENTITY_TYPES.DOOR then
    if door.properties.color == "secret" then
      door.properties.open = door.properties.open == 0 and 1 or 0
    elseif door.properties.color == "green" and player.greenKey == 1 then
      door.properties.open = door.properties.open == 0 and 1 or 0
      player.greenKey = 0
    elseif door.properties.color == "blue" and player.blueKey == 1 then
      door.properties.open = door.properties.open == 0 and 1 or 0
      player.blueKey = 0
    elseif door.properties.color == "red" and player.redKey == 1 then
      door.properties.open = door.properties.open == 0 and 1 or 0
      player.redKey = 0
    elseif door.properties.color == "yellow" and player.yellowKey == 1 then
      door.properties.open = door.properties.open == 0 and 1 or 0
      player.yellowKey = 0
    end
  end
end

-- ------------------------------------
-- -------------- CHESTS -------------
-- ------------------------------------

function chestIsHere(x, y)
  local chest = EntityManager:findAt(x, y)
  return chest and chest.type == GAME_CONFIG.ENTITY_TYPES.CHEST
end

function chgChestState(x, y)
  local chest = EntityManager:findAt(x, y)
  if chest and chest.type == GAME_CONFIG.ENTITY_TYPES.CHEST and not chest.properties.open then
    if chest.properties.content == "life" then
      player.life = player.life + 5
    elseif chest.properties.content == "score" then
      player.score = player.score + 100
    end
    chest.properties.open = true
  end
end

-- ----------------------
-- MONSTERS UPDATE
-- ----------------------
function updateMonster()
  if game.time % 20 == 0 then
    for _, monster in ipairs(EntityManager.entities) do
      if monster.type == GAME_CONFIG.ENTITY_TYPES.MONSTER then
        if monster.properties.dir == 0 then -- UP
          if monsterCanMove(monster.x, monster.y - 1) then
            monster.y = monster.y - 1
          else
            monster.properties.dir = math.random(0, 3)
          end
        elseif monster.properties.dir == 1 then -- RIGHT
          if monsterCanMove(monster.x + 1, monster.y) then
            monster.x = monster.x + 1
          else
            monster.properties.dir = math.random(0, 3)
          end
        elseif monster.properties.dir == 2 then -- DOWN
          if monsterCanMove(monster.x, monster.y + 1) then
            monster.y = monster.y + 1
          else
            monster.properties.dir = math.random(0, 3)
          end
        elseif monster.properties.dir == 3 then -- LEFT
          if monsterCanMove(monster.x - 1, monster.y) then
            monster.x = monster.x - 1
          else
            monster.properties.dir = math.random(0, 3)
          end
        end
      end
    end
  end
end

function monsterCanMove(x, y)
  local val = mget(x, y)
  if val == 1 or val == 3 or val == 39 or val == 10 or
    val == 11 or val == 12 or val == 23 or val == 15 or
    val == 17 or val == 20 or val == 21 or val == 22 or
    val == 37 or val == 18 then 
    return false 
  end

  if val == 2 then -- Secret Door
    return doorIsOpen(x, y)
  end

  if val == 33 or val == 34 or val == 35 or val == 36 then
    return doorIsOpen(x, y)
  end

  return true
end

-- -----------------------------
-- DRAW PLAYER
-- -----------------------------
function drawPlayer()
  -- Si on est en mode flyBy, ne pas dessiner le joueur (déjà dessiné dans drawMapSprite)
  if game.state == -1 then
    return
  end
  
  -- Pour l'écran titre (Attract Mode)
  if game.state == 0 then
    -- Position fixe pour l'écran titre (coordonnées absolues)
    spr(256, 3 * 24, 2 * 24, 15, 1, 0, 0, 3, 3)
    spr(271, 3 * 24 + 8, 2 * 24 + 4, 15, 1, 0, 0, 1, 1)
    return
  end

  -- Pour les autres modes de jeu
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

-- -----------------------------
-- DRAW MONSTERS
-- -----------------------------
-- print(game.time%30//15,75,2*24,10,2,2)

function drawMonsters()
  for _, monster in ipairs(EntityManager.entities) do
    if monster.type == GAME_CONFIG.ENTITY_TYPES.MONSTER then
      if monster.properties.dir == 0 then -- UP
        spr(352 + game.time % 30 // 15 * 3,
            (monster.x - camera.x) * 24,
            (monster.y - camera.y) * 24,
            15, 1, 0, 0, 3, 3)
      elseif monster.properties.dir == 1 then -- RIGHT
        spr(352 + game.time % 30 // 15 * 3,
            (monster.x - camera.x) * 24,
            (monster.y - camera.y) * 24,
            15, 1, 0, 0, 3, 3)
      elseif monster.properties.dir == 2 then -- DOWN
        spr(358,
            (monster.x - camera.x) * 24,
            (monster.y - camera.y) * 24,
            15, 1, 0, 0, 3, 3)
      elseif monster.properties.dir == 3 then -- LEFT
        spr(352 + game.time % 30 // 15 * 3,
            (monster.x - camera.x) * 24,
            (monster.y - camera.y) * 24,
            15, 1, 1, 0, 3, 3)
      end
    end
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
  drawDoors()
  drawChests()
end

function drawDoors()
  for _, door in ipairs(EntityManager.entities) do
    if door.type == GAME_CONFIG.ENTITY_TYPES.DOOR then
      if door.properties.open == 0 then
        if door.properties.color == "secret" then
          -- Secret Wall
          spr(65, (door.x - camera.x) * 24,
              (door.y - camera.y) * 24, -1, 1, 0, 0, 3, 3)
          spr(2, (door.x - camera.x) * 24 + 8,
              (door.y - camera.y) * 24 + 8, -1, 1, 0, 0, 1, 1)
        elseif door.properties.color == "green" then
          spr(211, (door.x - camera.x) * 24,
              (door.y - camera.y) * 24, -1, 1, 0, 0, 3, 3)
          spr(239, (door.x - camera.x) * 24 + 8,
              (door.y - camera.y) * 24 + 8, -1, 1, 0, 0, 1, 1)
        elseif door.properties.color == "blue" then
          spr(211, (door.x - camera.x) * 24,
              (door.y - camera.y) * 24, -1, 1, 0, 0, 3, 3)
          spr(255, (door.x - camera.x) * 24 + 8,
              (door.y - camera.y) * 24 + 8, -1, 1, 0, 0, 1, 1)
        elseif door.properties.color == "red" then
          spr(211, (door.x - camera.x) * 24,
              (door.y - camera.y) * 24, -1, 1, 0, 0, 3, 3)
          spr(223, (door.x - camera.x) * 24 + 8,
              (door.y - camera.y) * 24 + 8, -1, 1, 0, 0, 1, 1)
        elseif door.properties.color == "yellow" then
          spr(211, (door.x - camera.x) * 24,
              (door.y - camera.y) * 24, -1, 1, 0, 0, 3, 3)
          spr(207, (door.x - camera.x) * 24 + 8,
              (door.y - camera.y) * 24 + 8, -1, 1, 0, 0, 1, 1)
        end
      end
    end
  end
end

function drawChests()
  for _, chest in ipairs(EntityManager.entities) do
    if chest.type == GAME_CONFIG.ENTITY_TYPES.CHEST then
      if chest.properties.type == "big" then
        if chest.properties.open then
          spr(185, (chest.x - camera.x) * 24,
              (chest.y - camera.y) * 24 + 7, -1, 1, 0, 0, 3, 2)
        else
          spr(185, (chest.x - camera.x) * 24,
              (chest.y - camera.y) * 24 + 7, -1, 1, 0, 0, 3, 2)
        end
      else
        if chest.properties.open then
          spr(153, (chest.x - camera.x) * 24,
              (chest.y - camera.y) * 24 + 8, -1, 1, 0, 0, 3, 2)
        else
          spr(121, (chest.x - camera.x) * 24,
              (chest.y - camera.y) * 24 + 8, -1, 1, 0, 0, 3, 2)
        end
      end
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
  -- Wall 2 (normal, not secret)
  if val == 3 then
    spr(68, i * 24, j * 24, -1, 1, 0, 0, 3, 3)
  end
  -- Secret Wall (valeur 2) n'est pas dessiné ici, mais dans drawDoors
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

  -- Pretty Statue
  if val == 23 then
    spr(126, i * 24 + 4, j * 24 + 8, -1, 1, 0, 0, 2, 2)
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

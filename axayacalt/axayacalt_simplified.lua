-- title:  Axayacalt Tomb
-- author: VERHILLE Arnaud - gist974@gmail.com
-- desc: Axayacalt's Tomb Port for TIC-80
-- graphics: 24x24 tiles & sprites by Petitjean & Shurder
-- script: Lua

--[[ STRUCTURE PRINCIPALE DU JEU
Ce jeu est un dungeon crawler en vue de dessus avec des éléments d'exploration.
Le joueur se déplace dans différentes salles, résout des puzzles avec des clés,
évite des monstres et collecte des trésors.
]]--

-- États du joueur: 0=attente, 1=marche, 2=nage, 3=viser, 4=saut, 5=inventaire, 6=mort
player = {
  x = 0,          -- Position X sur la carte
  y = 0,          -- Position Y sur la carte
  dir = 0,        -- Direction (0=haut, 1=droite, 2=bas, 3=gauche)
  state = 0,      -- État actuel (voir commentaire ci-dessus)
  life = 10,      -- Points de vie
  O2 = 80,        -- Oxygène pour nager
  greenKey = 0,   -- Clé verte (0=non, 1=oui)
  blueKey = 0,    -- Clé bleue
  redKey = 0,     -- Clé rouge
  yellowKey = 0,  -- Clé jaune
  score = 0       -- Score du joueur
}

-- Structures de données principales (listes chaînées Lua)
monsters = nil    -- Liste des monstres
doors = nil       -- Liste des portes
chests = nil      -- Liste des coffres

-- Variables de contrôle du jeu
camera = {x = 0, y = 0}  -- Position de la caméra
input = -1               -- Entrée utilisateur actuelle
game = {
  state = 0,             -- État du jeu: -1=flyBy, 0=attract, 1-5=différentes cartes
  init = -1,             -- Indicateur d'initialisation
  time = 0               -- Compteur de temps de jeu
}

--[[ FONCTIONS PRINCIPALES ]]--

-- Fonction principale appelée à chaque frame
function TIC()
  game.time = game.time + 1
  
  -- Sélection de la carte à jouer selon l'état du jeu
  if game.state == -1 then flyBy() end                -- Mode libre caméra
  if game.state == 0 then playMap(72, 08, 81, 13) end -- Mode attrait
  if game.state == 1 then playMap(0, 0, 66, 67) end   -- Carte originale
  if game.state == 2 then playMap(66, 16, 87, 33) end -- Arène
  if game.state == 3 then playMap(64, 33, 89, 50) end -- La caverne
  if game.state == 4 then playMap(64, 51, 88, 66) end -- Les clés
  if game.state == 5 then playMap(89, 01, 120, 17) end -- Les clés 2
end

-- Fonction gérant le gameplay sur une carte
-- @param x1,y1,x2,y2: Coordonnées délimitant la zone de carte à charger
function playMap(x1, y1, x2, y2)
  -- Initialisation de la carte si nécessaire
  if game.init == -1 then
    initFromMap(x1, y1, x2, y2)
    game.init = 1
  end
  
  -- Gestion des différents états du jeu
  if player.state == 5 then 
    -- Mode inventaire
    if btnp(6) then -- Triangle pour quitter l'inventaire
      input = 6
      player.state = 0
    end
  else 
    -- Mode jeu normal
    updateMonster()
    updatePlayer()
    updateCamera()
    checkInteraction()
  end

  -- Affichage du jeu
  cls(0)
  drawMap(camera.x, camera.y)
  drawMonsters()
  drawHUD()
  drawPlayer()
end

-- Initialise le jeu à partir des sprites de la carte
-- @param x1,y1,x2,y2: Coordonnées délimitant la zone à analyser
function initFromMap(x1, y1, x2, y2)
  for i = x1, x2 do
    for j = y1, y2 do
      val = peek(0x08000 + i + j * 240)
      
      -- Détection des éléments de jeu basés sur l'ID de sprite
      if val == 49 then -- Monstres
        monsters = {
          next = monsters,
          x = i,
          y = j,
          dir = 0
        }
      elseif val == 64 then -- Position de départ du joueur
        player.x = i
        player.y = j
        player.dir = -1
      elseif val == 2 then -- Mur secret
        doors = {
          next = doors,
          x = i, y = j,
          color = "secret",
          open = 0
        }
      elseif val == 33 then -- Porte rouge
        doors = {
          next = doors,
          x = i, y = j,
          color = "red",
          open = 0
        }
      elseif val == 34 then -- Porte verte
        doors = {
          next = doors, 
          x = i, y = j,
          color = "green",
          open = 0
        }
      elseif val == 35 then -- Porte bleue
        doors = {
          next = doors,
          x = i, y = j,
          color = "blue",
          open = 0
        }
      elseif val == 36 then -- Porte jaune
        doors = {
          next = doors,
          x = i, y = j,
          color = "yellow",
          open = 0
        }
      elseif val == 20 then -- Petit coffre fermé
        chests = {
          next = chests,
          x = i, y = j,
          type = "little",
          inside = "score",
          open = 0
        }
      elseif val == 21 then -- Petit coffre ouvert
        chests = {
          next = chests,
          x = i, y = j,
          type = "little",
          inside = "nothing",
          open = 1
        }
      elseif val == 22 then -- Grand coffre
        chests = {
          next = chests,
          x = i, y = j,
          type = "big",
          inside = "nothing",
          open = 0
        }
      end
    end
  end
end

--[[ EXPLORATION ET INTERACTIONS ]]--

-- Mode caméra libre pour explorer la carte
function flyBy()
  cls(0)
  -- Contrôle de la caméra
  if btn(0) then camera.y = camera.y - 1 end
  if btn(1) then camera.y = camera.y + 1 end
  if btn(2) then camera.x = camera.x - 1 end
  if btn(3) then camera.x = camera.x + 1 end
  
  -- Limites de la caméra
  camera.x = math.max(0, math.min(camera.x, 239))
  camera.y = math.max(0, math.min(camera.y, 135))
  
  -- Affichage
  drawMap(camera.x, camera.y)
  
  -- Affichage des coordonnées
  local c = string.format('(%03i,%03i)', toInt(camera.x), toInt(camera.y))
  rect(0, 0, 52, 8, 0)
  print(c, 0, 0, 12, 1)
end

-- Vérifie les interactions du joueur avec l'environnement
function checkInteraction()
  -- Collision avec les monstres
  local m = monsters
  while m do
    if m.x == player.x and m.y == player.y then
      player.life = player.life - 1
    end
    m = m.next
  end
  
  -- Collecte des clés
  local tile = mget(player.x, player.y)
  if tile == 239 then
    player.greenKey = 1
  elseif tile == 255 then
    player.blueKey = 1
  elseif tile == 223 then
    player.redKey = 1
  elseif tile == 207 then
    player.yellowKey = 1
  end
end

-- Met à jour la position de la caméra
function updateCamera()
  if game.state == 0 then 
    -- Mode attrait: caméra fixe
    camera.x = 72
    camera.y = 8
  else 
    -- Caméra suit le joueur
    camera.x = player.x - 5
    camera.y = player.y - 2
  end
end

-- Vérifie si une case contient de l'eau
-- @return 1 si c'est de l'eau, -1 sinon
function isWater(x, y)
  return mget(x, y) == 14 and 1 or -1
end

--[[ GESTION DU JOUEUR ]]--

-- Met à jour la position et l'état du joueur selon les entrées
function updatePlayer()
  -- Gestion de l'inventaire
  if btnp(6) then -- Triangle
    input = 6
    player.state = 5 -- Inventaire
    
    -- Si mode attrait, lancer le jeu original
    if game.state == 0 then
      game.state = 1
      game.init = -1
    end
  end

  -- Contrôle de la vitesse du joueur
  if game.time % 15 == 0 then
    player.state = 0 -- État par défaut: attente
    
    -- Gestion des différentes actions
    if btn(5) then -- Viser
      input = 5
      player.state = 3
    elseif btn(4) then -- Sauter
      input = 4
      player.state = 4
    elseif btn(7) then -- Tirer/Interagir
      input = 7
      player.state = 3 -- Mode visée
      
      -- Déterminer la case ciblée selon la direction
      local tx, ty = player.x, player.y
      if player.dir == 0 then ty = ty - 1      -- Haut
      elseif player.dir == 1 then tx = tx + 1  -- Droite
      elseif player.dir == 2 then ty = ty + 1  -- Bas
      elseif player.dir == 3 then tx = tx - 1  -- Gauche
      end
      
      -- Interaction avec les portes et coffres
      if doorIsOpen(tx, ty) then chgDoorState(tx, ty) end
      if chestIsHere(tx, ty) then chgChestState(tx, ty) end
    elseif btn(0) then -- Déplacement vers le haut
      input = 0
      player.dir = 0
      if playerCanMove(player.x, player.y - 1) == 1 then
        player.y = player.y - 1
        player.state = 1
      end
    elseif btn(1) then -- Déplacement vers le bas
      input = 1
      player.dir = 2
      if playerCanMove(player.x, player.y + 1) == 1 then
        player.y = player.y + 1
        player.state = 1
      end
    elseif btn(2) then -- Déplacement vers la gauche
      input = 2
      player.dir = 3
      if playerCanMove(player.x - 1, player.y) == 1 then
        player.x = player.x - 1
        player.state = 1
      end
    elseif btn(3) then -- Déplacement vers la droite
      input = 4
      player.dir = 1
      if playerCanMove(player.x + 1, player.y) == 1 then
        player.x = player.x + 1
        player.state = 1
      end
    end

    -- Gestion de la nage et de l'oxygène
    if isWater(player.x, player.y) == 1 then
      player.state = 2 -- État: nage
      if player.O2 == 0 then
        player.life = player.life - 1
      else
        player.O2 = player.O2 - 1
      end
    else
      player.O2 = 300
    end

    -- Détection des pics (mort si non en état de saut)
    if mget(player.x, player.y + 1) == 7 and player.state ~= 4 then
      player.life = 0
    end
  end
end

-- Vérifie si le joueur peut se déplacer vers une case
-- @return 1 si déplacement possible, -1 sinon
function playerCanMove(x, y)
  local val = mget(x, y)
  
  -- Liste des obstacles bloquants
  local obstacles = {1, 3, 39, 10, 11, 12, 23, 15, 17, 20, 21, 22, 37, 18}
  for _, v in ipairs(obstacles) do
    if val == v then return -1 end
  end
  
  -- Vérification des portes spéciales
  if val == 2 then -- Porte secrète
    return doorIsOpen(x, y) == 0 and -1 or 1
  elseif val == 34 then -- Porte verte
    return (player.greenKey == 0 or doorIsOpen(x, y) == 0) and -1 or 1
  elseif val == 35 then -- Porte bleue
    return (player.blueKey == 0 or doorIsOpen(x, y) == 0) and -1 or 1
  elseif val == 33 then -- Porte rouge
    return (player.redKey == 0 or doorIsOpen(x, y) == 0) and -1 or 1
  elseif val == 36 then -- Porte jaune
    return (player.yellowKey == 0 or doorIsOpen(x, y) == 0) and -1 or 1
  end
  
  -- En mode visée, on ne bouge pas
  if player.state == 3 then return 0 end
  
  -- Par défaut, on vérifie juste si une porte est ouverte
  return doorIsOpen(x, y) == 0 and -1 or 1
end

--[[ GESTION DES PORTES ET COFFRES ]]--

-- Vérifie si une porte est ouverte à une position donnée
-- @return 1 si la porte est ouverte, 0 sinon ou si aucune porte
function doorIsOpen(x, y)
  local d = doors
  while d do
    if d.x == x and d.y == y then
      return d.open
    end
    d = d.next
  end
  return 1 -- Si pas de porte, considéré comme "ouvert" (passage libre)
end

-- Change l'état d'une porte (ouverte/fermée)
function chgDoorState(x, y)
  local d = doors
  while d do
    if d.x == x and d.y == y then
      -- Les portes secrètes peuvent toujours s'ouvrir/fermer
      if d.color == "secret" then
        d.open = 1 - d.open -- Bascule 0->1 ou 1->0
        return
      end
      
      -- Pour les autres portes, vérifier si le joueur a la clé
      local hasKey = false
      
      if d.color == "green" and player.greenKey == 1 then hasKey = true
      elseif d.color == "blue" and player.blueKey == 1 then hasKey = true
      elseif d.color == "red" and player.redKey == 1 then hasKey = true
      elseif d.color == "yellow" and player.yellowKey == 1 then hasKey = true
      end
      
      if hasKey then
        d.open = 1 - d.open -- Bascule l'état
        return
      end
    end
    d = d.next
  end
end

-- Vérifie si un coffre est présent à une position donnée
-- @return 1 si un coffre est présent, 0 sinon
function chestIsHere(x, y)
  local c = chests
  while c do
    if c.x == x and c.y == y then return 1 end
    c = c.next
  end
  return 0
end

-- Change l'état d'un coffre (ouvert/fermé) et donne son contenu
function chgChestState(x, y)
  local c = chests
  while c do
    if c.x == x and c.y == y then
      if c.open == 0 then
        -- Donner le contenu du coffre
        if c.inside == "life" then
          player.life = player.life + 5
          c.inside = "nothing"
        elseif c.inside == "score" then
          player.score = player.score + 100
          c.inside = "nothing"
        end
        c.open = 1 -- Ouvrir le coffre
      else
        c.open = 0 -- Fermer le coffre
      end
      return
    end
    c = c.next
  end
end

--[[ GESTION DES MONSTRES ]]--

-- Met à jour la position des monstres
function updateMonster()
  -- Mise à jour moins fréquente que le joueur
  if game.time % 20 ~= 0 then return end
  
  local m = monsters
  while m do
    -- Essaie de continuer dans la direction actuelle
    local moved = false
    local tx, ty = m.x, m.y
    
    -- Calcul de la nouvelle position selon la direction
    if m.dir == 0 then tx = tx + 1     -- Droite
    elseif m.dir == 1 then ty = ty - 1 -- Haut
    elseif m.dir == 2 then tx = tx - 1 -- Gauche
    elseif m.dir == 3 then ty = ty + 1 -- Bas
    end
    
    -- Tente de se déplacer
    if monsterCanMove(tx, ty) == 1 then
      m.x, m.y = tx, ty
      moved = true
    end
    
    -- Si blocage, change de direction aléatoirement
    if not moved then
      m.dir = toInt(math.random(0, 3))
    end
    
    m = m.next
  end
end

-- Vérifie si un monstre peut se déplacer vers une case
-- @return 1 si déplacement possible, 0 sinon
function monsterCanMove(x, y)
  local val = mget(x, y)
  
  -- Liste des obstacles pour les monstres
  local obstacles = {1, 2, 3, 8, 9, 39, 10, 11, 12, 23, 15, 17, 20, 21, 22, 37, 18, 14}
  for _, v in ipairs(obstacles) do
    if val == v then return 0 end
  end
  
  -- Les portes sont des obstacles sauf si ouvertes
  if val >= 33 and val <= 36 then
    return doorIsOpen(x, y)
  end
  
  return 1 -- Par défaut, déplacement possible
end

--[[ AFFICHAGE DU JOUEUR ]]--

-- Dessine le joueur selon son état et sa direction
function drawPlayer()
  -- Coordonnées d'affichage (position relative à la caméra)
  local px = (player.x - camera.x) * 24
  local py = (player.y - camera.y) * 24
  
  if player.state == 0 then -- État: attente
    -- Joueur de face
    spr(256, px, py, 15, 1, 0, 0, 3, 3)
    spr(271, px + 8, py + 4, 15, 1, 0, 0, 1, 1)
  
  elseif player.state == 1 then -- État: marche
    -- Animation de marche (alterne entre deux frames)
    local anim = game.time % 30 // 15 * 3
    
    if player.dir == -1 or player.dir == 0 or player.dir == 2 then
      -- Vers le haut ou bas (même sprite mais orientation différente)
      spr(304 + anim, px, py, 15, 1, 0, 0, 3, 3)
      -- Ajoute le visage pour la direction bas
      if player.dir == 2 then 
        spr(271, px + 8, py + 4, 15, 1, 0, 0, 1, 1)
      end
    elseif player.dir == 1 then -- Vers la droite
      spr(259 + anim, px, py, 15, 1, 0, 0, 3, 3)
    elseif player.dir == 3 then -- Vers la gauche
      spr(259 + anim, px, py, 15, 1, 1, 0, 3, 3) -- Miroir horizontal
    end
  
  elseif player.state == 2 then -- État: nage
    local anim = game.time % 30 // 15 * 3
    
    if player.dir == -1 then -- Orientation par défaut
      spr(265 + anim, px, py, 15, 1, 0, 0, 3, 3)
      spr(271, px + 9, py + 3 + game.time % 30 // 15, 15, 1, 0, 0, 1, 1)
    elseif player.dir >= 0 then -- Orientation spécifique
      spr(265 + anim, px, py, 15, 1, 0, player.dir, 3, 3)
    end
  
  elseif player.state == 3 then -- État: visée
    if player.dir == -1 then -- Par défaut
      spr(256, px, py, 15, 1, 0, 0, 3, 3)
      spr(271, px + 8, py + 4, 15, 1, 0, 0, 1, 1)
    elseif player.dir == 0 then -- Visée haut
      spr(313, px, py, 15, 1, 0, 0, 3, 3)
    elseif player.dir == 1 then -- Visée droite
      spr(310, px, py, 15, 1, 0, 0, 3, 3)
    elseif player.dir == 2 then -- Visée bas
      spr(316, px, py, 15, 1, 0, 0, 3, 3)
    elseif player.dir == 3 then -- Visée gauche
      spr(310, px, py, 15, 1, 1, 0, 3, 3)
    end
  
  elseif player.state == 4 then -- État: saut
    if player.dir == 0 or player.dir == 2 then -- Haut/Bas
      spr(412, px, py - 2, 15, 1, 0, 0, 3, 3)
    elseif player.dir == 1 then -- Droite
      spr(364, px, py - 2, 15, 1, 0, 0, 3, 3)
    elseif player.dir == 3 then -- Gauche
      spr(364, px, py - 2, 15, 1, 1, 0, 3, 3)
    end
  
  elseif player.state == 5 then -- État: inventaire
    -- Affiche le joueur dans l'inventaire
    spr(256, 3 * 24, py, 15, 1, 0, 0, 3, 3)
    spr(271, 3 * 24 + 8, py + 4, 15, 1, 0, 0, 1, 1)
  end
end

--[[ AFFICHAGE DES MONSTRES ET ÉLÉMENTS DE JEU ]]--

-- Dessine tous les monstres
function drawMonsters()
  local m = monsters
  while m do
    local mx = (m.x - camera.x) * 24
    local my = (m.y - camera.y) * 24
    local anim = game.time % 30 // 15 * 3
    
    if m.dir == -1 or m.dir == 0 then -- Par défaut ou droite
      spr(352 + anim, mx, my, 15, 1, 0, 0, 3, 3)
    elseif m.dir == 1 then -- Haut
      spr(361, mx, my, 15, 1, 0, 0, 3, 3)
    elseif m.dir == 2 then -- Gauche
      spr(352 + anim, mx, my, 15, 1, 1, 0, 3, 3)
    elseif m.dir == 3 then -- Bas
      spr(358, mx, my, 15, 1, 0, 0, 3, 3)
    end
    
    m = m.next
  end
end

-- Dessine l'interface utilisateur
function drawHUD()
  if game.state == 0 then 
    -- Mode attrait: titre du jeu
    print("Axayacalt's", 75, 1 * 24 + 6, 10, 2, 2)
    print("Tomb", 125, 2 * 24, 10, 2, 2)
    print("A TIC-80 game by gist974", 50, 5 * 24 + 2, 1, 1, 1)
    print("Graphics: Petitjean & Shurder", 35, 5 * 24 + 10, 1, 1, 1)
  else 
    -- Interface en jeu
    if player.state == 5 then 
      -- Mode inventaire
      rect(2 * 24, 1 * 24, 5 * 24, 3 * 24, 8) -- Fond
      rectb(2 * 24, 1 * 24, 5 * 24, 3 * 24, 12) -- Bordure
      
      -- Affichage de la vie
      rect(2 * 24 + 12, 1 * 24 + 8, 19, 7, 1)
      spr(26, 2 * 24 + 6, 1 * 24 + 8, 15, 1, 0, 0, 1, 1)
      print(player.life, 2 * 24 + 16, 1 * 24 + 9, 12, 1, 1)
      
      -- Affichage de l'oxygène
      rect(3 * 24 + 18, 1 * 24 + 8, 24, 7, 1)
      spr(25, 3 * 24 + 12, 1 * 24 + 8, 15, 1, 0, 0, 1, 1)
      print(player.O2, 3 * 24 + 22, 1 * 24 + 9, 12, 1, 1)
      
      -- Affichage des clés
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
      
      -- Affichage de l'or
      print("Gold", 5 * 24, 2 * 24 + 14, 12, 1, 1)
      print(player.score, 5 * 24, 2 * 24 + 16 + 10, 4, 1, 1)
    else
      -- HUD minimal en jeu
      rect(211, 3, 19, 7, 1)
      spr(26, 208, 2, 15, 1, 0, 0, 1, 1)
      print(player.life, 218, 4, 12, 1, 1)
      
      -- Affiche l'oxygène uniquement en nageant
      if player.state == 2 then
        rect(211, 13, 25, 7, 1)
        spr(25, 208, 12, 15, 1, 0, 0, 1, 1)
        print(player.O2, 218, 14, 12, 1, 1)
      end
    end
  end
end

-- Dessine les portes sur la carte
function drawDoors()
  local d = doors
  while d do
    -- N'affiche que les portes fermées
    if d.open == 0 then
      local dx = (d.x - camera.x) * 24
      local dy = (d.y - camera.y) * 24
      
      -- Base de porte
      spr(211, dx, dy, -1, 1, 0, 0, 3, 3)
      
      -- Affiche le symbole correspondant à la couleur
      if d.color == "green" then
        spr(239, dx + 8, dy + 8, -1, 1, 0, 0, 1, 1)
      elseif d.color == "blue" then
        spr(255, dx + 8, dy + 8, -1, 1, 0, 0, 1, 1)
      elseif d.color == "red" then
        spr(223, dx + 8, dy + 8, -1, 1, 0, 0, 1, 1)
      elseif d.color == "yellow" then
        spr(207, dx + 8, dy + 8, -1, 1, 0, 0, 1, 1)
      elseif d.color == "secret" then
        -- Mur secret
        spr(65, dx, dy, -1, 1, 0, 0, 3, 3)
        spr(2, dx + 8, dy + 8, -1, 1, 0, 0, 1, 1)
      end
    end
    d = d.next
  end
end

-- Dessine les coffres sur la carte
function drawChests()
  local c = chests
  while c do
    local cx = (c.x - camera.x) * 24
    local cy = (c.y - camera.y) * 24
    
    if c.type == "big" then
      -- Grand coffre
      spr(185, cx, cy + 7, -1, 1, 0, 0, 3, 2)
    else
      -- Petit coffre (fermé ou ouvert)
      if c.open == 0 then
        spr(121, cx, cy + 8, -1, 1, 0, 0, 3, 2)
      else
        spr(153, cx, cy + 8, -1, 1, 0, 0, 3, 2)
      end
    end
    c = c.next
  end
end

--[[ AFFICHAGE DE LA CARTE ]]--

-- Dessine la carte visible à l'écran
-- @param x,y: Position de la caméra
function drawMap(x, y)
  x, y = toInt(x), toInt(y)
  
  -- Dessine une grille 10x6 de sprites
  for i = 0, 9 do
    for j = 0, 5 do
      -- Calcule la position dans la carte TIC-80
      local mapX, mapY = i + x, j + y
      
      -- Récupère l'ID du sprite à cette position
      local val = 17 -- Par défaut: arbre (hors limites)
      if mapX >= 0 and mapX <= 239 and mapY >= 0 and mapY <= 135 then
        val = peek(0x08000 + mapX + mapY * 240)
      end
      
      -- Dessine le sprite correspondant
      drawMapSprite(val, i, j)
    end
  end
  
  -- Dessine les éléments interactifs par-dessus
  drawDoors()
  drawChests()
end

-- Dessine un sprite spécifique à la position donnée
-- @param val: ID du sprite à dessiner
-- @param i,j: Position relative sur l'écran
function drawMapSprite(val, i, j)
  local x, y = i * 24, j * 24
  
  -- Murs
  if val == 1 then
    spr(65, x, y, -1, 1, 0, 0, 3, 3)
  elseif val == 3 then
    spr(68, x, y, -1, 1, 0, 0, 3, 3)
  
  -- Escaliers
  elseif val == 4 then -- Escaliers gauche
    spr(71, x, y, -1, 1, 0, 0, 2, 3)
    spr(72, x + 16, y, -1, 1, 0, 0, 1, 3)
  elseif val == 5 then -- Escaliers centre
    spr(72, x, y, -1, 1, 0, 0, 1, 3)
    spr(72, x + 8, y, -1, 1, 0, 0, 1, 3)
    spr(72, x + 16, y, -1, 1, 0, 0, 1, 3)
  elseif val == 6 then -- Escaliers droite
    spr(72, x, y, -1, 1, 0, 0, 1, 3)
    spr(72, x + 8, y, -1, 1, 0, 0, 2, 3)
  elseif val == 16 then -- Escaliers verticaux haut
    spr(71, x, y, -1, 1, 0, 1, 1, 3)
    spr(72, x, y + 8, -1, 1, 0, 1, 1, 3)
    spr(72, x, y + 16, -1, 1, 0, 1, 1, 3)
  elseif val == 32 then -- Escaliers verticaux milieu
    spr(72, x, y, -1, 1, 0, 1, 1, 3)
    spr(72, x, y + 8, -1, 1, 0, 1, 1, 3)
    spr(72, x, y + 16, -1, 1, 0, 1, 1, 3)
  elseif val == 48 then -- Escaliers verticaux bas
    spr(72, x, y, -1, 1, 0, 1, 1, 3)
    spr(72, x, y + 8, -1, 1, 0, 1, 2, 3)
    
  -- Pièges et décorations
  elseif val == 7 then -- Pics
    spr(160, x, y, -1, 1, 0, 0, 3, 3)
  elseif val == 8 then -- Petit crâne
    spr(204, x, y, -1, 1, 0, 0, 3, 2)
  elseif val == 9 then -- Grand crâne
    spr(236, x, y, -1, 1, 0, 0, 3, 2)
  elseif val == 10 then -- Statue aztèque
    spr(163, x, y, -1, 1, 0, 0, 3, 3)
  elseif val == 11 then -- Statue étrange
    spr(118, x, y, -1, 1, 0, 0, 3, 3)
  elseif val == 12 then -- Piédestal
    spr(166, x, y, -1, 1, 0, 0, 3, 3)
  elseif val == 13 then -- Livre
    spr(13, x + 8, y + 16, -1, 1, 0, 0, 1, 1)
  elseif val == 14 then -- Eau
    spr(112, x, y, -1, 1, 0, 0, 3, 3)
  elseif val == 15 then -- Pilier
    spr(208, x, y, -1, 1, 0, 0, 3, 3)
  elseif val == 17 then -- Arbre
    spr(78, x + 8, y, -1, 1, 0, 0, 2, 3)
  elseif val == 18 then -- Mine
    spr(115, x, y, -1, 1, 0, 0, 3, 3)
  elseif val == 19 then -- Rocher
    spr(470, x, y, -1, 1, 0, 0, 3, 3)
  elseif val == 23 then -- Belle statue
    spr(126, x + 4, y + 8, -1, 1, 0, 0, 2, 2)
  
  -- Éléments du vaisseau
  elseif val == 38 then -- Chemin vaisseau
    spr(188, x, y, -1, 1, 0, 0, 3, 1)
    spr(188, x, y + 16, -1, 1, 0, 2, 3, 1)
  elseif val == 37 then -- Grand bureau
    spr(27, x - 32 + 3, y, -1, 1, 0, 0, 5, 3)
    spr(27, x + 8 + 3, y, -1, 1, 1, 0, 5, 3)
  elseif val == 80 then -- Contrôle vaisseau
    spr(172, x + 5, y - 24 + 8, -1, 1, 0, 0, 2, 1)
    spr(217, x, y, -1, 1, 1, 0, 3, 3)
  elseif val == 55 then -- Grande arche
    spr(74, x - 24 + 3, y - 24, -1, 1, 0, 0, 4, 3)
    spr(74, x + 11, y - 24, -1, 1, 1, 0, 4, 3)
    spr(124, x - 15, y, -1, 1, 1, 0, 2, 3)
    spr(124, x + 22, y, -1, 1, 1, 0, 2, 3)
    
  -- Clés (affichées seulement si pas collectées)
  elseif val == 207 and player.yellowKey == 0 then -- Clé jaune
    spr(val, x + 8, y + 8, -1, 1, 0, 0, 1, 1)
  elseif val == 223 and player.redKey == 0 then -- Clé rouge
    spr(val, x + 8, y + 8, -1, 1, 0, 0, 1, 1)
  elseif val == 239 and player.greenKey == 0 then -- Clé verte
    spr(val, x + 8, y + 8, -1, 1, 0, 0, 1, 1)
  elseif val == 255 and player.blueKey == 0 then -- Clé bleue
    spr(val, x + 8, y + 8, -1, 1, 0, 0, 1, 1)
  end
  
  -- En mode flyBy uniquement, affiche aussi les personnages statiques
  if game.state == -1 then
    if val == 49 then -- Gobelin statique
      spr(352, x, y, 15, 1, 0, 0, 3, 3)
    elseif val == 64 then -- Joueur statique
      spr(256, x, y, 15, 1, 0, 0, 3, 3)
      spr(271, x + 8, y + 4, 15, 1, 0, 0, 1, 1)
    end
  end
end

--[[ FONCTIONS UTILITAIRES ]]--

-- Convertit un nombre en entier en tronquant la partie décimale
function toInt(n)
  local s = tostring(n)
  local i, j = s:find('%.')
  if i then
    return tonumber(s:sub(1, i - 1))
  else
    return n
  end
end

-- Interpolation linéaire entre deux valeurs
-- @param a,b: Valeurs de départ et d'arrivée
-- @param mu: Facteur d'interpolation (0-1)
function lerp(a, b, mu) 
  return a * (1 - mu) + b * mu 
end

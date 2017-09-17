-- This file contains all barebones-registered events and has already set up the passed-in parameters for your use.
-- Do not remove the GameMode:_Function calls in these events as it will mess with the internal barebones systems.

-- Cleanup a player when they leave
function GameMode:OnDisconnect(keys)
  DebugPrint('[BAREBONES] Player Disconnected ' .. tostring(keys.userid))
  DebugPrintTable(keys)

  local name = keys.name
  local networkid = keys.networkid
  local reason = keys.reason
  local userid = keys.userid

end
-- The overall game state has changed
function GameMode:OnGameRulesStateChange()
  local nNewState = GameRules:State_Get()
  --print( "OnGameRulesStateChange: " .. nNewState )

  if nNewState == DOTA_GAMERULES_STATE_HERO_SELECTION then

  end

  if nNewState == DOTA_GAMERULES_STATE_PRE_GAME then
    local numberOfPlayers = PlayerResource:GetPlayerCount()
    if numberOfPlayers > 7 then
      --self.TEAM_KILLS_TO_WIN = 25
      nCOUNTDOWNTIMER = 901
    elseif numberOfPlayers > 4 and numberOfPlayers <= 7 then
      --self.TEAM_KILLS_TO_WIN = 20
      nCOUNTDOWNTIMER = 721
    else
      --self.TEAM_KILLS_TO_WIN = 15
      nCOUNTDOWNTIMER = 601
    end
    
    self.TEAM_KILLS_TO_WIN = 35

    --print( "Kills to win = " .. tostring(self.TEAM_KILLS_TO_WIN) )

    CustomNetTables:SetTableValue( "game_state", "victory_condition", { kills_to_win = self.TEAM_KILLS_TO_WIN } );

    self._fPreGameStartTime = GameRules:GetGameTime()
  end

  if nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    --print( "OnGameRulesStateChange: Game In Progress" )
    self.countdownEnabled = true
    CustomGameEventManager:Send_ServerToAllClients( "show_timer", {} )
    DoEntFire( "center_experience_ring_particles", "Start", "0", 0, self, self  )
  end
end

-- An NPC has spawned somewhere in game.  This includes heroes
function GameMode:OnNPCSpawned( event )
  local spawnedUnit = EntIndexToHScript( event.entindex )
  if spawnedUnit:IsRealHero() then
    -- Destroys the last hit effects
    local deathEffects = spawnedUnit:Attribute_GetIntValue( "effectsID", -1 )
    if deathEffects ~= -1 then
      ParticleManager:DestroyParticle( deathEffects, true )
      spawnedUnit:DeleteAttribute( "effectsID" )
    end
    if self.allSpawned == false then
      if GetMapName() == "free_for_all" then
        --print("mines_trio is the map")
        --print("self.allSpawned is " .. tostring(self.allSpawned) )
        local unitTeam = spawnedUnit:GetTeam()
        local particleSpawn = ParticleManager:CreateParticleForTeam( "particles/addons_gameplay/player_deferred_light.vpcf", PATTACH_ABSORIGIN, spawnedUnit, unitTeam )
        ParticleManager:SetParticleControlEnt( particleSpawn, PATTACH_ABSORIGIN, spawnedUnit, PATTACH_ABSORIGIN, "attach_origin", spawnedUnit:GetAbsOrigin(), true )
      end
    end
  end
end

-- An entity somewhere has been hurt.  This event fires very often with many units so don't do too many expensive
-- operations here
function GameMode:OnEntityHurt(keys)
  --DebugPrint("[BAREBONES] Entity Hurt")
  --DebugPrintTable(keys)

  local damagebits = keys.damagebits -- This might always be 0 and therefore useless
  if keys.entindex_attacker ~= nil and keys.entindex_killed ~= nil then
    local entCause = EntIndexToHScript(keys.entindex_attacker)
    local entVictim = EntIndexToHScript(keys.entindex_killed)

    -- The ability/item used to damage, or nil if not damaged by an item/ability
    local damagingAbility = nil

    if keys.entindex_inflictor ~= nil then
      damagingAbility = EntIndexToHScript( keys.entindex_inflictor )
    end
  end
end

-- An item was picked up off the ground
function GameMode:OnItemPickUp( event )
  local item = EntIndexToHScript( event.ItemEntityIndex )
  local owner = EntIndexToHScript( event.HeroEntityIndex )
  r = 300
  --r = RandomInt(200, 400)
  if event.itemname == "item_bag_of_gold" then
    --print("Bag of gold picked up")
    PlayerResource:ModifyGold( owner:GetPlayerID(), r, true, 0 )
    SendOverheadEventMessage( owner, OVERHEAD_ALERT_GOLD, owner, r, nil )
    UTIL_Remove( item ) -- otherwise it pollutes the player inventory
  elseif event.itemname == "item_treasure_chest" then
    --print("Special Item Picked Up")
    DoEntFire( "item_spawn_particle_" .. self.itemSpawnIndex, "Stop", "0", 0, self, self )
    GameMode:SpecialItemAdd( event )
    UTIL_Remove( item ) -- otherwise it pollutes the player inventory
  end
end

-- An item was picked up off the ground
function GameMode:OnItemPickedUp( event )

end

-- A player has reconnected to the game.  This function can be used to repaint Player-based particles or change
-- state as necessary
function GameMode:OnPlayerReconnect(keys)
  DebugPrint( '[BAREBONES] OnPlayerReconnect' )
  DebugPrintTable(keys) 
end

-- An item was purchased by a player
function GameMode:OnItemPurchased( keys )
  DebugPrint( '[BAREBONES] OnItemPurchased' )
  DebugPrintTable(keys)

  -- The playerID of the hero who is buying something
  local plyID = keys.PlayerID
  if not plyID then return end

  -- The name of the item purchased
  local itemName = keys.itemname 
  
  -- The cost of the item purchased
  local itemcost = keys.itemcost
  
end

-- An ability was used by a player
function GameMode:OnAbilityUsed(keys)
  DebugPrint('[BAREBONES] AbilityUsed')
  DebugPrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local abilityname = keys.abilityname
end

-- A non-player entity (necro-book, chen creep, etc) used an ability
function GameMode:OnNonPlayerUsedAbility(keys)
  DebugPrint('[BAREBONES] OnNonPlayerUsedAbility')
  DebugPrintTable(keys)

  local abilityname=  keys.abilityname
end

-- A player changed their name
function GameMode:OnPlayerChangedName(keys)
  DebugPrint('[BAREBONES] OnPlayerChangedName')
  DebugPrintTable(keys)

  local newName = keys.newname
  local oldName = keys.oldName
end

-- A player leveled up an ability
function GameMode:OnPlayerLearnedAbility( keys)
  DebugPrint('[BAREBONES] OnPlayerLearnedAbility')
  DebugPrintTable(keys)

  local player = EntIndexToHScript(keys.player)
  local abilityname = keys.abilityname
end

-- A channelled ability finished by either completing or being interrupted
function GameMode:OnAbilityChannelFinished(keys)
  DebugPrint('[BAREBONES] OnAbilityChannelFinished')
  DebugPrintTable(keys)

  local abilityname = keys.abilityname
  local interrupted = keys.interrupted == 1
end

-- A player leveled up
function GameMode:OnPlayerLevelUp(keys)
  DebugPrint('[BAREBONES] OnPlayerLevelUp')
  DebugPrintTable(keys)

  local player = EntIndexToHScript(keys.player)
  local level = keys.level
end

-- A player last hit a creep, a tower, or a hero
function GameMode:OnLastHit(keys)
  DebugPrint('[BAREBONES] OnLastHit')
  DebugPrintTable(keys)

  local isFirstBlood = keys.FirstBlood == 1
  local isHeroKill = keys.HeroKill == 1
  local isTowerKill = keys.TowerKill == 1
  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local killedEnt = EntIndexToHScript(keys.EntKilled)
end

-- A tree was cut down by tango, quelling blade, etc
function GameMode:OnTreeCut(keys)
  DebugPrint('[BAREBONES] OnTreeCut')
  DebugPrintTable(keys)

  local treeX = keys.tree_x
  local treeY = keys.tree_y
end

-- A rune was activated by a player
function GameMode:OnRuneActivated (keys)
  DebugPrint('[BAREBONES] OnRuneActivated')
  DebugPrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local rune = keys.rune

  --[[ Rune Can be one of the following types
  DOTA_RUNE_DOUBLEDAMAGE
  DOTA_RUNE_HASTE
  DOTA_RUNE_HAUNTED
  DOTA_RUNE_ILLUSION
  DOTA_RUNE_INVISIBILITY
  DOTA_RUNE_BOUNTY
  DOTA_RUNE_MYSTERY
  DOTA_RUNE_RAPIER
  DOTA_RUNE_REGENERATION
  DOTA_RUNE_SPOOKY
  DOTA_RUNE_TURBO
  ]]
end

-- A player took damage from a tower
function GameMode:OnPlayerTakeTowerDamage(keys)
  DebugPrint('[BAREBONES] OnPlayerTakeTowerDamage')
  DebugPrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local damage = keys.damage
end

-- A player picked a hero
function GameMode:OnPlayerPickHero(keys)
  DebugPrint('[BAREBONES] OnPlayerPickHero')
  DebugPrintTable(keys)

  local heroClass = keys.hero
  local heroEntity = EntIndexToHScript(keys.heroindex)
  local player = EntIndexToHScript(keys.player)
end

-- A player killed another player in a multi-team context
function GameMode:OnTeamKillCredit( event )
--  print( "OnKillCredit" )
--  DeepPrint( event )

  local nKillerID = event.killer_userid
  local nTeamID = event.teamnumber
  local nTeamKills = event.herokills
  print(nTeamKills)
  local nKillsRemaining = self.TEAM_KILLS_TO_WIN - nTeamKills
  
  local broadcast_kill_event =
  {
    killer_id = event.killer_userid,
    team_id = event.teamnumber,
    team_kills = nTeamKills,
    kills_remaining = nKillsRemaining,
    victory = 0,
    close_to_victory = 0,
    very_close_to_victory = 0,
  }

  if nKillsRemaining <= 0 then
    GameRules:SetCustomVictoryMessage( self.m_VictoryMessages[nTeamID] )
    GameRules:SetGameWinner( nTeamID )
    broadcast_kill_event.victory = 1
  elseif nKillsRemaining == 1 then
    EmitGlobalSound( "ui.npe_objective_complete" )
    broadcast_kill_event.very_close_to_victory = 1
  elseif nKillsRemaining <= self.CLOSE_TO_VICTORY_THRESHOLD then
    EmitGlobalSound( "ui.npe_objective_given" )
    broadcast_kill_event.close_to_victory = 1
  end

  CustomGameEventManager:Send_ServerToAllClients( "kill_event", broadcast_kill_event )
end

-- -- An entity died
-- function GameMode:OnEntityKilled( event )
--   local killedUnit = EntIndexToHScript( event.entindex_killed )
--   local killedTeam = killedUnit:GetTeam()
--   local hero = EntIndexToHScript( event.entindex_attacker )
--   local heroTeam = hero:GetTeam()
--   local extraTime = 0
--   if killedUnit:IsRealHero() then
--     self.allSpawned = true
--     --print("Hero has been killed")
--     --Add extra time if killed by Necro Ult
--     if hero:IsRealHero() == true then
--       if event.entindex_inflictor ~= nil then
--         local inflictor_index = event.entindex_inflictor
--         if inflictor_index ~= nil then
--           local ability = EntIndexToHScript( event.entindex_inflictor )
--           if ability ~= nil then
--             if ability:GetAbilityName() ~= nil then
--               if ability:GetAbilityName() == "necrolyte_reapers_scythe" then
--                 print("Killed by Necro Ult")
--                 extraTime = 20
--               end
--             end
--           end
--         end
--       end
--     end
--     if hero:IsRealHero() and heroTeam ~= killedTeam then
--       --print("Granting killer xp")
--       if killedUnit:GetTeam() == self.leadingTeam and self.isGameTied == false then
--         local memberID = hero:GetPlayerID()
--         PlayerResource:ModifyGold( memberID, 500, true, 0 )
--         hero:AddExperience( 100, 0, false, false )
--         local name = hero:GetClassname()
--         local victim = killedUnit:GetClassname()
--         local kill_alert =
--           {
--             hero_id = hero:GetClassname()
--           }
--         CustomGameEventManager:Send_ServerToAllClients( "kill_alert", kill_alert )
--       else
--         hero:AddExperience( 50, 0, false, false )
--       end
--     end
--     --Granting XP to all heroes who assisted
--     local allHeroes = HeroList:GetAllHeroes()
--     for _,attacker in pairs( allHeroes ) do
--       --print(killedUnit:GetNumAttackers())
--       for i = 0, killedUnit:GetNumAttackers() - 1 do
--         if attacker == killedUnit:GetAttacker( i ) then
--           --print("Granting assist xp")
--           attacker:AddExperience( 25, 0, false, false )
--         end
--       end
--     end
--     if killedUnit:GetRespawnTime() > 10 then
--       --print("Hero has long respawn time")
--       if killedUnit:IsReincarnating() == true then
--         --print("Set time for Wraith King respawn disabled")
--         return nil
--       else
--         GameMode:SetRespawnTime( killedTeam, killedUnit, extraTime )
--       end
--     else
--       GameMode:SetRespawnTime( killedTeam, killedUnit, extraTime )
--     end
--   end
-- end



-- This function is called 1 to 2 times as the player connects initially but before they 
-- have completely connected
function GameMode:PlayerConnect(keys)
  DebugPrint('[BAREBONES] PlayerConnect')
  DebugPrintTable(keys)
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function GameMode:OnConnectFull(keys)
  DebugPrint('[BAREBONES] OnConnectFull')
  DebugPrintTable(keys)

  GameMode:_OnConnectFull(keys)
  
  local entIndex = keys.index+1
  -- The Player entity of the joining user
  local ply = EntIndexToHScript(entIndex)
  
  -- The Player ID of the joining player
  local playerID = ply:GetPlayerID()
end

-- This function is called whenever illusions are created and tells you which was/is the original entity
function GameMode:OnIllusionsCreated(keys)
  DebugPrint('[BAREBONES] OnIllusionsCreated')
  DebugPrintTable(keys)

  local originalEntity = EntIndexToHScript(keys.original_entindex)
end

-- This function is called whenever an item is combined to create a new item
function GameMode:OnItemCombined(keys)
  DebugPrint('[BAREBONES] OnItemCombined')
  DebugPrintTable(keys)

  -- The playerID of the hero who is buying something
  local plyID = keys.PlayerID
  if not plyID then return end
  local player = PlayerResource:GetPlayer(plyID)

  -- The name of the item purchased
  local itemName = keys.itemname 
  
  -- The cost of the item purchased
  local itemcost = keys.itemcost
end

-- This function is called whenever an ability begins its PhaseStart phase (but before it is actually cast)
function GameMode:OnAbilityCastBegins(keys)
  DebugPrint('[BAREBONES] OnAbilityCastBegins')
  DebugPrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local abilityName = keys.abilityname
end

-- This function is called whenever a tower is killed
function GameMode:OnTowerKill(keys)
  DebugPrint('[BAREBONES] OnTowerKill')
  DebugPrintTable(keys)

  local gold = keys.gold
  local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
  local team = keys.teamnumber
end

-- This function is called whenever a player changes there custom team selection during Game Setup 
function GameMode:OnPlayerSelectedCustomTeam(keys)
  DebugPrint('[BAREBONES] OnPlayerSelectedCustomTeam')
  DebugPrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.player_id)
  local success = (keys.success == 1)
  local team = keys.team_id
end

-- This function is called whenever an NPC reaches its goal position/target
function GameMode:OnNpcGoalReached( event )
  local npc = EntIndexToHScript( event.npc_entindex )
  if npc:GetUnitName() == "npc_dota_treasure_courier" then
    GameMode:TreasureDrop( npc )
  end
end

-- This function is called whenever any player sends a chat message to team or All
function GameMode:OnPlayerChat(keys)
  local teamonly = keys.teamonly
  local userID = keys.userid
  local playerID = self.vUserIds[userID]:GetPlayerID()

  local text = keys.text
end

function GameMode:BountyRunePickupFilter( filterTable )
  filterTable["xp_bounty"] = 2*filterTable["xp_bounty"]
  filterTable["gold_bounty"] = 2*filterTable["gold_bounty"]
  return true
end

function GameMode:SetRespawnTime( killedTeam, killedUnit, extraTime )
  --print("Setting time for respawn")
  if killedTeam == self.leadingTeam and self.isGameTied == false then
    killedUnit:SetTimeUntilRespawn( 20 + extraTime )
  else
    killedUnit:SetTimeUntilRespawn( 10 + extraTime )
  end
end


--------------------------------------------------------------------------------
-- Event: OnItemPickUp
--------------------------------------------------------------------------------
function GameMode:OnItemPickUp( event )
  local item = EntIndexToHScript( event.ItemEntityIndex )
  local owner = EntIndexToHScript( event.HeroEntityIndex )
  r = 300
  --r = RandomInt(200, 400)
  if event.itemname == "item_bag_of_gold" then
    --print("Bag of gold picked up")
    PlayerResource:ModifyGold( owner:GetPlayerID(), r, true, 0 )
    SendOverheadEventMessage( owner, OVERHEAD_ALERT_GOLD, owner, r, nil )
    UTIL_Remove( item ) -- otherwise it pollutes the player inventory
  elseif event.itemname == "item_treasure_chest" then
    --print("Special Item Picked Up")
    DoEntFire( "item_spawn_particle_" .. self.itemSpawnIndex, "Stop", "0", 0, self, self )
    GameMode:SpecialItemAdd( event )
    UTIL_Remove( item ) -- otherwise it pollutes the player inventory
  end
end
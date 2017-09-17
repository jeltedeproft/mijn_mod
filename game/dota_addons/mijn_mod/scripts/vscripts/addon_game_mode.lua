-- This is the entry-point to your game mode and should be used primarily to precache models/particles/sounds/etc

require('internal/util')
require('gamemode')
require( "items" )

require( "utility_functions" )

function Precache( context )
--[[
  This function is used to precache resources/units/items/abilities that will be needed
  for sure in your game and that will not be precached by hero selection.  When a hero
  is selected from the hero selection screen, the game will precache that hero's assets,
  any equipped cosmetics, and perform the data-driven precaching defined in that hero's
  precache{} block, as well as the precache{} block for any equipped abilities.

  See GameMode:PostLoadPrecache() in gamemode.lua for more information
  ]]

  DebugPrint("[BAREBONES] Performing pre-load precache")

  LinkLuaModifier("modifier_imba_speed_limit_break", "libraries/modifiers/modifier_imba_speed_limit_break.lua", LUA_MODIFIER_MOTION_NONE )

  -- Particles can be precached individually or by folder
  -- It it likely that precaching a single particle system will precache all of its children, but this may not be guaranteed
  PrecacheResource("particle", "particles/econ/generic/generic_aoe_explosion_sphere_1/generic_aoe_explosion_sphere_1.vpcf", context)
  PrecacheResource("particle_folder", "particles/test_particle", context)

  -- Models can also be precached by folder or individually
  -- PrecacheModel should generally used over PrecacheResource for individual models
  PrecacheResource("model_folder", "particles/heroes/antimage", context)
  PrecacheResource("model", "particles/heroes/viper/viper.vmdl", context)
  PrecacheModel("models/heroes/viper/viper.vmdl", context)

  -- Sounds can precached here like anything else
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_gyrocopter.vsndevts", context)

  -- Entire items can be precached by name
  -- Abilities can also be precached in this way despite the name
  PrecacheItemByNameSync("example_ability", context)
  PrecacheItemByNameSync("item_example_item", context)

  -- Entire heroes (sound effects/voice/models/particles) can be precached with PrecacheUnitByNameSync
  -- Custom units from npc_units_custom.txt can also have all of their abilities and precache{} blocks precached in this way
  PrecacheUnitByNameSync("npc_dota_hero_ancient_apparition", context)
  PrecacheUnitByNameSync("npc_dota_hero_enigma", context)
  --Cache the gold bags
  PrecacheItemByNameSync( "item_bag_of_gold", context )
  PrecacheResource( "particle", "particles/items2_fx/veil_of_discord.vpcf", context ) 

  PrecacheItemByNameSync( "item_treasure_chest", context )
  PrecacheModel( "item_treasure_chest", context )

  --Cache the creature models
  PrecacheUnitByNameSync( "npc_dota_creature_basic_zombie", context )
  PrecacheModel( "npc_dota_creature_basic_zombie", context )

  PrecacheUnitByNameSync( "npc_dota_creature_berserk_zombie", context )
  PrecacheModel( "npc_dota_creature_berserk_zombie", context )

  PrecacheUnitByNameSync( "npc_dota_treasure_courier", context )
  PrecacheModel( "npc_dota_treasure_courier", context )

  --Cache new particles
  PrecacheResource( "particle", "particles/econ/events/nexon_hero_compendium_2014/teleport_end_nexon_hero_cp_2014.vpcf", context )
  PrecacheResource( "particle", "particles/leader/leader_overhead.vpcf", context )
  PrecacheResource( "particle", "particles/last_hit/last_hit.vpcf", context )
  PrecacheResource( "particle", "particles/units/heroes/hero_zuus/zeus_taunt_coin.vpcf", context )
  PrecacheResource( "particle", "particles/addons_gameplay/player_deferred_light.vpcf", context )
  PrecacheResource( "particle", "particles/items_fx/black_king_bar_avatar.vpcf", context )
  PrecacheResource( "particle", "particles/treasure_courier_death.vpcf", context )
  PrecacheResource( "particle", "particles/econ/wards/f2p/f2p_ward/f2p_ward_true_sight_ambient.vpcf", context )

  PrecacheResource( "particle", "particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_illuminate.vpcf", context )
  PrecacheResource( "particle", "particles/units/heroes/hero_dragon_knight/dragon_knight_breathe_fire.vpcf", context )
  PrecacheResource( "particle", "particles/econ/courier/courier_platinum_roshan/platinum_roshan_ambient.vpcf", context )
  PrecacheResource( "particle", "particles/econ/courier/courier_golden_roshan/golden_roshan_ambient.vpcf", context )
end

-- Create the game mode when we activate
function Activate()
  GameRules.GameMode = GameMode()
  GameRules.GameMode:InitGameMode()
end
require "code.engine.global_types"
require "code.engine.game_data"
require "code.utilities.love_extension"
require "code.utilities.table_extension"
require "code.utilities.math_extension"
require "code.game.components"
require "code.utilities.utility_functions"

local ecs = require "code.engine.ecs"
local player = require "code.game.entities.player"
local wall = require "code.game.entities.wall"
local input_system = require "code.game.systems.input_system"
local input_velocity_system = require "code.game.systems.input_velocity_system"
local movement_system = require "code.game.systems.movement_system"
local set_animation_state_system = require "code.game.systems.set_animation_state_system"
local debug_draw_entities = require "code.game.systems.debug_draw_entities"

--[[
  Due to the level listening to game_events,
  only a require is needed to load it.

  We will have to change that later when we make
  a level select of some kind
]]
require "code.level1"

local camera = require "code.engine.camera"
local game_event_manager = require "code.engine.game_event.game_event_manager"
local level_one
local draw_the_fucking_world
local player_one
local fixed_delta_time = 1 / 60

local function visualize_level_data(level_data)
  local word = "|"
  local border = string.rep("-", level_data.width + 2)
  print(border)
  for i = 1, #level_data.content do
    local c = level_data.content:sub(i, i)
    word = word .. c
    if (i % level_data.width == 0) then
      print(word .. "|")
      word = "|"
    end
  end
  print(border)
end

function love.load()
  low, high = love.math.getRandomSeed()
  love.math.setRandomSeed(low, high)
  camera:load()
  game_event_manager.invoke(GAME_EVENT_TYPES.LOAD)

  level_one = ecs.world()
  draw_the_fucking_world = entity_draw(level_one)

  player(level_one, 1, { x = 0, y = 0 })


  wall(level_one, 0, { x = -1, y = 2 })
  wall(level_one, 1, { x = 0, y = 2 })
  wall(level_one, 2, { x = 1, y = 2 })
  wall(level_one, 3, { x = 2, y = 2 })


  local level_data = level_generator.generate_level_data()
  visualize_level_data(level_data)


  level_one:add_system(input_system)
  level_one:add_system(input_velocity_system)
  level_one:add_system(movement_system)
  level_one:add_system(set_animation_state_system)
  level_one:add_system(debug_draw_entities)
end

function love.update(dt)
  --game_event_manager.invoke(GAME_EVENT_TYPES.UPDATE, dt)
  --game_event_manager.invoke(GAME_EVENT_TYPES.LATE_UPDATE, dt)
  dt = dt < fixed_delta_time and dt or fixed_delta_time
  level_one:update(dt)
end

function love.draw()
  camera:start_draw_world()
  --game_event_manager.invoke(GAME_EVENT_TYPES.DRAW_WORLD)

  draw_the_fucking_world:update(level_one)
  camera:stop_draw_world()

  camera:start_draw_hud()
  game_event_manager.invoke(GAME_EVENT_TYPES.DRAW_HUD)
  camera:stop_draw_hud()
end

function love.mousepressed(x, y, btn, is_touch)
  game_event_manager.invoke(GAME_EVENT_TYPES.MOUSE_PRESSED, x, y, btn, is_touch)
end

function love.mousereleased(x, y, btn, is_touch, pressed)
  game_event_manager.invoke(GAME_EVENT_TYPES.MOUSE_RELEASED, x, y, btn, is_touch, pressed)
end

function love.joystickadded(joystick)
  game_event_manager.invoke(GAME_EVENT_TYPES.JOYSTICK_ADDED, joystick)
end

function love.joystickremoved(joystick)
  game_event_manager:invoke(GAME_EVENT_TYPES.JOYSTICK_REMOVED, joystick)
end

function love.keypressed(key, scancode, is_repeat)
  game_event_manager.invoke(GAME_EVENT_TYPES.KEY_PRESSED, key, scancode, is_repeat)

  if key == "escape" then
    love.event.quit()
  end
end

function love.keyreleased(key, scancode)
  game_event_manager.invoke(GAME_EVENT_TYPES.KEY_RELEASED, key, scancode)
end

--Can be stopped by returning true instead
function love.quit()
  local ready_to_quit = false
  game_event_manager.invoke(GAME_EVENT_TYPES.QUIT, ready_to_quit)
  return ready_to_quit
end

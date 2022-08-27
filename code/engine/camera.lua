local world_grid = require "code.engine.world_grid"
--[[
  PIXEL COORDINATES = love.mouse.getPosition() returns pixel coordinates
  top-left = (0, 0), bottom-right = screen resolution, e.g. 1920x1080 or 3440x1440 and so on.
  VIRTUAL RESOLUTION = Screen resolution / Scale. e.g. 1920x1080 / 6 = 320x180.
  We're dealing with small images, and scaling the canvas up to make the images look larger than it actually is.
  WORLD COORDINATES = Is the position of a entity or thing in the game world.
  SCREEN COORDINATES = Pixel coordinates on the screen that is upscaled same as the images.
]]

local camera = {
  x = 0,
  y = 0,
  scale = 5,
  canvas_game = {},
  canvas_hud = {},
  delta_time = 0,
  is_fullscreen = false,
  follow_targets = {},
  zoom = 0,
  zoom_animation_coroutine = nil,
}

-- Get screen size with scale and zoom
function camera:get_screen_game_size()
  local width, height = love.graphics.getWidth(), love.graphics.getHeight()

  return width / (self.scale + self.zoom), height / (self.scale + self.zoom)
end

function camera:get_screen_game_half_size()
  local width, height = self:get_screen_game_size()

  return width / 2, height / 2
end

-- Returns scale diff between game and hud
function camera:get_zoom_aspect_ratio() return self.scale / (self.scale + self.zoom) end

-- Returns actual screen pixel coordinates to game virtual coordinates
function camera:screen_coordinates(pixel_x, pixel_y) return self:pixel_to_screen(pixel_x), self:pixel_to_screen(pixel_y) end

function camera:pixel_to_screen(pixel)
  return pixel / self.scale
end

-- Returns centered screen world coordinates
function camera:world_coordinates(screen_x, screen_y)
  local x, y = self:get_position()
  local width, height = self:get_screen_game_size()
  local centered_x, centered_y = (screen_x - width / 2), (screen_y - height / 2)

  return centered_x + x, centered_y + y
end

-- Returns camera position in game world
function camera:get_position() return self.x or 0, self.y or 0 end

-- Turns on or off fullscreen
function camera:toggle_fullscreen() self.is_fullscreen = love.window.setFullscreen(not self.is_fullscreen, "desktop") end

-- Sets what the camera should look at
function camera:look_at(world_x, world_y) self.x, self.y = world_x, world_y end

-- Checks if rectangle is about to leave camera view
function camera:is_outside_camera_view(rectangle)
  local x, y = self:get_position()
  local half_width, half_height = world_grid:world_to_grid(camera:get_screen_game_half_size())
  local is_outside_x = rectangle.x < x - half_width or rectangle.x + rectangle.w > x + half_width
  local is_outside_y = rectangle.y < y - half_height or rectangle.y + rectangle.h > y + half_height

  return is_outside_x or is_outside_y
end

-- Preparing to draw the game world
function camera:start_draw_world()
  love.graphics.setCanvas(camera.canvas_game)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.push()

  local x, y = world_grid:grid_to_world(self:get_position())
  local half_width, half_height = self:get_screen_game_half_size()
  love.graphics.translate(math.round(half_width), math.round(half_height)) -- Center the origin
  love.graphics.translate(math.round(-x), math.round(-y)) -- Sets the camera position
end

-- Resets everything after drawing the game world
function camera:stop_draw_world()
  love.graphics.pop()
  love.graphics.setCanvas()
  love.graphics.draw(camera.canvas_game, 0, 0, 0, camera.scale + camera.zoom)
end

-- Preparing to draw the game hud
function camera:start_draw_hud()
  love.graphics.setCanvas(camera.canvas_hud)
  love.graphics.clear(0, 0, 0, 0)
end

-- Resets everything after drawing the hud
function camera:stop_draw_hud()
  love.graphics.setCanvas()
  love.graphics.draw(camera.canvas_hud, 0, 0, 0, camera.scale)
end

-- Setting up the canvas for game world
function camera:set_canvas_game(width, height)
  self.canvas_game = love.graphics.newCanvas(width, height)
  self.canvas_game:setFilter("nearest", "nearest")
end

-- Setting up the canvas for the hud
function camera:set_canvas_hud(width, height)
  self.canvas_hud = love.graphics.newCanvas(width, height)
  self.canvas_hud:setFilter("nearest", "nearest")
end

function camera:load()
  --self:toggle_fullscreen()
  local width, height = camera:get_screen_game_size()

  self:set_canvas_game(width, height)
  self:set_canvas_hud(width, height)
end

return camera

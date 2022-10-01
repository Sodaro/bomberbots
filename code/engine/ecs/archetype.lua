local CACHE_WITH = {}
local CACHE_WITHOUT = {}
local archetypes = {}
local version = 0

local archetype = {}
archetype.__index = archetype

function archetype.setup(...)
  local component_types = (...).is_component_type and { ... } or ...
  local component_ids = {}
  local components = {}

  for _, component in pairs(component_types) do
    if (component.is_component_type and not component.is_component) then
      if components[component] == nil then
        components[component] = true
        table.insert(component_ids, component:get_id())
      end
    end
  end

  local archetype_id = table.concat(component_ids, "_")

  if archetypes[archetype_id] == nil then
    archetypes[archetype_id] = setmetatable({
      _id = archetype_id,
      _components = components,
    }, archetype)

    version = version + 1
  end

  return archetypes[archetype_id]
end

function archetype:with(component_type)
  if self._components[component_type] then
    return self
  end

  local archetype_cache = CACHE_WITH[self]

  if not archetype_cache then
    archetype_cache = {}
    CACHE_WITH[self] = archetype_cache
  end

  local current_archetype = archetype_cache[component_type]

  if current_archetype == nil then
    local component_types = {}

    for component, _ in pairs(self._components) do
      table.insert(component_types, component)
    end

    table.insert(component_types, component_type)
    current_archetype = archetype.setup(component_types)
    archetype_cache[component_type] = current_archetype
  end

  return current_archetype
end

function archetype:without(component_type)
  if self._components[component_type] == nil then
    return self
  end

  local archetype_cache = CACHE_WITHOUT[self]

  if not archetype_cache then
    archetype_cache = {}
    CACHE_WITH[self] = archetype_cache
  end

  local current_archetype = archetype_cache[component_type]

  if current_archetype == nil then
    local component_types = {}

    for component, _ in pairs(self._components) do
      if not component_type:is(component) then
        table.insert(component_types, component)
      end
    end

    current_archetype = archetype.setup(component_types)
    archetype_cache[component_type] = current_archetype
  end

  return current_archetype
end

function archetype.get_version()
  return version
end

function archetype:has(component_type)
  return self._components[component_type] == true
end

function archetype:has_all(...)
  local components = (...).is_component_type and { ... } or ...

  for _, component in pairs(components) do
    if not self:has(component) then
      return false
    end
  end

  return true
end

function archetype:has_any(...)
  local components = (...).is_component_type and { ... } or ...

  for _, component in pairs(components) do
    if self:has(component) then
      return true
    end
  end

  return false
end

archetype.EMPTY = archetype.setup({})

return archetype

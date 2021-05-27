local pl_tablex = require "pl.tablex"
local jwt_decoder = require "kong.plugins.jwt.jwt_parser"

local EMPTY = pl_tablex.readonly {}

local mt_cache = { __mode = "k" }
local consumer_in_groups_cache = setmetatable({}, mt_cache)


local function get_user_roles()
  local groups = {}
  local token = ngx.ctx.authenticated_jwt_token
  local jwt = jwt_decoder:new(token)
  local roles = jwt.claims["roles"]

  if not roles then
    roles = {"PUBLIC"}
  else
    table.insert(roles, "PUBLIC")
  end

  for i = 1, #roles do
    local group = roles[i]
    groups[group] = group
  end 

  return groups
end


--- checks whether a consumer-group-list is part of a given list of groups.
-- @param groups_to_check (table) an array of group names. Note: since the
-- results will be cached by this table, always use the same table for the
-- same set of groups!
-- @param consumer_groups (table) list of consumer groups (result from
-- `get_user_roles`)
-- @return (boolean) whether the consumer is part of any of the groups.
local function consumer_in_groups(groups_to_check, consumer_groups)
  -- 1st level cache on "groups_to_check"
  local result1 = consumer_in_groups_cache[groups_to_check]
  if result1 == nil then
    result1 = setmetatable({}, mt_cache)
    consumer_in_groups_cache[groups_to_check] = result1
  end

  -- 2nd level cache on "consumer_groups"
  local result2 = result1[consumer_groups]
  if result2 ~= nil then
    return result2
  end

  -- not found, so validate and populate 2nd level cache
  result2 = false
  for i = 1, #groups_to_check do
    if consumer_groups[groups_to_check[i]] then
      result2 = true
      break
    end
  end
  result1[consumer_groups] = result2
  return result2
end

--- Gets the currently identified consumer for the request.
-- Checks both consumer and if not found the credentials.
-- @return consumer_id (string), or alternatively `nil` if no consumer was
-- authenticated.
local function get_current_consumer_id()
  local ctx = ngx.ctx
  return (ctx.authenticated_consumer or EMPTY).id or
         (ctx.authenticated_credential or EMPTY).consumer_id
end


return {
  get_user_roles = get_user_roles,
  consumer_in_groups = consumer_in_groups,
  get_current_consumer_id = get_current_consumer_id,
}
local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"
local constants = require "kong.constants"
local pl_tablex = require "pl.tablex"
local parser = require "kong.plugins.rbac.parser"
local roles = require "kong.plugins.rbac.roles"

local table_concat = table.concat
local set_header = ngx.req.set_header
local ngx_error = ngx.ERR
local ngx_log = ngx.log
local EMPTY = pl_tablex.readonly {}
local BLACK = "BLACK"
local WHITE = "WHITE"

local mt_cache = { __mode = "k" }
local config_cache = setmetatable({}, mt_cache)

local RBACHandler = BasePlugin:extend()

RBACHandler.PRIORITY = 949
RBACHandler.VERSION = "0.1.0"

function RBACHandler:new()
  RBACHandler.super.new(self, "rbac")
end

function RBACHandler:access(conf)
  RBACHandler.super.access(self)

  -- simplify our plugins 'conf' table
  local config = config_cache[conf]
  if not config then
    config = {}
    config.type = (conf.blacklist or EMPTY)[1] and BLACK or WHITE
    config.groups = config.type == BLACK and conf.blacklist or conf.whitelist
    config.cache = setmetatable({}, mt_cache)
  end

  -- get the consumer/credentials
  local consumer_id = parser.get_current_consumer_id()
  if not consumer_id then
    ngx_log(ngx_error, "[rbac plugin] Cannot identify the consumer, add an ",
                       "authentication plugin to use the RBAC plugin")
    return responses.send_HTTP_FORBIDDEN("You cannot consume this service")
  end

  -- get the consumer groups, since we need those as cache-keys to make sure
  -- we invalidate properly if they change
  local user_roles, err = parser.get_user_org_roles()
  if not user_roles.role then
    return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
  end

  -- 'to_be_blocked' is either 'true' if it's to be blocked, or the header
  -- value if it is to be passed
  local to_be_blocked = config.cache[user_roles.role]
  if to_be_blocked == nil then    
    local in_group = roles.user_roles(config.groups, user_roles.role)

    if config.type == BLACK then
      to_be_blocked = in_group
    else
      to_be_blocked = not in_group
    end

    if to_be_blocked == false then
      -- we're allowed, convert 'false' to the header value, if needed
      -- if not needed, set dummy value to save mem for potential long strings
      to_be_blocked = conf.hide_groups_header and "" 
                      or table_concat(user_roles.role, ", ")
    end

    -- update cache
    config.cache[user_roles.role] = to_be_blocked
  end

  if to_be_blocked == true then -- NOTE: we only catch the boolean here!
    return responses.send_HTTP_FORBIDDEN("You cannot consume this service")
  end

  if not conf.hide_groups_header then
    set_header(constants.HEADERS.USER_ROLES, to_be_blocked)
  end
end

return RBACHandler

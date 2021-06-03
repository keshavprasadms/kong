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
    config.type = WHITE
    config.roles = conf.whitelist
    config.additionalchecks = conf.additionalchecks
    config.checkin = conf.checkin
    config.payloadfields = conf.payloadfields
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
  local user_org_roles, err = parser.token_roles_orgs(config.additionalchecks)

  if not user_org_roles then
    return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
  end

  -- 'to_be_blocked' is either 'true' if it's to be blocked, or the header
  -- value if it is to be passed
  local to_be_blocked = config.cache[user_org_roles]

  if to_be_blocked == nil then

    local paylod_data = {}
    if type(config.checkin) == "table" and type(config.payloadfields) == "table" then
      for i=1, #config.checkin do
        for j=1, #config.payloadfields do
          if config.checkin[i] == 'body' then
            local body, err = kong.request.get_body()
            if not err then
              paylod_data = parser.parse_json(body, paylod_data, config.payloadfields[j])
            end
          elseif config.checkin[i] == 'header' then
            local header = kong.request.get_header(config.payloadfields[j])
            if header ~= nil then
              paylod_data[config.payloadfields[j]] = header
            end
          end
        end
      end
    end

    local in_roles = roles.user_roles(config.roles, paylod_data, user_org_roles)

    to_be_blocked = not in_roles

    if to_be_blocked == false then
      -- we're allowed, convert 'false' to the header value, if needed
      -- if not needed, set dummy value to save mem for potential long strings
      to_be_blocked = conf.hide_groups_header and "" or table_concat(user_org_roles, ", ")
    end

    -- update cache
    config.cache[user_org_roles] = to_be_blocked
  end

  if to_be_blocked == true then -- NOTE: we only catch the boolean here!
    return responses.send_HTTP_FORBIDDEN("You cannot consume this service")
  end

  if not conf.hide_groups_header then
    set_header(constants.HEADERS.USER_ORG_ROLES, to_be_blocked)
  end
end

return RBACHandler

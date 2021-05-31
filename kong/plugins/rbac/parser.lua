local pl_tablex = require "pl.tablex"

local EMPTY = pl_tablex.readonly {}

local jwt_decoder = require "kong.plugins.jwt.jwt_parser"

local function parse_roles_orgs(jwt_roles, user_org_roles)
    local user_org_roles = user_org_roles or {}
      for key,value in pairs(jwt_roles) do
          if type(value) == "table" then
            parse_roles_orgs(value, user_org_roles)
          else
            table.insert(user_org_roles[key], value)
          end
      end
      return user_org_roles
  end

local function get_user_org_roles() 
      local user_org_roles = {["orgId"] = {}, ["role"] = {}}
      local token = ngx.ctx.authenticated_jwt_token
      local jwt = jwt_decoder:new(token)
      local jwt_roles = jwt.claims.roles
    
      if not jwt_roles then
        user_org_roles["role"] = {"PUBLIC"}
      else
        table.insert(user_org_roles["role"], "PUBLIC")
      end
    
      user_org_roles = parse_roles_orgs(jwt_roles, user_org_roles)
    
      for i = 1, #user_org_roles.role do
        local role = user_org_roles.role[i]
        user_org_roles.role[role] = role
      end
    
      return user_org_roles
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
    get_user_org_roles = get_user_org_roles,
    get_current_consumer_id = get_current_consumer_id,
  }
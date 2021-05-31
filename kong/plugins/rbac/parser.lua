local pl_tablex = require "pl.tablex"

local EMPTY = pl_tablex.readonly {}

local jwt_decoder = require "kong.plugins.jwt.jwt_parser"

local function parse_json(json, json_temp_table)
    local json_temp_table = json_temp_table or {}
      for key,value in pairs(json) do
          if type(value) == "table" then
            parse_json(value, json_temp_table)
          else
            print(key,value)
            table.insert(json_temp_table, value)
          end
      end
      local json_table = {}
      for key,value in pairs(json_temp_table) do
        json_table[value] = value
      end
      return json_table
  end

  local function parse_orgs_roles(json, json_table)
    local json_table = json_table or {}
      for key,value in pairs(json) do
          if type(value) == "table" then
            print(key)
            parse_orgs_roles(value, json_table)
          else
            print(key, value)
--            table.insert(json_table[key], value)
          end
      end
      return json_table
  end

local function get_user_org_roles() 
      local user_org_roles = {["orgId"] = {}, ["role"] = {}}
      local json_table = {}
      local token = ngx.ctx.authenticated_jwt_token
      local jwt = jwt_decoder:new(token)
--      local jwt_roles = jwt.claims.roles
    
    --   if not user_org_roles then
    --     user_org_roles["role"] = {"PUBLIC"}
    --   else
    --     table.insert(user_org_roles["role"], "PUBLIC")
    --   end
    
    --  return parse_orgs_roles(jwt_roles, user_org_roles)
    --   parse_orgs_roles(jwt_roles, json_table)
    --   print(jwt.claims.roles)
    --   for k,v in pairs(jwt.claims.roles[1]) do
    --       print(k,v)
    --   end

    -- parse_orgs_roles(jwt_roles, user_org_roles)
    -- print(jwt.claims.roles[1][1].role)
    -- print(jwt.claims.roles[1][1].scope[1].orgId)
    -- print(jwt.claims.roles[1][2].role)
    -- print(jwt.claims.roles[1][2].scope[1].orgId)
    -- print(jwt.claims.roles[1][2].scope[2].orgId)

    --   local roles = {}
    --   for i=1, #jwt.claims.roles[1] do
    --     roles[i] = {}
    --     for j=1, #jwt.claims.roles[1][i].scope do
    --       roles[i][j] = jwt.claims.roles[1][i].scope[j].orgId
    --     end
    --   end

    local roles = {}
    for i=1, #jwt.claims.roles[1] do
        table.insert(roles,jwt.claims.roles[1][i].role)
    end

    local orgs = {}
      for i=1, #jwt.claims.roles[1] do
        orgs[i] = {}
        for j=1, #jwt.claims.roles[1][i].scope do
            table.insert(orgs[i], jwt.claims.roles[1][i].scope[j].orgId)
        end
      end

      local final_table = {}
      local final_table1 = {}
      for i=1, #roles do
        for j=1, #orgs[i] do
          local role = roles[i]
          local org = orgs[i][j]
          table.insert(final_table, {role, org})
          table.insert(final_table1, role.. "." .. org)
        end
    end

    for i=1, #final_table do
        for j=1, #final_table[i] do
            print(final_table[i][j])
        end
    end

    --parse_orgs_roles(final_table)
      for i=1, #final_table1 do
        local key = final_table1[i]
        final_table1[key] = key
      end

    for k,v in pairs(final_table1) do
        print(k .. "/" ..v)
    end

    return final_table1
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
    parse_json = parse_json,
    parse_orgs_roles = parse_orgs_roles,
  }
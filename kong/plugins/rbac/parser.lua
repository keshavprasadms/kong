local pl_tablex = require "pl.tablex"

local EMPTY = pl_tablex.readonly {}

local jwt_decoder = require "kong.plugins.jwt.jwt_parser"

local function parse_json(json, json_temp_table)
    local json_temp_table = json_temp_table or {}
      for key,value in pairs(json) do
          if type(value) == "table" then
            parse_json(value, json_temp_table)
          else
            table.insert(json_temp_table, value)
          end
      end
      local json_table = {}
      for key,value in pairs(json_temp_table) do
        json_table[value] = value
      end
      return json_table
end

local function token_roles_orgs()
  local user_org_roles = {["orgId"] = {}, ["role"] = {}}
  local token = ngx.ctx.authenticated_jwt_token
  local jwt = jwt_decoder:new(token)
  local jwt_roles = jwt.claims.roles
  local roles = {}

  for i=1, #jwt_roles do
    table.insert(roles,jwt_roles[i].role)
  end

  local orgs = {}
  for i=1, #jwt_roles do
    orgs[i] = {}
    for j=1, #jwt.claims.roles[i].scope do
      table.insert(orgs[i], jwt.claims.roles[i].scope[j].orgId)
    end
  end

  local final_table = {}
  for i=1, #roles do
    for j=1, #orgs[i] do
      local role = roles[i]
      local org = orgs[i][j]
      table.insert(final_table, role.. "." .. org)
    end
  end

  for i=1, #final_table do
    local key = final_table[i]
    final_table[key] = key
    final_table[i] = nil
  end

    return final_table
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
    token_roles_orgs = token_roles_orgs,
    get_current_consumer_id = get_current_consumer_id,
    parse_json = parse_json,
  }
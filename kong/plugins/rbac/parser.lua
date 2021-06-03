local pl_tablex = require "pl.tablex"

local EMPTY = pl_tablex.readonly {}

local jwt_decoder = require "kong.plugins.jwt.jwt_parser"

local function parse_json(json, json_temp_table, payloadfields)
    local json_temp_table = json_temp_table or {}
    local payloadfields = payloadfields or ""
      for key,value in pairs(json) do
          if type(value) == "table" then
            if payloadfields == key then
              json_temp_table[key] = value[1]
              break
            else
              parse_json(value, json_temp_table, payloadfields)
            end
          end
      end
      local json_table = {}
      for key,value in pairs(json_temp_table) do
        json_table[value] = value
      end
      return json_temp_table
end

local function token_roles_orgs(additionalchecks)
  local token = ngx.ctx.authenticated_jwt_token
  local jwt = jwt_decoder:new(token)
  local jwt_roles = jwt.claims.roles

  local roles = {}
  if jwt_roles then
    for i=1, #jwt_roles do
      table.insert(roles,jwt_roles[i].role)
    end
  end

  local orgs = {}
  if type(additionalchecks) == "table" then
    for i=1, #additionalchecks do
      if additionalchecks[i] == 'orgcheck' then
        for i=1, #jwt_roles do
          orgs[i] = {}
          for j=1, #jwt.claims.roles[i].scope do
            table.insert(orgs[i], jwt.claims.roles[i].scope[j].orgId)
          end
        end
      end
    end
  end

  local final_table = {}
  if next(roles) then
    for i=1, #roles do
      local role = roles[i]
      if next(orgs) then
        for j=1, #orgs[i] do
          local org = orgs[i][j]
          table.insert(final_table, role .. "." .. org)
        end
      else
        table.insert(final_table, role)
      end
    end
  end

  if type(additionalchecks) == "table" then
    for i=1, #additionalchecks do
      if additionalchecks[i] == 'ownercheck' then
        table.insert(final_table, jwt.claims.userid)
      end
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
local mt_cache = { __mode = "k" }
local roles_cache = setmetatable({}, mt_cache)

local function construct_map(roles_to_check, payload_data)  
  local result_table = {}
    for key, value in pairs(roles_to_check) do
      if next(payload_data) then
        for k, v in pairs(payload_data) do
            table.insert(result_table, value .. "." .. v)
        end
      end
      table.insert(result_table, value)
    end

    return result_table
end

--- checks whether a consumer-group-list is part of a given list of groups.
-- @param groups_to_check (table) an array of group names. Note: since the
-- results will be cached by this table, always use the same table for the
-- same set of groups!
-- @param consumer_groups (table) list of consumer groups (result from
-- `get_user_roles`)
-- @return (boolean) whether the consumer is part of any of the groups.
local function user_roles(roles_to_check, payload_data, roles)
    local result_table = construct_map(roles_to_check, payload_data)
    -- 1st level cache on "groups_to_check"
    local result1 = roles_cache[result_table]
    if result1 == nil then
      result1 = setmetatable({}, mt_cache)
      roles_cache[result_table] = result1
    end

    -- 2nd level cache on "consumer_groups"
    local result2 = result1[roles]
    if result2 ~= nil then
      return result2
    end

    -- not found, so validate and populate 2nd level cache
    result2 = false
    for i = 1, #result_table do
      if roles[result_table[i]] then
        result2 = true
        break
      end
    end
    result1[roles] = result2
    return result2
end

return {
    user_roles = user_roles,
    construct_map = construct_map,
}
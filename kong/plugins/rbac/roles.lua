local mt_cache = { __mode = "k" }
local roles_cache = setmetatable({}, mt_cache)

local function construct_map(roles_to_check, body_data)
    local result_table = {}
    for key, value in pairs(roles_to_check) do
      for k, v in pairs(body_data) do
          table.insert(result_table, value .. "." .. v)
        end
    end

    -- for i=1, #result_table do
    --     local key = result_table[i]
    --     result_table[key] = key
    --     result_table[i] = nil
    -- end

    for k,v in pairs(result_table) do
        print(k .. "/" .. v)
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
local function user_roles(roles_to_check, body_data, roles)
    local result_table = construct_map(roles_to_check, body_data)
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

-- result2 = false
-- local flag1 = false
-- local flag2 = false
-- for i = 1, #user_org_roles do
--    for j = 1, #user_org_roles[i] do
--       for k = 1, #roles_to_check do
--           if user_org_roles[i][j] == roles_to_check[k] then
--               print(user_org_roles[i][j])
--               print(roles_to_check[k])
--               flag1 = true
--               print(flag1)
--              break
--           end
--       end
--       for k = 1, #body_data do
--           if user_org_roles[i][j] == body_data[k] then
--               print(user_org_roles[i][j])
--               print(body_data[k])
--               flag2 = true
--               print(flag2)
--               break
--            end
--       end
--   end
-- end
-- if flag1 and flag2 then
--   result2 = true
-- end
-- result1[user_org_roles] = result2
-- return result2
-- end
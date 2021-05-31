local mt_cache = { __mode = "k" }
local orgs_cache = setmetatable({}, mt_cache)

--- checks whether a consumer-group-list is part of a given list of groups.
-- @param groups_to_check (table) an array of group names. Note: since the
-- results will be cached by this table, always use the same table for the
-- same set of groups!
-- @param consumer_groups (table) list of consumer groups (result from
-- `get_user_roles`)
-- @return (boolean) whether the consumer is part of any of the groups.
local function user_orgs(orgs_to_check, orgs)
  -- 1st level cache on "groups_to_check"
  local result1 = orgs_cache[orgs_to_check]
  if result1 == nil then
    result1 = setmetatable({}, mt_cache)
    orgs_cache[orgs_to_check] = result1
  end

  -- 2nd level cache on "consumer_groups"
  local result2 = result1[orgs]
  if result2 ~= nil then
    return result2
  end

  -- not found, so validate and populate 2nd level cache
  result2 = false
  for i = 1, #orgs_to_check do
    if orgs[orgs_to_check[i]] then
      result2 = true
      break
    end
  end
  result1[orgs] = result2
  return result2
end

return {
  user_orgs = user_orgs,
}
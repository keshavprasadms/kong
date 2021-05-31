local mt_cache = { __mode = "k" }
local consumer_in_groups_cache = setmetatable({}, mt_cache)

local body, err = kong.request.get_body()
if err then
  kong.log.err("Cannot process request body: ", err)
  return nil, { status = 400, message = "Cannot process request body" }
end
for k,v in pairs(body) do
  print(k, v)
end

--- checks whether a consumer-group-list is part of a given list of groups.
-- @param groups_to_check (table) an array of group names. Note: since the
-- results will be cached by this table, always use the same table for the
-- same set of groups!
-- @param consumer_groups (table) list of consumer groups (result from
-- `get_user_roles`)
-- @return (boolean) whether the consumer is part of any of the groups.
local function user_orgs(groups_to_check, consumer_groups)
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

return {
  consumer_in_groups = consumer_in_groups,
}
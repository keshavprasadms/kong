local singletons = require "kong.singletons"

local function check_unique(group, rbac)
  -- If dao required to make this work in integration tests when adding fixtures
  if singletons.dao and rbac.consumer_id and group then
    local res, err = singletons.dao.rbacs:find_all {consumer_id = rbac.consumer_id, group = group}
    if not err and #res > 0 then
      return false, "RBAC group already exist for this consumer"
    elseif not err then
      return true
    end
  end
end

local SCHEMA = {
  primary_key = {"id"},
  table = "rbacs",
  cache_key = { "consumer_id" },
  fields = {
    id = { type = "id", dao_insert_value = true },
    created_at = { type = "timestamp", dao_insert_value = true },
    consumer_id = { type = "id", required = true, foreign = "consumers:id" },
    group = { type = "string", required = true, func = check_unique }
  },
}

return {rbacs = SCHEMA}

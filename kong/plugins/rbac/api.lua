local crud = require "kong.api.crud_helpers"

return {
  ["/consumers/:username_or_id/rbacs/"] = {
    before = function(self, dao_factory, helpers)
      crud.find_consumer_by_username_or_id(self, dao_factory, helpers)
      self.params.consumer_id = self.consumer.id
    end,

    GET = function(self, dao_factory)
      crud.paginated_set(self, dao_factory.rbacs)
    end,

    PUT = function(self, dao_factory)
      crud.put(self.params, dao_factory.rbacs)
    end,

    POST = function(self, dao_factory)
      crud.post(self.params, dao_factory.rbacs)
    end
  },

  ["/consumers/:username_or_id/rbacs/:group_or_id"] = {
    before = function(self, dao_factory, helpers)
      crud.find_consumer_by_username_or_id(self, dao_factory, helpers)
      self.params.consumer_id = self.consumer.id

      local rbacs, err = crud.find_by_id_or_field(
        dao_factory.rbacs,
        { consumer_id = self.params.consumer_id },
        self.params.group_or_id,
        "group"
      )

      if err then
        return helpers.yield_error(err)
      elseif #rbacs == 0 then
        return helpers.responses.send_HTTP_NOT_FOUND()
      end
      self.params.group_or_id = nil

      self.rbac = rbacs[1]
    end,

    GET = function(self, dao_factory, helpers)
      return helpers.responses.send_HTTP_OK(self.rbac)
    end,

    PATCH = function(self, dao_factory)
      crud.patch(self.params, dao_factory.rbacs, self.rbac)
    end,

    DELETE = function(self, dao_factory)
      crud.delete(self.rbac, dao_factory.rbacs)
    end
  },
  ["/rbacs"] = {
    GET = function(self, dao_factory)
      crud.paginated_set(self, dao_factory.rbacs)
    end
  },
  ["/rbacs/:rbac_id/consumer"] = {
    before = function(self, dao_factory, helpers)
      local filter_keys = {
       id = self.params.rbac_id
      }

      local rbacs, err = dao_factory.rbacs:find_all(filter_keys)
      if err then
        return helpers.yield_error(err)
      elseif next(rbacs) == nil then
        return helpers.responses.send_HTTP_NOT_FOUND()
      end

      self.params.rbac_id = nil
      self.params.username_or_id = rbacs[1].consumer_id
      crud.find_consumer_by_username_or_id(self, dao_factory, helpers)
    end,

    GET = function(self, dao_factory, helpers)
      return helpers.responses.send_HTTP_OK(self.consumer)
    end
  }
}

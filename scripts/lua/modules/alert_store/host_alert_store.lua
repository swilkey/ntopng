--
-- (C) 2021-21 - ntop.org
--

local dirs = ntop.getDirs()
package.path = dirs.installdir .. "/scripts/lua/modules/alert_store/?.lua;" .. package.path

require "lua_utils"
local alert_store = require "alert_store"
local json = require "dkjson"

-- ##############################################

local host_alert_store = {}

-- ##############################################

function host_alert_store:new(args)
   -- Instance of the base class
   local _host_alert_store = alert_store:new()

   -- Subclass using the base class instance
   self.key = "host"

   -- self is passed as argument so it will be set as base class metatable
   -- and this will actually make it possible to override functions
   local _host_alert_store_instance = _host_alert_store:new(self)

   -- Return the instance
   return _host_alert_store_instance
end

-- ##############################################

function host_alert_store:init()
   -- TODO
end

-- ##############################################

function host_alert_store:insert()
   -- TODO
end

-- ##############################################

return host_alert_store

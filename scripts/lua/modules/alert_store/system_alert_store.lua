--
-- (C) 2021-21 - ntop.org
--

local dirs = ntop.getDirs()
package.path = dirs.installdir .. "/scripts/lua/modules/alert_store/?.lua;" .. package.path

require "lua_utils"
local alert_store = require "alert_store"
local alert_consts = require "alert_consts"
local json = require "dkjson"

-- ##############################################

local system_alert_store = {}

-- ##############################################

function system_alert_store:new(args)
   -- Instance of the base class
   local _system_alert_store = alert_store:new()

   -- Subclass using the base class instance
   self.key = "system"

   -- self is passed as argument so it will be set as base class metatable
   -- and this will actually make it possible to override functions
   local _system_alert_store_instance = _system_alert_store:new(self)

   -- Return the instance
   return _system_alert_store_instance
end

-- ##############################################

function system_alert_store:insert(alert)
   local table_name = "system_alerts"

   traceError(TRACE_DEBUG,TRACE_CONSOLE, "system_alert_store:insert")

   -- TODO

   local json = alert.alert_json or ""

   local insert_stmt = "INSERT INTO "..table_name.."("..
        "alert_id, "..

      ") "..
      "VALUES ("..
        alert.alert_type..", "..

        json..
      "); "
  
   --return interface.alert_store_query(insert_stmt)
end

-- ##############################################

return system_alert_store

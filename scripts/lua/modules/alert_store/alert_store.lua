--
-- (C) 2021-21 - ntop.org
--
-- Module to keep things in common across alert_store of various type

local dirs = ntop.getDirs()

require "lua_utils"
local json = require "dkjson"

-- ##############################################

local alert_store = {}

-- ##############################################

function alert_store:new(args)
   if args then
      -- We're being sub-classed
      if not args.key then return nil end
   end

   local this = args or {key = "base"}

   setmetatable(this, self)
   self.__index = self

   if args then
      -- Initialization is only run if a subclass is being instanced, that is,
      -- when args is not nil
      this:_initialize()
   end

   return this
end

-- ##############################################

function alert_store:_initialize()

end

-- ##############################################

function alert_store:insert(alert)
   traceError(TRACE_NORMAL, TRACE_CONSOLE, "alert_store:insert")
   tprint(alert)
   return false
end

-- ##############################################
--
function alert_store:_get_store_lock_key()
   return string.format("ntopng.cache.alert_store.%s.alert_store_lock", self.key)
end

-- ##############################################

function alert_store:_lock()
   local max_lock_duration = 5 -- seconds
   local max_lock_attempts = 5 -- give up after at most this number of attempts
   local lock_key = self:_get_store_lock_key()

   for i = 1, max_lock_attempts do
      local value_set = ntop.setnxCache(lock_key, "1", max_lock_duration)

      if value_set then
         return true -- lock acquired
      end

      ntop.msleep(1000)
   end

   return false -- lock not acquired
end

-- ##############################################

function alert_store:_unlock()
   ntop.delCache(self:_get_store_lock_key())
end

-- ##############################################

return alert_store

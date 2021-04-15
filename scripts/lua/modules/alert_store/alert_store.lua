--
-- (C) 2021-21 - ntop.org
--
-- Module to keep things in common across alert_store of various type

local dirs = ntop.getDirs()

-- Import the classes library.
local classes = require "classes"
require "lua_utils"
local json = require "dkjson"

-- ##############################################

local alert_store = classes.class()

-- ##############################################

function alert_store:init(args)
   self._where = { "1 = 1" }
   self._group_by = nil
end

-- ##############################################

function alert_store:_escape(str)
   if not str then
      return ""
   end

   return str:gsub("'", "''")
end

-- ##############################################

--@brief Check if the submitted fields are avalid (i.e., they are not injection attempts)
function alert_store:_valid_fields(fields)
   local f = fields:split(",") or { fields }

   for _, field in pairs(f) do
      -- only allow alphanumeric characters and underscores
      if not string.match(field, "^[%w_(*) ]+$") then
	 traceError(TRACE_ERROR, TRACE_CONSOLE, string.format("Invalid field found in query [%s]", field:gsub('%W','') --[[ prevent stored injections --]]))
	 return false
      end
   end

   return true
end

-- ##############################################

--@brief Add filters on time
--@param epoch_begin The start timestamp
--@param epoch_end The end timestamp
--@return True if set is successful, false otherwise
function alert_store:add_time_filter(epoch_begin, epoch_end)
   if tonumber(epoch_begin) then
      self._epoch_begin = tonumber(epoch_begin)
      self._where[#self._where + 1] = string.format("tstamp >= %u", epoch_begin)
   end

   if tonumber(epoch_end) then
      self._epoch_end = tonumber(epoch_end)
      self._where[#self._where + 1] = string.format("tstamp <= %u", epoch_end)
   end

   return true
end

-- ##############################################

--@brief Pagination options to fetch partial results
--@param limit The number of results to be returned
--@param offset The number of records to skip before returning results
--@return True if set is successful, false otherwise
function alert_store:add_limit(limit, offset)
   if tonumber(limit) then
      self._limit = limit

      if tonumber(offset) then
	 self._offset = offset
      end

      return true
   end

   return false
end

-- ##############################################

--@brief Specify the sort criteria of the query
--@param fields Results will be returned sorted according to these fields
--@return True if set is successful, false otherwise
function alert_store:order_by(fields)
   if self:_valid_fields(fields) then
      self._order_by = fields
      return true
   end

   return false
end

-- ##############################################

function alert_store:group_by(fields)
   if self:_valid_fields(fields) then
      self._group_by = fields
      return true
   end

   return false
end

-- ##############################################

function alert_store:insert(alert)
   traceError(TRACE_NORMAL, TRACE_CONSOLE, "alert_store:insert")
   tprint(alert)
   return false
end

-- ##############################################

function alert_store:select(fields)
   local res = {}
   local where_clause = ''
   local group_by_clause = ''
   local order_by_clause = ''
   local limit_clause = ''
   local offset_clause = ''

   -- Select everything by defaul
   fields = fields or '*'

   if not self:_valid_fields(fields) then
      return res
   end

   where_clause = table.concat(self._where, " AND ")

   -- [OPTIONAL] Add the group by
   if self._group_by then
      group_by_clause = string.format("GROUP BY %s", self._group_by)
   end

   -- [OPTIONAL] Add sort criteria
   if self._order_by then
      order_by_clause = string.format("ORDER BY %s", self._order_by)
   end

   -- [OPTIONAL] Add limit for pagination
   if self._limit then
      limit_clause = string.format("LIMIT %u", self._limit)
   end

   -- [OPTIONAL] Add offset for pagination
   if self._offset then
      offset_clause = string.format("OFFSET %u", self._offset)
   end

   -- Prepare the final query
   local q = string.format(" SELECT %s FROM `%s` WHERE %s %s %s %s %s",
			   fields, self._table_name, where_clause, group_by_clause, order_by_clause, limit_clause, offset_clause)
   tprint(q)
   res = interface.alert_store_query(q)

   return res
end

-- ##############################################

--@brief Performs a query and counts the number of records
function alert_store:count()
   local count_query = self:select("count(*) as count")
   local num_results = tonumber(count_query[1]["count"])

   return num_results
end

-- ##############################################

--@brief Performs a query and counts the number of records in multiple time slots
function alert_store:count_by_time()
   local time_slot_width = 600 -- 5-minute slots
   -- Preserve all the filters currently set
   local where_clause = table.concat(self._where, " AND ")

   -- Group by according to the timeslot, that is, the alert timestamp MODULO the slot width
   local q = string.format("SELECT (tstamp - tstamp %% %u) as slot, count(*) count FROM %s WHERE %s GROUP BY slot ORDER BY slot ASC",
			   time_slot_width, self._table_name, where_clause)

   local q_res = interface.alert_store_query(q)

   -- Calculate minimum and maximum slots to make sure the response always returns consecutive time slots, possibly filled with zeroes
   local now = os.time()

   -- Minimum slot is, in order, the specified begin epoch, or the oldest time read in the query, or one hour ago as fallback
   local min_slot = self._epoch_begin or tonumber(q_res and q_res[1] and q_res[1]["slot"]) or now - 3600

   -- Minimum slot is, in order, the specified begin epoch, or the oldest time read in the query, or the current time as fallback
   local max_slot = self._epoch_end or tonumber(q_res and q_res[#q_res] and q_res[#q_res]["slot"]) or now

   local all_slots = {}
   -- Read points from the query
   for _, p in ipairs(q_res) do
      all_slots[tonumber(p.slot)] = tonumber(p.count)
   end

   -- Pad missing points with zeroes
   for slot = min_slot, max_slot + 1, time_slot_width do
      if not all_slots[slot] then
	 all_slots[slot] = 0
      end
   end

   -- Prepare the result as a Lua array ordered by time slot
   local res = {}
   for slot, count in pairsByKeys(all_slots, asc) do
      res[#res + 1] = {slot, count}
   end

   return res
end

-- ##############################################

--@brief Add filters according to what is specified inside the REST API
function alert_store:add_request_filters()
   local epoch_begin = tonumber(_GET["epoch_begin"])
   local epoch_end = tonumber(_GET["epoch_end"])
   local alert_type = _GET["alert_type"] -- TODO: add type filter
   local alert_severity = _GET["alert_severity"] -- TODO: add severity filter

   self:add_time_filter(epoch_begin, epoch_end)
end

-- ##############################################

--@brief Add offset, limit, and group by filters according to what is specified inside the REST API
function alert_store:add_request_ranges()
   local start = tonumber(_GET["start"])   --[[ The OFFSET: default no offset --]]
   local length = tonumber(_GET["length"]) --[[ The LIMIT: default no limit   --]]

   -- TODO: add sort
   self:add_limit(length, start)
end

-- ##############################################

return alert_store

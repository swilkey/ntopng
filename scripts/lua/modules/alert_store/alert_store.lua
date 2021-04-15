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

--@brief Add filters on status (engaged or historical)
--@param engaged true to select engaged alerts
--@return True if set is successful, false otherwise
function alert_store:add_status_filter(engaged)
   self._engaged = engaged
   return true
end

-- ##############################################

--@brief Add filters on time
--@param epoch_begin The start timestamp
--@param epoch_end The end timestamp
--@return True if set is successful, false otherwise
function alert_store:add_time_filter(epoch_begin, epoch_end)
   if not self._epoch_begin and tonumber(epoch_begin) then
      self._epoch_begin = tonumber(epoch_begin)
      self._where[#self._where + 1] = string.format("tstamp >= %u", epoch_begin)
   end

   if not self._epoch_end and tonumber(epoch_end) then
      self._epoch_end = tonumber(epoch_end)
      self._where[#self._where + 1] = string.format("tstamp <= %u", epoch_end)
   end

   return true
end

-- ##############################################

--@brief Add filters on alert id
--@param alert_id The id of an alert to be filtered
--@return True if set is successful, false otherwise
function alert_store:add_alert_id_filter(alert_id)
   if not self._alert_id and tonumber(alert_id) then
      self._alert_id = tonumber(alert_id)
      self._where[#self._where + 1] = string.format("alert_id = %u", alert_id)

      return true
   end

   return false
end

-- ##############################################

--@brief Add filters on alert severity
--@param alert_severity The severity of an alert to be filtered
--@return True if set is successful, false otherwise
function alert_store:add_alert_severity_filter(alert_severity)
   if not self._alert_severity and tonumber(alert_severity) then
      self._alert_severity = tonumber(alert_severity)
      self._where[#self._where + 1] = string.format("severity = %u", alert_severity)

      return true
   end

   return false
end

-- ##############################################

--@brief Pagination options to fetch partial results
--@param limit The number of results to be returned
--@param offset The number of records to skip before returning results
--@return True if set is successful, false otherwise
function alert_store:add_limit(limit, offset)
   if not self._limit and tonumber(limit) then
      self._limit = limit

      if not self._offset and tonumber(offset) then
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
   if not self._order_by and self:_valid_fields(fields) then
      self._order_by = fields
      return true
   end

   return false
end

-- ##############################################

function alert_store:group_by(fields)
   if not self._group_by and self:_valid_fields(fields) then
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

function alert_store:select_historical(filter, fields)
   local res = {}
   local where_clause = ''
   local group_by_clause = ''
   local order_by_clause = ''
   local limit_clause = ''
   local offset_clause = ''

   -- TODO handle fields (e.g. add entity value to WHERE)

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

--@brief Selects engaged alerts from memory
--@return Selected engaged alerts, and the total number of engaged alerts
function alert_store:select_engaged(filter)
   local alert_id_filter = tonumber(self._alert_id)
   local severity_filter = tonumber(self._alert_severity)
   local entity_id_filter = tonumber(self._alert_entity and self._alert_entity.entity_id) -- Possibly set in subclasses constructor
   local entity_value_filter = filter

   -- tprint(string.format("id=%s sev=%s entity=%s val=%s", alert_id_filter, severity_filter, entity_id_filter, entity_value_filter))
   local alerts = interface.getEngagedAlerts(entity_id_filter, entity_value_filter, alert_id_filter, severity_filter)
   local total_rows = #alerts
   local sort_2_col = {}

   -- Sort
   for idx, alert in pairs(alerts) do
      if sortColumn == "alert_id" then
	 sort_2_col[idx] = alert.alert_type
      elseif sortColumn == "severity" then
	 sort_2_col[idx] = alert.alert_severity
      elseif sortColumn == "column_duration" then
	 sort_2_col[idx] = os.time() - alert.alert_tstamp
      else -- column_date
	 sort_2_col[idx] = alert.alert_tstamp
      end
   end

   -- Pagination
   local offset = self._offset or 0        -- The offset, or zero (start from the beginning) if no offset is set
   local limit = self._limit or total_rows -- The limit, or the actual number of records, ie., no limit

   local res = {}
   local i = 0

   for idx in pairsByValues(sort_2_col, asc --[[ TODO --]]) do
      if i >= offset + limit then
	 break
      end

      if i >= offset then
	 res[#res + 1] = alerts[idx]
      end

      i = i + 1
   end

   return res, total_row
end

-- ##############################################

--@brief Handle alerts select request (GET) from memory (engaged) or database (historical)
--@param filter A filter on the entity value (no filter by default)
--@param select_fields The fields to be returned (all by default or in any case for engaged)
--@return Selected alerts, and the total number of alerts
function alert_store:select_request(filter, select_fields)

   -- Add filters
   self:add_request_filters()

   if self.engaged then -- Engaged

      -- Add limits and sort criteria
      self:add_request_ranges()

      return self:select_engaged(filter)

   else -- Historical
      
      -- Count
      local total_row = self:count()

      -- Add limits and sort criteria only after the count has been done
      self:add_request_ranges()

      local res = self:select_historical(filter, select_fields)
      return res, total_row
   end
end

-- ##############################################

--@brief Performs a query and counts the number of records
function alert_store:count()
   local count_query = self:select_historical(nil, "count(*) as count")
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

--@brief Possibly overridden in subclasses to add additional filters from the request
function alert_store:_add_additional_request_filters()
end

-- ##############################################

--@brief Add filters according to what is specified inside the REST API
function alert_store:add_request_filters()
   local epoch_begin = tonumber(_GET["epoch_begin"])
   local epoch_end = tonumber(_GET["epoch_end"])
   local alert_type = _GET["alert_type"]
   local alert_severity = _GET["alert_severity"]
   local status = _GET["status"]

   self:add_time_filter(epoch_begin, epoch_end)
   self:add_alert_id_filter(alert_type)
   self:add_alert_severity_filter(alert_severity)
   self:add_status_filter(status and status == 'engaged')
   self:_add_additional_request_filters()
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

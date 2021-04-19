--
-- (C) 2020 - ntop.org
--
local dirs = ntop.getDirs()
package.path = dirs.installdir .. "/scripts/lua/modules/?.lua;" .. package.path

require "lua_utils"
local page_utils = require "page_utils"
local ui_utils = require "ui_utils"
local json = require "dkjson"
local template_utils = require "template_utils"
local widget_gui_utils = require "widget_gui_utils"
local Datasource = widget_gui_utils.datasource

local ifid = interface.getId()

local CHART_NAME = "alert-timeseries"

-- select the default page
local page = _GET["page"] or 'host'
local status = _GET["status"] or "historical"

local time = os.time()
local epoch_begin = _GET["epoch_begin"] or time - 3600
local epoch_end = _GET["epoch_end"] or time

sendHTTPContentTypeHeader('text/html')

page_utils.set_active_menu_entry(page_utils.menu_entries.detected_alerts)

-- append the menu above the page
dofile(dirs.installdir .. "/scripts/lua/inc/menu.lua")

local url = ntop.getHttpPrefix() .. "/lua/alert_stats.lua?"
page_utils.print_navbar(i18n("alerts_dashboard.alerts"), url, {
    {
        active = page == "host",
        page_name = "host",
        label = i18n("hosts"),
    },
    {
        active = page == "mac",
        page_name = "mac",
        label = i18n("report.local_networks"),
    },
    {
        active = page == "snmp_device",
        page_name = "snmp_device",
        label = i18n("snmp.snmp_devices"),
    },
    {
        active = page == "flow",
        page_name = "flow",
        label = i18n("flows"),
    },
    {
        active = page == "system",
        page_name = "system",
        label = i18n("system"),
    },
    {
        active = page == "active_monitoring",
        page_name = "active_monitoring",
        label = i18n("active_monitoring_stats.active_monitoring"),
    },
})

widget_gui_utils.register_timeseries_bar_chart(CHART_NAME, 0, {
    Datasource(string.format("/lua/rest/v1/get/%s/alert/ts.lua", page), {
        ifid = ifid,
        epoch_begin = epoch_begin,
        epoch_end = epoch_end,
        status = status
    })
})

local modals = {
    ["delete_alert_dialog"] = template_utils.gen("modal_confirm_dialog.html", {
        dialog = {
         id      = "delete_alert_dialog",
         title   = i18n("show_alerts.delete_alert"),
         message = i18n("show_alerts.confirm_delete_alert") .. '?',
         confirm = i18n("delete"),
         confirm_button = "btn-danger",
         custom_alert_class = "alert alert-danger"
        }
    })
}

local context = {
    template_utils = template_utils,
    json = json,
    ui_utils = ui_utils,
    widget_gui_utils = widget_gui_utils,
    range_picker = {
        -- ?
    },
    chart = {
        name = CHART_NAME
    },
    datatable = {
        name = page .. "-alerts-table",
        initialLength = getDefaultTableSize(),
        table = template_utils.gen(string.format("pages/alerts/families/%s/table.template", page), {}),
        js_columns = template_utils.gen(string.format("pages/alerts/families/%s/table.js.template", page), {}),
        datasource = Datasource(string.format("/lua/rest/v1/get/%s/alert/list.lua", page), {
            ifid = ifid,
            epoch_begin = epoch_begin,
            epoch_end = epoch_end,
            status = status
        }),
        modals = modals,
    },
    alert_stats = {
        entity = page,
        status = status
    }
}

template_utils.render("pages/alerts/alert-stats.template", context)

-- append the menu down below the page
dofile(dirs.installdir .. "/scripts/lua/inc/footer.lua")

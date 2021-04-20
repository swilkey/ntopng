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
local tag_utils = require "tag_utils"
local Datasource = widget_gui_utils.datasource

local IFID = interface.getId()
local CHART_NAME = "alert-timeseries"

-- select the default page
local page = _GET["page"] or 'host'
local status = _GET["status"] or "historical"

local time = os.time()

-- initial epoch_begin is set as now - 30 minutes
local epoch_begin = _GET["epoch_begin"] or time - 1800
local epoch_end = _GET["epoch_end"] or time

--------------------------------------------------------------

local l7_proto = _GET["l7_proto"]
local cli_ip = _GET["cli_ip"]
local srv_ip = _GET["srv_ip"]
local host_ip = _GET["ip"]

--------------------------------------------------------------

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
        label = i18n("discover.device"),
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
        ifid = IFID,
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
            custom_alert_class = "alert alert-danger",
            no_confirm_id = true
        }
    }),
    ["host_alerts_filter_dialog"] = template_utils.gen("modal_host_alerts_filter_dialog.html", {
        dialog = {
            id = "host_alerts_filter_dialog",
            title = i18n("show_alerts.filter_alert"),
            message	= i18n("show_alerts.confirm_filter_alert"),
            delete_message = i18n("show_alerts.confirm_delete_filtered_alerts"),
            delete_alerts = i18n("delete_disabled_alerts"),
            alert_filter = "default_filter",
            confirm = i18n("filter"),
            confirm_button = "btn-warning",
            custom_alert_class = "alert alert-warning"
        }
    }),
    ["release_single_alert"] = template_utils.gen("modal_confirm_dialog.html", {
        dialog = {
            id      = "release_single_alert",
            action  = "releaseAlert(alert_to_release)",
            title   = i18n("show_alerts.release_alert"),
            message = i18n("show_alerts.confirm_release_alert"),
            confirm = i18n("show_alerts.release_alert_action"),
            confirm_button = "btn-primary",
            custom_alert_class = "alert alert-primary"
        }
    })
}

local defined_tags = {
    ["host"] = {
        ip = {'eq'}
    },
    ["mac"] = {
    },
    ["snmp_device"] = {

    },
    ["flow"] = {
        l7_proto  = {'eq'},
        cli_ip = {'eq'},
        srv_ip = {'eq'}
    },
    ["system"] = {

    },
    ["active_monitoring"] = {

    }
}

local initial_tags = {}

for tag_key, tag in pairs(defined_tags[page]) do
    tag_utils.add_tag_if_valid(initial_tags, tag_key, tag, {})
end

local context = {
    template_utils = template_utils,
    json = json,
    ui_utils = ui_utils,
    widget_gui_utils = widget_gui_utils,
    ifid = IFID,
    range_picker = {
        tags = {
            tag_operators = {tag_utils.tag_operators.eq},
            defined_tags = defined_tags[page],
            values = initial_tags,
            i18n = {
                l7_proto = i18n("tags.l7proto"),
                cli_ip = i18n("tags.cli_ip"),
                srv_ip = i18n("tags.srv_ip"),
                ip = i18n("tags.ip")
            }
        },
        presets = {
            five_mins = false,
            month = false,
            year = false
        }
    },
    chart = {
        name = CHART_NAME
    },
    datatable = {
        name = page .. "-alerts-table",
        initialLength = getDefaultTableSize(),
        table = template_utils.gen(string.format("pages/alerts/families/%s/table.template", page), {}),
        js_columns = template_utils.gen(string.format("pages/alerts/families/%s/table.js.template", page), {}),
        -- TODO: refactor the datasource
        datasource = Datasource(string.format("/lua/rest/v1/get/%s/alert/list.lua", page), {
            ifid = IFID,
            epoch_begin = epoch_begin,
            epoch_end = epoch_end,
            status = status,
            cli_ip = cli_ip,
            srv_ip = srv_ip,
            l7_proto = l7_proto,
            ip = host_ip
        }),
        actions = {
            disable = (page ~= "host" and page ~= "flow")
        },
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

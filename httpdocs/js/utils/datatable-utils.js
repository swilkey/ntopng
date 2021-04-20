/**
 * (C) 2020-21 - ntop.org
 */

jQuery.fn.dataTableExt.sErrMode = 'console';
jQuery.fn.dataTableExt.formatSecondsToHHMMSS = (data, type, row) => {
    if (isNaN(data)) return data;
    if (type == "display" && data <= 0) return ' ';
    if (type == "display") return NtopUtils.secondsToTime(data);
    return data;
};
jQuery.fn.dataTableExt.absoluteFormatSecondsToHHMMSS = (data, type, row) => {

    if (isNaN(data)) return data;
    if (type == "display" && (data <= 0)) return ' ';

    const delta = Math.floor(Date.now() / 1000) - data;
    if (type == "display") return NtopUtils.secondsToTime(delta);
    return data;
};
jQuery.fn.dataTableExt.sortBytes = (byte, type, row) => {
    if (type == "display") return NtopUtils.bytesToSize(byte);
    return byte;
};
jQuery.fn.dataTableExt.hideIfZero = (value, type, row) => {
    if (type === "display" && parseInt(value) === 0) return "";
    return value;
};
jQuery.fn.dataTableExt.showProgress = (percentage, type, row) => {
    if (type === "display") {
        const fixed = percentage.toFixed(1)
        return `
        <div class="d-flex align-items-center">
        <span class="progress w-100">
          <span class="progress-bar bg-warning" role="progressbar" style="width: ${fixed}%" aria-valuenow="${fixed}" aria-valuemin="0" aria-valuemax="100"></span>
        </span>
        <span>${fixed}%</span>
        </div>
        `
    }
    return percentage;
};
//https://datatables.net/forums/discussion/44885
$.fn.dataTable.Api.registerPlural( 'columns().names()', 'column().name()', function ( setter ) {
    return this.iterator( 'column', function ( settings, column ) {
        var col = settings.aoColumns[column];
 
        if ( setter !== undefined ) {
            col.sName = setter;
            return this;
        }
        else {
            return col.sName;
        }
    }, 1 );
} );

class DataTableFiltersMenu {

    /**
     *
     * @param {options}
     */
    constructor({ tableAPI, filterMenuKey, filterTitle, filters, columnIndex }) {
        this.rawFilters = filters;
        this.tableAPI = tableAPI;
        this.filterTitle = filterTitle;
        this.filterMenuKey = filterMenuKey;
        this.columnIndex = columnIndex;
        this.preventUpdate = false;
        this.currentFilterSelected = undefined;
        this.$datatableWrapper = $(tableAPI.context[0].nTableWrapper);
    }

    get selectedFilter() {
        return this.currentFilterSelected;
    }

    init() {

        const self = this;

        // when the datatable has been initialized render the dropdown
        this.$datatableWrapper.on('init.dt', function () {
            self._render(self.rawFilters);
        });

        // on ajax reload then update the datatable entries
        this.tableAPI.on('draw', function () {
            self._update();
        });

        return self;
    }

    _countEntries(regex, data = []) {

        if (regex === undefined) {
            console.error("DataTableFiltersMenu::_countEntries() => the passed regex is undefined!");
        }

        const reg = new RegExp(regex);
        return data.filter(cellValue => reg.test(cellValue)).length;
    }

    _createMenuEntry(filter) {

        const self = this;
        const $entry = $(`<li class='dropdown-item pointer'>${filter.label} </li>`);

        if (filter.countable === undefined || filter.countable) {

            const data = this.tableAPI.columns(this.columnIndex).data()[0];
            const count = this._countEntries(filter.regex, data);
            const $counter = $(`<span class='counter'>(${count})</span>`);

            // if the count is 0 then hide the menu entry
            if (count == 0) $entry.hide();

            //append the $counter object inside the $entry
            $entry.append($counter);
        }

        $entry.click(function (e) {

            self.preventUpdate = true;

            // set active filter title and key
            if (self.$dropdown.title.parent().find(`i.fas`).length == 0) {
                self.$dropdown.title.parent().prepend(`<i class='fas fa-filter'></i>`);
            }

            const newContent = $entry.html();
            self.$dropdown.title.html(newContent);
            // remove the active class from the li elements
            self.$dropdown.container.find('li').removeClass(`active`);
            // add active class to current entry
            $entry.addClass(`active`);
            // if the filter have a callback then call it
            if (filter.callback) filter.callback();
            // perform the table filtering
            self.tableAPI.column(self.columnIndex).search(filter.regex, true, false).draw();
            // set current filter
            self.currentFilterSelected = filter;
        });

        return $entry;
    }

    _createFilters(filters) {

        const filtersCreated = {};

        // for each filter defined in this.filters
        for (const filter of filters) {

            const $filter = this._createMenuEntry(filter);
            // save the filter inside the $filters object
            filtersCreated[filter.key] = { filter: filter, $node: $filter };
        }

        return filtersCreated;
    }

    _render(filters) {

        const $dropdownContainer = $(`<div id='${this.filterMenuKey}-filters' class='dropdown d-inline'></div>`);
        const $dropdownButton = $(`<button class='btn-link btn dropdown-toggle' data-toggle='dropdown' type='button'></button>`);
        const $dropdownTitle = $(`<span class='filter-title'>${this.filterTitle}</span>`);
        $dropdownButton.append($dropdownTitle);

        this.filters = this._createFilters(filters);

        this.$dropdown = {
            container: $dropdownContainer,
            title: $dropdownTitle,
            button: $dropdownButton
        };

        const $menuContainer = $(`<ul class='dropdown-menu scrollable-dropdown' id='${this.filterMenuKey}-filter-menu'></ul>`);
        for (const [_, filter] of Object.entries(this.filters)) {
            $menuContainer.append(filter.$node);
        }

        // the All entry is created by the object
        const allFilter = this._generateAllFilter();

        $menuContainer.prepend(this._createMenuEntry(allFilter));

        // append the created dropdown inside
        $dropdownContainer.append($dropdownButton);
        $dropdownContainer.append($menuContainer);
        // append the dropdown menu inside the filter wrapper
        $dropdownContainer.insertBefore(this.$datatableWrapper.find('.dataTables_filter').parent());

        this._selectFilterFromState(this.filterMenuKey);
    }

    _selectFilterFromState(filterKey) {

        if (!this.tableAPI.state) return;
        if (!this.tableAPI.state.loaded()) return;
        if (!this.tableAPI.state.loaded().filters) return;

        // save the current table state
        tableAPI.state.save();
    }

    _generateAllFilter() {
        return {
            key: 'all',
            label: i18n.all,
            regex: '',
            countable: false,
            callback: () => {
                this.$dropdown.title.parent().find('i.fas.fa-filter').remove();
                this.$dropdown.title.html(`${this.filterTitle}`);
            }
        };
    }

    _update() {

        // if the filters have not been initialized by _render then return
        if (this.filters === undefined) return;
        if (this.preventUpdate) {
            this.preventUpdate = false;
            return;
        }

        for (const [_, filter] of Object.entries(this.filters)) {
            if (filter.countable == false) continue;

            const data = this.tableAPI.columns(this.columnIndex).data()[0];
            const count = this._countEntries(filter.filter.regex, data);

            // hide the filter if the count is zero
            (count == 0) ? filter.$node.hide() : filter.$node.show();
            // update the counter label
            filter.$node.find('.counter').text(`(${count})`);
            // update the selected button counter
            this.$dropdown.button.find('.counter').text(`(${count})`);
        }
    }

}

class DataTableRangeFiltersMenu extends DataTableFiltersMenu {

    constructor(params) {

        super(params);

        const self = this;
        this.selectedMin = Number.MIN_VALUE;
        this.selectedMax = Number.MAX_VALUE;

        $.fn.dataTable.ext.search.push(
            function (settings, data, dataIndex) {

                const min = self.selectedMin || Number.MIN_VALUE;
                const max = self.selectedMax || Number.MAX_VALUE;

                const currentValue = parseFloat(data[params.columnIndex]) || 0;

                return ((isNaN(min) && isNaN(max)) ||
                    (isNaN(min) && currentValue <= max) ||
                    (min <= currentValue && isNaN(max)) ||
                    (min <= currentValue && currentValue <= max));
            }
        );

        this.tableAPI.draw();
        params.rawFilters = params.filters.map((filter) => {

            filter.regex = '';
            filter.min = filter.min || Number.MIN_VALUE;
            filter.max = filter.max || Number.MAX_VALUE;
            filter.countable = false;

            filter.callback = () => {
                self.selectedMax = filter.max;
                self.selectedMin = filter.min;
                self.tableAPI.draw();
            };

            return filter;
        });

    }

    _generateAllFilter() {
        const all = super._generateAllFilter();
        const oldCallback = all.callback;
        all.callback = () => {
            oldCallback();
            this.selectedMin = Number.MIN_VALUE;
            this.selectedMax = Number.MAX_VALUE;
            this.tableAPI.draw();
        }
        return all;
    }

}

class DataTableUtils {

    /**
     * Return a standard config for the Sprymedia (c) DataTables
     */
    static getStdDatatableConfig(dtButtons = [], dom = "<'d-flex flex-wrap'<'mr-auto'l><'dt-search'f>B>rtip") {

        // hide the buttons section if there aren't buttons inside the array
        if (dtButtons.length == 0) {
            dom = "fBrtip";
        }

        return {
            dom: dom,
            pagingType: 'full_numbers',
            lengthMenu: [[10, 25, 50, -1], [10, 25, 50, `${i18n.all}`]],
            language: {
                info: i18n.showing_x_to_y_rows,
                search: i18n.script_search,
                infoFiltered: "",
                paginate: {
                    previous: '&lt;',
                    next: '&gt;',
                    first: '«',
                    last: '»'
                }
            },
            saveState: true,
            responsive: true,
            buttons: {
                buttons: dtButtons,
                dom: {
                    button: {
                        className: 'btn btn-link'
                    },
                    container: {
                        className: 'border-left ml-1 d-flex flex-md-row'
                    }
                }
            }
        }
    }

    /**
     * Example of action:
     * {
     *  class: string,
     *  data: object,
     *  icon: string,
     *  modal: string,
     *  href: string,
     *  hidden: bool,
     * }
     * @param {*} actions
     */
    static createActionButtons(actions = []) {

        const buttons = [];
        actions.forEach((action) => {

            let button = (`
                <a
                    ${(action.href || action.modal) ? `href='${action.href || action.modal}'` : ``}
                    ${(action.onclick) ? `onclick='${action.onclick}'` : ``}
                    data-placement='bottom'
                    ${action.modal ? "data-toggle='modal'" : ``}
                    class='btn btn-sm ${action.class}'
                    ${action.hidden ? "style='display: none'" : ``}
                    ${action.external ? "target='_about'" : ``}
                    ${action.title ? `title='${action.title}'` : ``}
                    >
                    <i class='fas ${action.icon}'></i>
                </a>
            `);

            // add a wrapper for the disabled button to show a tooltip
            // if (action.class.contains("disabled")) {
            //    button = `<span class='d-inline-block' data-placement='bottom' ${action.title ? `title='${action.title}'` : ""}>${button}</span>`;
            //}

            buttons.push(button);
        });

        return (`<div class='actions-group' role='group'>${buttons.join('')}</div>`);
    }

    static setAjaxConfig(config, url, dataSrc = '', method = "get", params = {}) {

        config.ajax = {
            url: url,
            type: method,
            dataSrc: dataSrc,
            data: function (d) {
                return $.extend({}, d, params);
            }
        }

        return config;
    }

    static extendConfig(config, extension) {

        // if there are custom filters then manage state in this way
        if (extension.hasFilters) {

            extension.stateSaveCallback = function (settings, data) {
                localStorage.setItem('DataTables_' + settings.sInstance, JSON.stringify(data))
            };

            extension.stateLoadCallback = function (settings) {
                return JSON.parse(localStorage.getItem('DataTables_' + settings.sInstance));
            };

            // on saving the table state store the selected filters
            extension.stateSaveParams = function (settings, data) {

                // save the filters selected from the user inside the state
                $('[data-filter]').each(function () {

                    const activeFilter = $(this).find(`li.active`).data('filter-key');
                    if (!activeFilter) return;

                    // if the filters object is not allocated then initizializes it
                    if (!data.filters) data.filters = {};
                    data.filters[$(this).data('filter')] = activeFilter;

                });
            };
        }

        // const userInitComplete = extension.initComplete;

        // const initComplete = (settings, json) => {
        //     if (userInitComplete !== undefined) userInitComplete(settings, json);
        //     // turn on tooltips
        //     $(`.actions-group [title]`).tooltip('enable');
        // };

        // // override initComplete function
        // extension.initComplete = initComplete;

        return $.extend({}, config, extension);
    }

    /**
     * Format the passed seconds into the "HH:MM:SS" string.
     * @param {number} seconds
     */
    static secondsToHHMMSS(seconds) {

        const padZeroes = n => `${n}`.padStart(2, '0');

        const sec = seconds % 60;
        const mins = Math.floor(seconds / 60) % 60;
        const hours = Math.floor(seconds / 3600);

        return `${padZeroes(hours)}:${padZeroes(mins)}:${padZeroes(sec)}`;
    }

    /**
    * Open the pool edit modal of a chosen pool if the query params contains the pool paramater
    * @param tableAPI
    */
    static openEditModalByQuery(params) {

        const urlParams = new URLSearchParams(window.location.search);
        if (!urlParams.has(params.paramName)) return;

        const dataID = urlParams.get(params.paramName);
        const data = params.datatableInstance.data().toArray().find((data => data[params.paramName] == dataID));

        // if the cancelIf param has been passed
        // then test the cancelIf function, if the return value
        // is true then cancel the modal opening
        if (typeof (params.cancelIf) === 'function') {
            if (params.cancelIf(data)) return;
        }

        const $modal = $(`#${params.modalHandler.getModalID()}`);

        // if the pool id is valid then open the edit modal
        if (data !== undefined) {
            params.modalHandler.invokeModalInit(data);
            $modal.modal('show');
        }

        if (!urlParams.has('referer')) {
            $modal.on('hidden.bs.modal', function (e) {

                const url = new URL(window.location.href);
                url.searchParams.delete(params.paramName);

                history.replaceState({}, '', url.toString());
            });
            return;
        }
        const referer = urlParams.get('referer');

        $modal.on('hidden.bs.modal', function (e) {
            window.location = referer;
        });
    }

    static addToggleColumnsDropdown(tableAPI, toggleCallback = (col, visible) => {}) {

        if (tableAPI === undefined) {
            throw 'The $table is undefined!';
        }

        const tableID = tableAPI.table().node().id;

        DataTableUtils._loadColumnsVisibility(tableAPI).then(function (fetchedData) {

            let savedColumns = [-1];
            if (fetchedData.success) {
                savedColumns = fetchedData.columns.map(i => parseInt(i));
            }
            else {
                console.warn(fetchedData.message);
            }

            const columns = [];
            const ignoredColumns = [];
            const $datatableWrapper = $(tableAPI.context[0].nTableWrapper);

            // get the table headers 
            tableAPI.columns().every(function (i) {

                // avoid already hidden columns
                if (!tableAPI.column(i).visible()) {
                    ignoredColumns.push(i);
                    return;
                }

                columns.push({ index: i, name: this.header().textContent });
            });

            const $btnGroup = $(`
                <div class="btn-group">
                    <button type="button" class="btn btn-link dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                        <i class="fas fa-eye"></i>
                    </button>
                </div>
            `);

            const $dropdownMenu = $(`<div class="dropdown-menu dropdown-menu-right" style='width: max-content;'><h6 class="dropdown-header">Show Columns</h6></div>`);
            const $checkboxes = $(`<div class='px-4'></div>`);

            for (let i = 0; i < columns.length; i++) {

                const column = columns[i];

                // create a checkbox and delegate a change event
                const id = `toggle-${column.name.split().join('_')}`; 

                // check if the column id it's inside the savedColumns array
                // if toggled is true then the column is not hidden
                const toggled = savedColumns.indexOf(column.index) === -1;
                if (!toggled) {
                    const col = tableAPI.column(column.index);
                    col.visible(false);
                }

                const $checkbox = $(`<input class="custom-control-input" ${(toggled ? 'checked' : '')} type="checkbox" id="${id}">`)
                const $wrapper = $(`
                    <div class="custom-control custom-switch">
                        <label class="custom-control-label" for="${id}">
                            ${column.name}
                        </label>
                    </div>
                `);

                $checkbox.on('change', function (e) {
                    
                    // Get the column API object
                    const col = tableAPI.column(column.index);
                    // Toggle the visibility
                    col.visible(!col.visible());

                    const visible = col.visible();

                    const hiddenColumns = [];
                    // insert inside the array only the hidden columns
                    tableAPI.columns().every(function(i) {
                        if (tableAPI.column(i).visible() || ignoredColumns.indexOf(i) !== -1) return;
                        hiddenColumns.push(i); 
                    });

                    // save the table view inside redis
                    $.post(`${http_prefix}/lua/datatable_columns.lua`, {
                        action: 'save', table: tableID, columns: hiddenColumns.join(','), csrf: window.__CSRF_DATATABLE__
                    }).then(function(data) {
                        if (data.success) return;
                        console.warn(data.message);
                    });

                    if (toggleCallback !== undefined) {
                        toggleCallback(col, visible);
                    }

                });

                $wrapper.prepend($checkbox);
                $checkboxes.append($wrapper);
            }

            $dropdownMenu.on("click.bs.dropdown", function (e) { e.stopPropagation(); });

            // append the new node inside the datatable
            $btnGroup.append($dropdownMenu.append($checkboxes));
            $datatableWrapper.find('.dt-search').parent().append($btnGroup);
        });
    }

    static async _loadColumnsVisibility(tableAPI) {
        const tableID = tableAPI.table().node().id;
        return $.get(`${http_prefix}/lua/datatable_columns.lua?table=${tableID}&action=load`);
    }

}

class DataTableRenders {

    static hideIfZero(value, type, row) {
        if (type === "display" && parseInt(value) === 0) return "";
        return value;
    }

    static secondsToTime(seconds, type, row) {
        if (type === "display") return NtopUtils.secondsToTime(seconds);
        return seconds;
    }

    static filterize(value, label) {
        return `<a class='tag-filter' data-tag-value='${value}' href='#'>${label || value}</a>`;
    }

    static formatValueLabel(obj, type, row) {
        if (type !== "display") return obj.value;
        return obj.label;
    }

}
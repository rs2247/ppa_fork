(function() {
  'use strict';

  var globals = typeof global === 'undefined' ? self : global;
  if (typeof globals.require === 'function') return;

  var modules = {};
  var cache = {};
  var aliases = {};
  var has = {}.hasOwnProperty;

  var expRe = /^\.\.?(\/|$)/;
  var expand = function(root, name) {
    var results = [], part;
    var parts = (expRe.test(name) ? root + '/' + name : name).split('/');
    for (var i = 0, length = parts.length; i < length; i++) {
      part = parts[i];
      if (part === '..') {
        results.pop();
      } else if (part !== '.' && part !== '') {
        results.push(part);
      }
    }
    return results.join('/');
  };

  var dirname = function(path) {
    return path.split('/').slice(0, -1).join('/');
  };

  var localRequire = function(path) {
    return function expanded(name) {
      var absolute = expand(dirname(path), name);
      return globals.require(absolute, path);
    };
  };

  var initModule = function(name, definition) {
    var hot = hmr && hmr.createHot(name);
    var module = {id: name, exports: {}, hot: hot};
    cache[name] = module;
    definition(module.exports, localRequire(name), module);
    return module.exports;
  };

  var expandAlias = function(name) {
    var val = aliases[name];
    return (val && name !== val) ? expandAlias(val) : name;
  };

  var _resolve = function(name, dep) {
    return expandAlias(expand(dirname(name), dep));
  };

  var require = function(name, loaderPath) {
    if (loaderPath == null) loaderPath = '/';
    var path = expandAlias(name);

    if (has.call(cache, path)) return cache[path].exports;
    if (has.call(modules, path)) return initModule(path, modules[path]);

    throw new Error("Cannot find module '" + name + "' from '" + loaderPath + "'");
  };

  require.alias = function(from, to) {
    aliases[to] = from;
  };

  var extRe = /\.[^.\/]+$/;
  var indexRe = /\/index(\.[^\/]+)?$/;
  var addExtensions = function(bundle) {
    if (extRe.test(bundle)) {
      var alias = bundle.replace(extRe, '');
      if (!has.call(aliases, alias) || aliases[alias].replace(extRe, '') === alias + '/index') {
        aliases[alias] = bundle;
      }
    }

    if (indexRe.test(bundle)) {
      var iAlias = bundle.replace(indexRe, '');
      if (!has.call(aliases, iAlias)) {
        aliases[iAlias] = bundle;
      }
    }
  };

  require.register = require.define = function(bundle, fn) {
    if (bundle && typeof bundle === 'object') {
      for (var key in bundle) {
        if (has.call(bundle, key)) {
          require.register(key, bundle[key]);
        }
      }
    } else {
      modules[bundle] = fn;
      delete cache[bundle];
      addExtensions(bundle);
    }
  };

  require.list = function() {
    var list = [];
    for (var item in modules) {
      if (has.call(modules, item)) {
        list.push(item);
      }
    }
    return list;
  };

  var hmr = globals._hmr && new globals._hmr(_resolve, require, modules, cache);
  require._cache = cache;
  require.hmr = hmr && hmr.wrap;
  require.brunch = true;
  globals.require = require;
})();

(function() {
var global = typeof window === 'undefined' ? this : window;
var process;
var __makeRelativeRequire = function(require, mappings, pref) {
  var none = {};
  var tryReq = function(name, pref) {
    var val;
    try {
      val = require(pref + '/node_modules/' + name);
      return val;
    } catch (e) {
      if (e.toString().indexOf('Cannot find module') === -1) {
        throw e;
      }

      if (pref.indexOf('node_modules') !== -1) {
        var s = pref.split('/');
        var i = s.lastIndexOf('node_modules');
        var newPref = s.slice(0, i).join('/');
        return tryReq(name, newPref);
      }
    }
    return none;
  };
  return function(name) {
    if (name in mappings) name = mappings[name];
    if (!name) return;
    if (name[0] !== '.' && pref) {
      var val = tryReq(name, pref);
      if (val !== none) return val;
    }
    return require(name);
  }
};
require.register("web/static/js/sales-report.js", function(exports, require, module) {
"use strict";

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _datepicker = require("./components/datepicker");

var _datepicker2 = _interopRequireDefault(_datepicker);

var _moment = require("moment");

var _moment2 = _interopRequireDefault(_moment);

var _ajax = require("./components/ajax");

var _ajax2 = _interopRequireDefault(_ajax);

var _authentication = require("./components/authentication");

var _authentication2 = _interopRequireDefault(_authentication);

var _datatable = require("./components/datatable");

var _datatable2 = _interopRequireDefault(_datatable);

var _universityFilter = require("./components/universityFilter");

var _universityFilter2 = _interopRequireDefault(_universityFilter);

var _jquery = require("jquery");

var _jquery2 = _interopRequireDefault(_jquery);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var select2 = require('select2')();

var PAGE_URL = 'sales_stats';

var SalesReportPage = function () {
  function SalesReportPage() {
    _classCallCheck(this, SalesReportPage);
  }

  _createClass(SalesReportPage, [{
    key: "setup",
    value: function setup() {
      var _this = this;

      this.$levelFilterSelect = (0, _jquery2.default)('.js-levels-multi-select');
      this.$levelFilterSelect.select2({ width: "resolve", height: "resolve", placeholder: "Todos" });
      this.$kindFilterSelect = (0, _jquery2.default)('.js-kinds-multi-select');
      this.$kindFilterSelect.select2({ width: "resolve", height: "resolve", placeholder: "Todos" });
      this.startDatePicker = new _datepicker2.default("start-date");
      this.endDatePicker = new _datepicker2.default("end-date");
      this.removeWhitelabelsCheckbox = (0, _jquery2.default)("#remove-whitelabels");
      this.universityFilter = new _universityFilter2.default();

      (0, _jquery2.default)("#filters-form").submit(function (evt) {
        evt.preventDefault();
        _this.updateReport();
      });

      this.updateRequest = new _ajax2.default({
        url: "/" + PAGE_URL + "/generate",
        onSuccess: function onSuccess() {
          return _this.afterShowReport();
        },
        onLoadOverlayElement: (0, _jquery2.default)(".report-panel")
      });
      this.loadInitialFilterValues();
      this.universityFilter.loadInitialValues();
      this.afterShowReport();
    }
  }, {
    key: "loadInitialFilterValues",
    value: function loadInitialFilterValues() {
      var yesterday = (0, _moment2.default)().subtract(1, 'days').toDate();
      var sixMonthsBehind = (0, _moment2.default)().subtract(1, 'days').subtract(6, 'months').toDate();

      var startDate = (0, _jquery2.default)("#initial-start-date").val() || sixMonthsBehind;
      var endDate = (0, _jquery2.default)("#initial-end-date").val() || yesterday;
      this.startDatePicker.setDate(startDate);
      this.endDatePicker.setDate(endDate);
    }
  }, {
    key: "updateReport",
    value: function updateReport() {
      var data = this.collectParameters();
      console.log("Filter Data: " + JSON.stringify(data));
      (0, _jquery2.default)("#update-btn").attr('disabled', '');
      this.updateRequest.getAndRenderPartial(data, (0, _jquery2.default)("#report-container"));
      this.updatePageHistory(data);
    }
  }, {
    key: "updatePageHistory",
    value: function updatePageHistory(data) {
      var params = _jquery2.default.param(data);
      window.history.pushState("", "", PAGE_URL + "?" + params);
    }
  }, {
    key: "collectParameters",
    value: function collectParameters() {
      console.log(this.startDatePicker.getValue());
      return {
        start_date: this.startDatePicker.getValue(),
        end_date: this.endDatePicker.getValue(),
        university_filter_type: this.universityFilter.universityTypeDropdown.getSelectedValue(),
        university_id: this.universityFilter.universityAutocomplete.getSelectedValue(),
        education_group_id: this.universityFilter.educationGroupAutocomplete.getSelectedValue(),
        admin_id: _authentication2.default.getCurrentUserId(),
        remove_whitelabels: this.removeWhitelabelsCheckbox.is(":checked"),
        level: this.$levelFilterSelect.val(),
        kind: this.$kindFilterSelect.val()
      };
    }
  }, {
    key: "afterShowReport",
    value: function afterShowReport() {
      this.dataTable = new _datatable2.default('#report-table', {
        paging: true,
        deferRender: true,
        pageLength: 10,
        order: [0, 'asc']
      });
      (0, _jquery2.default)("#update-btn").removeAttr('disabled');
    }
  }]);

  return SalesReportPage;
}();

window.salesReportPage = new SalesReportPage();
});

require.alias("buffer/index.js", "buffer");
require.alias("process/browser.js", "process");process = require('process');require.register("___globals___", function(exports, require, module) {
  

// Auto-loaded modules from config.npm.globals.
window.Vue = require("vue/dist/vue.js");


});})();require('___globals___');


//# sourceMappingURL=sales-report.js.map
// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
import 'phoenix_html';

// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".

// Import local files
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".
import { socket, joinSingleChannel } from "./socket"

import _ from 'lodash';
import Logging from "./logging";
import NavBar from "./components/navbar"
import Dropdown from './components/dropdown';
import "./farm-panel"
import "./key-accounts"
import "./sales-report"
import "./competitors-flow"
import "./university-charts"
import "./foe-stock"
import "./utils/string"
import "./utils/object"
import "./universities"
import "./import-university-goals"
import "./panel-app"
import "./user-home"
import "./analysis-panel"
import "./stock-panel"
import "./inep-share"
import "./ies-stats"
import "./billing-panel"
import "./courses-panel"
import "./competitors-panel"
import "./quality-stats"
import "./comparing-panel"
import "./demand-curves"
import "./pricing-panel"
import "./cpfs-panel"
import "./search-ranking-panel"
import "./bo-panel"
import "./refund-panel"
import "./inep-entrants"
import "./sold-courses-panel"
import "./farm-ranking"
import "./inep-panel"
import "./farm-universities"
import "./farm-key-accounts"
import "./offers-panel"
import "./paids-panel"
import "./pricing-campaign-panel"
import "./quali-panel"
import "./ies-panel"
import "./farm-campaign"
import "./quali-campaign"
import "./search-shows-panel"
import "./dashboard-app"
import "./crawler-panel"
import "./search-simulator"
import "./funnel-panel"
import "./farm-quality-owners"

// Set log level
// Available levels are:
// - Logging.ERROR (default)
// - Logging.WARN
// - Logging.INFO
// - Logging.DEBUG
Logging.set_level(Logging.INFO);

Vue.filter('toDelimited', function (value) {
    if (typeof value !== "number") {
        return value;
    }
    var formatter = new Intl.NumberFormat('pt-BR', {
        currency: 'BRL',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    });
    return formatter.format(value);
});

Vue.filter('toDelimitedInt', function (value) {
    if (typeof value !== "number") {
        return value;
    }
    var formatter = new Intl.NumberFormat('pt-BR', {
        currency: 'BRL',
        minimumFractionDigits: 0
    });
    return formatter.format(value);
});

Vue.filter('toPercentage', function (value) {
    if (typeof value !== "number") {
        return value;
    }
    var formatter = new Intl.NumberFormat('pt-BR', {
        minimumFractionDigits: 2
    });
    return formatter.format(value) + "%";
});

Vue.filter('toCurrency', function (value) {
    if (typeof value !== "number") {
        return value;
    }
    var formatter = new Intl.NumberFormat('pt-BR', {
        style: 'currency',
        currency: 'BRL',
        minimumFractionDigits: 2
    });
    return formatter.format(value);
});


const Chartjs = require('chart.js');
Chartjs.plugins.register({
  afterDatasetsDraw: function(chartInstance, easing) {
    if (easing != 1) {
      return;
    }
    if (chartInstance.options.extended) {
      var drawValues = chartInstance.options.extended.drawValuesInChart;
      var drawPercentages = chartInstance.options.extended.drawPercentageValuesInChart;
      var useAlternativeDataSet = chartInstance.options.extended.useAlternativeDataSet;
      var drawColor = chartInstance.options.extended.drawValuesColor;
      var drawSize = chartInstance.options.extended.drawValuesSize;
      var drawStyle = chartInstance.options.extended.drawValueStyle;

      if (drawValues || drawPercentages) {
        var ctx = chartInstance.chart.ctx;
        chartInstance.data.datasets.forEach(function(dataset, i) {
          var fullSum = 0;
          var meta = chartInstance.getDatasetMeta(i);
          for (var i = 0; i < dataset.data.length; i++) {
            fullSum += dataset.data[i];
          }
          if (!meta.hidden) {
            meta.data.forEach(function(element, index) {
              if (drawColor) {
                ctx.fillStyle = drawColor;
              } else {
                ctx.fillStyle = '#FFFFFF';
              }
              var fontSize = 15;
              if (drawSize) {
                fontSize = drawSize;
              }
              var fontStyle = 'normal';
              if (drawStyle) {
                fontStyle = drawStyle;
              }
              var fontFamily = 'proxima-nova';
              ctx.font = Chartjs.helpers.fontString(fontSize, fontStyle, fontFamily);

              if (dataset.data[index]) {
                var percentage = ((dataset.data[index] / fullSum).toFixed(2) * 100).toString();
                var dataString = '';
                if (useAlternativeDataSet) {
                  dataString = dataset.labelsData[index].toString();
                } else {
                  dataString = dataset.data[index].toString();
                }

                // Make sure alignment settings are correct
                ctx.textAlign = 'center';
                ctx.textBaseline = 'middle';
                var padding = 5;
                var position = element.tooltipPosition();
                if (drawPercentages) {
                  ctx.fillText(percentage + ' %', position.x, position.y - (fontSize / 2) - padding);
                  padding -= 25;
                }
                if (drawValues) {
                  ctx.fillText(dataString, position.x, position.y - (fontSize / 2) - padding);
                }
              }
            });
          }
        });
      }

      if (chartInstance.options.extended.drawRectangles && chartInstance.data.datasets.length > 0) {
        let meta = chartInstance.getDatasetMeta(0);
        for (var i = 0; i < chartInstance.options.extended.rectangles.length; i++) {
          let rectangle = chartInstance.options.extended.rectangles[i];
          let xValue = rectangle.x;
          let yValue = rectangle.y;

          var wValue = rectangle.w;
          var hValue = rectangle.h;
          if (rectangle.to_point) {
            let tPosition = meta.data[rectangle.to_point.index].tooltipPosition();
            let yAxes = meta.data[0]._yScale;

            wValue = tPosition.x - meta.data[0]._yScale.right + xValue;
            hValue = meta.data[0]._yScale.bottom - tPosition.y + yValue;
          }

          if (rectangle.to_scale_point) {

            let yAxes = meta.data[0]._yScale;
            let xAxes = meta.data[0]._xScale;

            let yMax = yAxes.ticks[0];
            let yMin = yAxes.ticks[yAxes.ticks.length - 1];
            let yDelta = yMax - yMin;

            let yBottom = meta.data[0]._yScale.bottom;
            let yTop = meta.data[0]._yScale.top;
            let yDeltaScale = yBottom - yTop;

            let xMin = xAxes.ticks[0];
            let xMax = xAxes.ticks[xAxes.ticks.length - 1];
            let xDelta = xMax - xMin;

            let xRight = meta.data[0]._xScale.right;
            let xLeft = meta.data[0]._xScale.left;
            let xDeltaScale = xRight - xLeft;

            var xScale = rectangle.to_scale_point.x;
            var yScale = rectangle.to_scale_point.y;

            let adjustedY = yScale * yDeltaScale / yDelta;
            let adjustedX = xScale * xDeltaScale / xDelta;

            wValue = adjustedX;
            hValue = adjustedY;

          }

          let colorValue = rectangle.color;
          let dashValue = rectangle.dash;

          chartInstance.chart.ctx.beginPath();
          chartInstance.chart.ctx.moveTo(meta.data[0]._yScale.right + xValue, meta.data[0]._yScale.bottom - yValue);
          chartInstance.chart.ctx.lineTo(meta.data[0]._yScale.right + xValue + wValue, meta.data[0]._yScale.bottom - yValue);
          chartInstance.chart.ctx.lineTo(meta.data[0]._yScale.right + xValue + wValue, meta.data[0]._yScale.bottom - (yValue + hValue));
          chartInstance.chart.ctx.lineTo(meta.data[0]._yScale.right + xValue, meta.data[0]._yScale.bottom - (yValue + hValue));
          chartInstance.chart.ctx.lineTo(meta.data[0]._yScale.right + xValue, meta.data[0]._yScale.bottom - yValue);
          chartInstance.chart.ctx.strokeStyle = colorValue;
          chartInstance.chart.ctx.setLineDash(dashValue)
          chartInstance.chart.ctx.stroke();

          if (rectangle.legend) {

            var baseX = meta.data[0]._yScale.right + 50 + (170 * i);
            var baseY = meta.data[0]._yScale.top - 30;
            //este retengulo tem legenda?
            chartInstance.chart.ctx.beginPath();
            chartInstance.chart.ctx.moveTo(baseX, baseY);
            chartInstance.chart.ctx.lineTo(baseX + 50, baseY);
            chartInstance.chart.ctx.strokeStyle = colorValue;
            chartInstance.chart.ctx.setLineDash(dashValue)
            chartInstance.chart.ctx.stroke();

            chartInstance.chart.ctx.textAlign = 'left';
            chartInstance.chart.ctx.fillStyle = rectangle.legendColor;
            chartInstance.chart.ctx.fillText(rectangle.legend, baseX + 60, baseY);
          }
        }
      }

      if (chartInstance.options.extended.drawHorizontalLine && chartInstance.data.datasets.length > 0) {
        var meta = chartInstance.getDatasetMeta(chartInstance.options.extended.drawHorizontalLineDataset);
        //pegando o primeiro ponto pra puchar os dados dos eixos
        var iPoint = meta.data[0];
        if (!iPoint) {
          return;
        }
        var position = iPoint.tooltipPosition();
        let step = (iPoint._yScale.bottom - iPoint._yScale.top) / (iPoint._yScale.max - iPoint._yScale.min);
        let base = chartInstance.options.extended.drawHorizontalLinePoint - iPoint._yScale.min;
        let position = iPoint._yScale.bottom - (chartInstance.options.extended.drawHorizontalLinePoint - iPoint._yScale.min) * step;

        chartInstance.chart.ctx.beginPath();
        chartInstance.chart.ctx.moveTo(iPoint._xScale.left, position);
        chartInstance.chart.ctx.strokeStyle = '#ff0000';
        chartInstance.chart.ctx.setLineDash([2,5])
        chartInstance.chart.ctx.lineTo(iPoint._xScale.right, position);
        chartInstance.chart.ctx.stroke();

        chartInstance.chart.ctx.textAlign = 'center';
        chartInstance.chart.ctx.fillStyle = "#FFFFFF";
      }

      if (chartInstance.options.extended.drawCurrentPointLine && chartInstance.data.datasets.length > 0) {
        var meta = chartInstance.getDatasetMeta(0);
        var iPoint = meta.data[chartInstance.options.extended.currentPoint];
        if (!iPoint) {
          return;
        }
        var position = iPoint.tooltipPosition();

        chartInstance.chart.ctx.beginPath();
        chartInstance.chart.ctx.moveTo(position.x, iPoint._yScale.top);
        chartInstance.chart.ctx.strokeStyle = '#ff0000';
        chartInstance.chart.ctx.setLineDash([2,5])
        chartInstance.chart.ctx.lineTo(position.x, iPoint._yScale.bottom);
        chartInstance.chart.ctx.stroke();

        chartInstance.chart.ctx.textAlign = 'center';
        chartInstance.chart.ctx.fillStyle = chartInstance.options.extended.drawCurrentPointFontColor || "#FFFFFF";
        chartInstance.chart.ctx.fillText("HOJE", position.x, 0 + 5);
      }
    }
  }
});

class Application {

  /**
   * Find the current page component call its setup.
   */
  startPageComponent() {
    let pageComponentInput = document.getElementById("page-component");
    if (pageComponentInput !== null) {
      let pageComponent = pageComponentInput.value;
      Logging.info("Instantiating page component: " + pageComponent);
      var page = window[pageComponent];
      if (!page) {
        Logging.error("Page component not found:" + pageComponent);
      } else {
        page.setup();
      }
    }

    const dropdown = new Dropdown('capture_period', this.onSelectCapturePerdiod);

  }

  onSelectCapturePerdiod(period) {
    const $capturePeriodFormInput = $('.js-capture-period');

    if ($capturePeriodFormInput.val() !== period) {
      $capturePeriodFormInput.val(period);
      $('.js-capture-period-form').submit();
    }
  }

  applyPrototypes() {
    Number.prototype.formatMoney = function(c, d, t){
      var n = this,
        c = isNaN(c = Math.abs(c)) ? 2 : c,
        d = d === undefined ? "," : d,
        t = t === undefined ? "." : t,
        s = n < 0 ? "-" : "",
        i = String(parseInt(n = Math.abs(Number(n) || 0).toFixed(c))),
        j = (j = i.length) > 3 ? j % 3 : 0;
      return s + (j ? i.substr(0, j) + t : "") + i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + t) + (c ? d + Math.abs(n - i).toFixed(c).slice(2) : "");
    };

    String.prototype.replaceAll = function(search, replacement) {
      return this.replace(new RegExp(search, 'g'), replacement);
    };

    String.prototype.parseMoney = function(){
      if (this === null || this === '') {
        return 0;
      } else {
        return parseFloat(this.replaceAll(/\./, '').replaceAll(/,/, '.'));
      }
    };

    String.prototype.isBlank = function() {
      return this === null || this.trim().length === 0;
    };
  }

}

var app = new Application();
app.applyPrototypes();
app.startPageComponent();

window.navBar = new NavBar();

import DataTable from "./components/datatable";
import GaugeChart from "./components/gauge-chart";
import SolidGaugeChart from "./components/solid-gauge-chart";

class FarmPanelPage {

  setup() {
    this.setupDataTable();

    this.farmChart = new GaugeChart('time-chart-farmer', {
      title: 'Farm',
      tooltip: ' % de parcerias'
    });
    this.captureChart = new SolidGaugeChart('daily-contributions', {
      title: 'Captação',
      tooltip: 'Captação - Graduação'
    });

    this.setContributionChartData();
    this.recalculateTotals();
  }

  setContributionChartData() {
    let dailyContributionsData = $("#daily-contributions-data").val();
    this.captureChart.getSeries(0).setData([eval(dailyContributionsData)]);
  }

  setupDataTable() {
    this.table = new DataTable('#report-table', {
      paging: true,
      deferRender: true,
      searchDelay: 500,
      pageLength: 10,
      order: [ 9, 'desc' ]
    });
    var instance = this;
    this.table.onFilter(function() {
      // wait some time before the user stop typing.
      setTimeout(function() {
        instance.recalculateTotals();
      }, 300);
    });
  }

  recalculateTotals() {
    let newPercent = 0;
    let nRows = this.table.getFilteredRows().nodes().length;
    if (nRows > 0) {
      let filteredData = this.table.getFilteredRows().data();

      let realized = 0;
      let movel_goal = 0;
      for (var i = 0; i < nRows; i++) {
        movel_goal += filteredData[i][10].parseMoney();
        realized += filteredData[i][11].parseMoney();
      }

      $("#mobile-goal").text(movel_goal.formatMoney(2));
      $("#total-realized").text(realized.formatMoney(2));

      newPercent = parseFloat((( realized / movel_goal ) * 100).toFixed(2));
      console.log(newPercent);
    }

    this.farmChart.getSeries(0).setData([]);
    this.farmChart.getSeries(0).addPoint(newPercent)
  }
}

window.farmPanelPage = new FarmPanelPage();


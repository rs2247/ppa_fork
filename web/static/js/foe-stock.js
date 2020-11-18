import DataTable from "./components/datatable";
import GaugeChart from "./components/gauge-chart";
import SolidGaugeChart from "./components/solid-gauge-chart";

class FoeStockPage {

  setup() {
    this.setupDataTable();
  }

  setupDataTable() {
    this.table = new DataTable('#report-table', {
      paging: true,
      deferRender: true,
      searchDelay: 100,
      pageLength: 10,
      order: [[0, 'asc'], [1, 'asc'], [4, 'asc']]
    });
  }
}

window.foeStockPage = new FoeStockPage();


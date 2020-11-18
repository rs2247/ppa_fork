import DataTable from "./components/datatable";

class UniversitiesPage {

  setup() {
    this.setupDataTable();
  }

  setupDataTable() {
    this.table = new DataTable('#report-table', {
      paging: true,
      deferRender: true,
      searchDelay: 100,
      pageLength: 10,
      order: [6, 'desc' ]
    });
  }
}

window.universitiesPage = new UniversitiesPage();


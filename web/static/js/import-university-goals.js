import DataTable from './components/datatable';

const COLUMNS = ['period','university_id','product_line_id','value','present','current_value'];

class importUniversityGoals {

  setup() {
    this.preprocessPath = $('.js-preprocess-path').val();
    this.importPath = $('.js-import-path').val();
    this.fileInput = $('.js-file-input');
    this.submitButton = $('.js-submit-button');
    this.goalsTableWrapper = $('.js-goals-table-wrapper');
    this.disableSubmitButton();
    this.setupProcessFile();
    this.setupImportFile();
  }

  setupProcessFile() {
    this.fileInput.on('change', (e) => {
      this.deleteGoalsTable();
      if(this.verifyFile()){
        alert('O arquivo foi enviado e está sendo pré-processado, aguarde para conferir e confirmar a importação.');
        this.preprocessFile();
      } else {
        this.clearFile();
        this.disableSubmitButton();
        alert('Selecione um arquivo csv');
      }
    });
  }

  setupImportFile() {
    this.submitButton.on('click', (e) => {
      this.disableSubmitButton();
      alert('O arquivo foi enviado e está sendo importado, aguarde.');
      this.getEncodedFile((encodedFile) => {
        $.ajax({
          url: this.importPath,
          type: 'POST',
          data: {file: encodedFile},
          beforeSend: (xhr) => {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
          success: (data) => {
            alert('Metas importadas com sucesso, ' + data + ' novos valores');
          },
          error: (error) => {
            alert('Erro na importação');
          },
        });
      });
    });
  }

  verifyFile() {
    const filename = this.fileInput.val();
    const fileExtension = filename.split('.').pop();
    return fileExtension === 'csv';
  }

  preprocessFile() {
    this.getEncodedFile((encodedFile) => {
      $.ajax({
        url: this.preprocessPath,
        type: 'POST',
        data: {file: encodedFile},
        beforeSend: (xhr) => {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
        success: (data) => {
          this.enableSubmitButton();
          this.createGoalsTable(data);
        },
        error: (error) => {
          this.clearFile();
          this.disableSubmitButton();
          alert(`Ocorreu um erro com a leitura do arquivo\n${error.responseJSON.error}`);
        },
      });
    });
  }

  getEncodedFile(onLoad){
    const file = this.fileInput[0].files[0];
    const reader = new FileReader();
    reader.onload = () => {
      let encodedFile = reader.result.split(',')[1];
      onLoad(encodedFile);
    };
    reader.readAsDataURL(file);
  }

  clearFile() {
    this.fileInput.val('');
  }

  disableSubmitButton() {
    this.submitButton.prop('disabled', true);
  }

  enableSubmitButton() {
    this.submitButton.prop('disabled', false);
  }

  createGoalsTable(data) {
    this.goalsTable = $('<table></table>');
    this.goalsTable.addClass('data-table');
    this.goalsTable.addClass('js-goals-table');
    this.goalsTableWrapper.append(this.goalsTable);
    this.createTableHeaders();
    this.createTableBody(data);
    this.setupDataTable();
  }

  deleteGoalsTable(data) {
    this.goalsTableWrapper.empty();
    this.goalsTable = null;
  }

  createTableHeaders() {
    const tableHead = $('<thead></thead>');
    const headRow = $('<tr></tr>');
    tableHead.append(headRow);
    $.each(COLUMNS, (index, header) => {
      headRow.append($('<th></th>').text(header));
    });
    this.goalsTable.append(tableHead);
  }

  createTableBody(data) {
    const tableBody = $('<tbody></tbody>');
    $.each(data, (index, rowData) => {
      let tableRow = $('<tr></tr>');
      $.each(COLUMNS, (index, column) => {
        tableRow.append($('<td></td>').text(rowData[column]));
      });
      tableBody.append(tableRow);
    });
    this.goalsTable.append(tableBody);
  }

  setupDataTable() {
    this.table = new DataTable('.js-goals-table', {
      paging: false,
      searching: false,
      deferRender: true,
      buttons: [],
      order: [],
    });
  }
}

window.importUniversityGoals = new importUniversityGoals();

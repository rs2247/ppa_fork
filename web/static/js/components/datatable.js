export default class DataTable {

  constructor(selector, config = {}) {
    this.selector = selector;
    this.element = $(selector);
    this.configDataTypes();
    console.log("configDataTypes FINISHED");

    const buttonCustomization = this.getButtonCustomization();
    let baseConfig = {
      paging: config["paging"] || false,
      pageLength: config["pageLength"] || 10,
      info: config["info"] || false,
      searching: config["searching"], // If the config is empty, will default to true
      searchDelay: config['searchDelay'] || 350,
      dom: 'Bfrtip',
      buttons: config["buttons"] || [
        $.extend( true, {}, buttonCustomization, {
          extend: 'copyHtml5'
        }),
        $.extend( true, {}, buttonCustomization, {
          extend: 'excelHtml5'
        }),
        $.extend( true, {}, buttonCustomization, {
          extend: 'pdfHtml5'
        })
      ],
      language: {
        "search": "",
        buttons: {
          copy: 'Copiar',
          copyTitle: 'Copiado para a área de transferência',
          copySuccess: {
            _: '%d linhas copiadas',
            1: '1 linha copiada'
          }
        },
        emptyTable: "Nenhum registro encontrado.",
        paginate: {
          first: 'Primeiro',
          previous: 'Anterior',
          next: 'Próximo',
          last: 'Último'
        }
      }
    };

    if (config["columnDefs"]) {
      baseConfig.columnDefs = config["columnDefs"];
    }

    this.dataTable = this.element.DataTable(baseConfig);

    if (config["order"]) {
      this.dataTable.order(config["order"]);
    }
    this.dataTable.draw();
    $('.dataTables_filter input').attr('placeholder', 'Localizar na tabela...');
    $('.dataTables_filter label').append('<i class="form-control-feedback glyphicon glyphicon-search" aria-hidden="true"></i>')
  }

  onFilter(func) {
    this.dataTable.on('search.dt', func);
  }

  getFilteredRows() {
    return this.dataTable.rows( { filter : 'applied'} )
  }

  /**
   * This button customization allows to export custom data formats, as brazilian currency format.
   * More details can be found here: https://datatables.net/extensions/buttons/examples/html5/outputFormat-function.html
   */
  getButtonCustomization() {
    const instance = this;
    return {
      exportOptions: {
        columns: ':not(.exclude)',  // exclude columns with <th class="exclude">
        format: {
          body: function ( data, row, column, node ) {
            if (instance.isBrazilianCurrency(data)) {
              return instance.parseBRCurrencyToFloat(data);
            } else if (instance.isBrazilianFormattedNumber(data)) {
              return instance.parseBRNumberToFloat(data);
            //} else if (instance.isBrazilianDate(data)) {
              //return instance.parseBRDateToFloat(data);
            } else {
              return data;
            }
          }
        }
      }
    }
  }

  configDataTypes() {
    console.log("configDataTypes");
    const instance = this;
    jQuery.fn.dataTableExt.aTypes.unshift(
      function (sData, settings) {
        if (instance.isBrazilianCurrency(sData)) {
          return 'currency';
        } else if (instance.isBrazilianFormattedNumber(sData)) {
          return 'numbr';
        //} else if (instance.isBrazilianDate(sData)) {
          //return 'brdate';
        } else {
          return null;
        }
      }
    );

    // Configure sorting for brazilian dates (dd/mm/yyyy)
    jQuery.fn.dataTableExt.oSort['brdate-asc'] = (x,y) => {
      console.log("brdate-asc");
      var a = this.parseBRDateToFloat(x);
      var b = this.parseBRDateToFloat(y);
      return (a <= b ? -1 : 1);
    };

    jQuery.fn.dataTableExt.oSort['brdate-desc'] = (x,y) => {
      console.log("brdate-desc");
      var a = this.parseBRDateToFloat(x);
      var b = this.parseBRDateToFloat(y);
      return (a > b ? -1 : 1);
    };

    // Configure sorting for brazilian currencies (R$)
    jQuery.fn.dataTableExt.oSort['numbr-asc'] = (x,y) => {
      var a = this.parseBRNumberToFloat(x);
      var b = this.parseBRNumberToFloat(y);
      return (a <= b ? -1 : 1);
    };

    jQuery.fn.dataTableExt.oSort['numbr-desc'] = (x,y) => {
      var a = this.parseBRNumberToFloat(x);
      var b = this.parseBRNumberToFloat(y);
      return (a > b ? -1 : 1);
    };

    // Configure sorting for brazilian formatted numbers
    jQuery.fn.dataTableExt.oSort['currency-asc'] = (x,y) => {
      var a = this.parseBRCurrencyToFloat(x);
      var b = this.parseBRCurrencyToFloat(y);
      return (a <= b ? -1 : 1)
    };

    jQuery.fn.dataTableExt.oSort['currency-desc'] = (x,y) => {
      var a = this.parseBRCurrencyToFloat(x);
      var b = this.parseBRCurrencyToFloat(y);
      return (a > b ? -1 : 1);
    };
  }

  isBrazilianCurrency(str) {
    return str.indexOf('R$') >= 0
  }

  isBrazilianDate(str) {
    return str.indexOf('/') >= 0
  }

  isBrazilianFormattedNumber(str) {
    const numberFormatRegex = /\d+(\.\d{3})*\,\d+/g;
    return str.match(numberFormatRegex);
  }

  parseBRCurrencyToFloat(x) {
    return this.parseBRNumberToFloat(x.replace('R$', '').replace('&nbsp;', ''));
  }

  parseBRDateToFloat(x) {
    let parts = x.split('/');
    return parseFloat(`${parts[2]}${parts[1]}${parts[0]}`);
  }

  parseBRNumberToFloat(x) {
    let num = x
      .replace(/<.+?>/g, '')
      .replace(/\./g, '')
      .replace(',', '.');
    return parseFloat(num);
  }
}

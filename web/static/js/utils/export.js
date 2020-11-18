import _ from 'lodash'
import moment from 'moment'

function emptyNull(value) {
  if (_.isNil(value)) {
    return "";
  }
  return value;
}

function exportCsvFile(filename, content) {
  var blob = new Blob([content], {type: "text/plain;charset=utf-8"});
  saveAs(blob, filename);
}

function exportData(name_sufix, data, fields) {
  var filename = name_sufix + "_" + moment().format('MM_DD_YYYY_hh_mm_ss_a') + '.csv';
  var content = _.join(fields, ';') + '\n';
  let lines = data[0].length;
  let columns = data.length;
  console.log("content: " + content);
  console.log("lines: " + lines + " columns: " + columns);
  for (var i = 0; i < lines; i++) {
    let separator = '';
    for (var j = 0; j < columns; j++) {
      content = content + separator + emptyNull(data[j][i]);
      separator = ';';
    }
    content = content + '\n';
  }
  exportCsvFile(filename, content);
}

export default {
  exportCsvFile: exportCsvFile,
  exportData: exportData,
};

import _ from 'lodash'

function solveEntries(options, compareValues, field) {
  let filters = _.map(compareValues, (valueEntry) => {
    let filteredOptions = _.filter(options, (filterEntry) => {
      return filterEntry[field] == valueEntry[field];
    })
    if (filteredOptions.length > 0) {
      return filteredOptions[0];
    }
    return null;
  });
  return filters;
}

function solveEntry(options, compareValue, field) {
  let filteredEntry = _.filter(options, (filterEntry) => {
    return filterEntry[field] == compareValue;
  })
  if (filteredEntry.length > 0) {
    return filteredEntry[0];
  }
}

export default {
  solveEntries: solveEntries,
  solveEntry: solveEntry,
};

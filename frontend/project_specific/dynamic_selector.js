let DynamicSelector = {
  selected(element){
    return $(`${element} :selected`);
  },
  filterOptions(parentSelector, childSelector, allOptions){
    let parentSelection = this.selected(parentSelector).text();
    // console.log("parentSelection: #{parentSelection}")
    let filtered = $(allOptions).filter(`optgroup[label='${parentSelection}']`);
    // console.log("filtered: #{filtered.html()}")
    let options = filtered.html();
    // console.log("options: #{options}")
    if (options) {
      $(childSelector).empty().attr('disabled', false);
      return $(childSelector).html(options).parent().show();
    } else {
      return $(childSelector).empty().attr('disabled', true);
    }
  },
  makeDynamic(parentSelector, childSelector){
    let allOptions = $(childSelector).html();
    return $(parentSelector).change(() => {
      return this.filterOptions(parentSelector, childSelector, allOptions);
    }
    );
  },
  selectDefault(parentSelector){
    return $(parentSelector).trigger('change');
  }
};
export default DynamicSelector;

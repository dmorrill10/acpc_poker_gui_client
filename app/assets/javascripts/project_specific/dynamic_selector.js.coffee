root = exports ? this

root.DynamicSelector =
  selected: (element)->
    $("#{element} :selected")
  filterOptions: (parentSelector, childSelector, allOptions)->
    parentSelection = @selected(parentSelector).text()
    # console.log("parentSelection: #{parentSelection}")
    filtered = $(allOptions).filter("optgroup[label='#{parentSelection}']")
    # console.log("filtered: #{filtered.html()}")
    options = filtered.html()
    # console.log("options: #{options}")
    if options
      $(childSelector).empty().attr('disabled', false)
      $(childSelector).html(options).parent().show()
    else
      $(childSelector).empty().attr('disabled', true)
  makeDynamic: (parentSelector, childSelector)->
    allOptions = $(childSelector).html()
    $(parentSelector).change =>
      @filterOptions(parentSelector, childSelector, allOptions)
  selectDefault: (parentSelector)->
    $(parentSelector).trigger('change')
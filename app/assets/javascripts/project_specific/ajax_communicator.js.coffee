root = exports ? this

class AjaxCommunicator
  @send: (type, urlArg, dataArg = {})->
    console.log "AjaxCommunicator#send: type: #{type}, urlArg: #{urlArg}, dataArg: #{dataArg}"
    $.ajax({
      type: type,
      url: urlArg,
      data: dataArg,
      dataType: 'script'
    })
  @sendPost: (urlArg, dataArg = {})->
    console.log "AjaxCommunicator#sendPost: urlArg: #{urlArg}, dataArg: #{dataArg}"
    @send('POST', urlArg, dataArg)
  @sendGet: (urlArg)->
    console.log "AjaxCommunicator#sendGet: urlArg: #{urlArg}"
    @send('GET', urlArg)

root.AjaxCommunicator = AjaxCommunicator
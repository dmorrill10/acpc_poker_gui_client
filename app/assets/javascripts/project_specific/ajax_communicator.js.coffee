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
  @post: (urlArg, dataArg = {})->
    console.log "AjaxCommunicator#post: urlArg: #{urlArg}, dataArg: #{dataArg}"
    @send('POST', urlArg, dataArg)
  @get: (urlArg)->
    console.log "AjaxCommunicator#get: urlArg: #{urlArg}"
    @send('GET', urlArg)

root.AjaxCommunicator = AjaxCommunicator
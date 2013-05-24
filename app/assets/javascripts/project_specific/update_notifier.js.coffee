root = exports ? this

root.UpdateNotifier =
  open: ->
    @ws = new WebSocket(@url)
    console.log "Opened websocket"
    @ws.onmessage = (event)=>
      console.log 'Received message'
      alert(event.data)
      $('#hidden-next_state').submit()
    @ws.onerror = (event)=> alert(event.data)

  close: ->
    if @ws
      console.log "CLOSING websocket..."
      @ws.close()
  connect: (@url)->
    @close()
    @open()
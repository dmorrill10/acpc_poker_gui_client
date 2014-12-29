root = exports ? this

class Chat
  @chatBox: null
  @init: (chatElement, userName, onSentMessage)->
    unless @chatBox?
      @chatBox = new Chat(chatElement, userName, onSentMessage)
    @chatBox
  @close: ()->
    if @chatBox?
      @chatBox.close()
    @chatBox = null

  constructor: (chatElement, userName, onSentMessage)->
    @box = $(chatElement).chatbox(
      {
        id: chatElement,
        user: userName,
        title: "Chat",
        hidden: true,
        messageSent: (id, user, msg)=>
          onSentMessage id, user, msg
          @addMessage user, msg
      }
    )
    @toggle()

  addMessage: (user, message)->
    @box.chatbox("option", "boxManager").addMsg(user, message)

  toggleOpenClose: ->
    @box.chatbox('option', 'boxManager').toggleBox()

  toggle: -> @box.chatbox('toggleContent')
  close: -> $('.ui-chatbox').remove()

root.Chat = Chat

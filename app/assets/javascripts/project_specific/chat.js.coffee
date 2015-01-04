root = exports ? this

class Chat
  @chatBox: null
  @init: (userName, onSentMessage)->
    console.log "Chat::init: @chatBox?: #{@chatBox?}"
    if @chatBox?
      @chatBox.closeIfNotFunctional()
    unless @chatBox?
      @chatBox = new Chat(userName, onSentMessage)
    console.log "Chat::init: Returning: @chatBox?: #{@chatBox?}"
    @chatBox
  @close: ()->
    console.log "Chat::close: @chatBox?: #{@chatBox?}"
    if @chatBox?
      @chatBox.close()
    @chatBox = null

  @intialElementId: 'chat-box'
  @titlebarClass: '.ui-chatbox-titlebar'
  @badgeHtml: (numNewMessages)->
    "<span class=badge>#{numNewMessages}</span>"

  constructor: (userName, onSentMessage)->
    @chatElement = "##{@constructor.intialElementId}"
    @numNewMessages = 0
    onCreate = (event, ui)=>
      console.log 'Chat#new: onCreate'
      @containerElement().focusin(=> @clearBadge())
      @toggle()
      console.log 'Chat#new: onCreate: Returning'
    @box().chatbox(
      {
        id: @chatElement,
        user: userName,
        title: "Chat",
        hidden: true,
        create: onCreate,
        messageSent: (id, user, msg)=>
          onSentMessage id, user, msg
          @addMessage user, msg
      }
    )

  containerElement: ->
    $('.ui-chatbox')

  isFocused: ->
    $("#{@constructor.titlebarClass}.ui-state-focus").length > 0

  box: ->
    $(@chatElement)

  clearBadge: ->
    console.log "Chat#clearBadge: @newMessagesBadge()?: #{@newMessagesBadge().length > 0}"
    if @newMessagesBadge().length > 0
      @newMessagesBadge().remove()
      @numNewMessages = 0

  badgeHtml: ->
    @constructor.badgeHtml @numNewMessages

  inputBox: ->
    $('.ui-chatbox-input-box')

  titlebar: ->
    $(@constructor.titlebarClass)

  newMessagesBadge: ->
    $("#{@constructor.titlebarClass} > .badge")

  isShrunk: ->
    $('.ui-chatbox-content').css('display') is 'none'

  newMessagesPresent: ->
    @newMessagesBadge().length > 0

  addMessage: (user, message)->
    console.log "Chat#addMessage: user: #{user}, message: #{message}, @isFocused(): #{@isFocused()}"
    try
      @box().chatbox("option", "boxManager").addMsg(user, message)
    catch ignoredError
      console.log("Chat#toggleOpenClose ignoredError: #{ignoredError}")
      @constructor.close()
    finally
      unless @isFocused()
        console.log "Chat#addMessage: @numNewMessages: #{@numNewMessages}, @newMessagesPresent(): #{@newMessagesPresent()}"
        @numNewMessages += 1
        if @newMessagesPresent()
          @newMessagesBadge().html @numNewMessages
        else
          @titlebar().append @badgeHtml()

  toggleOpenClose: ->
    try
      @box().chatbox('option', 'boxManager').toggleBox()
    catch ignoredError
      console.log("Chat#toggleOpenClose ignoredError: #{ignoredError}")
      @constructor.close()

  widget: ->
    try
      @box().chatbox('widget')
    catch ignoredError
      console.log("Chat#widget ignoredError: #{ignoredError}")
      @constructor.close()

  closeIfNotFunctional: ->
    @widget()

  toggle: ->
    try
      @box().chatbox('toggleContent')
    catch ignoredError
      console.log("Chat#toggle ignoredError: #{ignoredError}")
      @constructor.close()
  close: ->
    try
      @box().chatbox('destroy')
    catch ignoredError
      console.log("Chat#close ignoredError: #{ignoredError}")
    finally
      @removeHtmlElement()
  removeHtmlElement: ->
    @containerElement().remove()
    if @box().length < 1
      $('body').append("<div id='#{@constructor.intialElementId}'></div>")

root.Chat = Chat

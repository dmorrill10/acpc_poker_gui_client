root = exports ? this

class Timer
  constructor: ->
    @timeoutId = null
  isCounting: -> @timeoutId?
  getTimeRemaining: ->
    parseInt($('.time-remaining').text(), 10)
  setTimeRemaining: (timeRemaining)->
    return if !timeRemaining? || isNaN(timeRemaining)
    timeRemaining = 0 if timeRemaining < 0
    $('.time-remaining').text(timeRemaining)
  clear: ()->
    if @timeoutId?
      clearTimeout(@timeoutId)
      @timeoutId = null
  start: (fn)->
    @timeoutId = setTimeout(fn, 1000)
  afterEachSecond: (onTimeout)->
    timeRemaining = @getTimeRemaining()
    if timeRemaining?
      if timeRemaining <= 0
        onTimeout()
      else
        @setTimeRemaining timeRemaining - 1
        @start(=> @afterEachSecond(onTimeout))
    else
      @start(=> @afterEachSecond(onTimeout))
  startForPlayer: (onTimeout)->
    @clear()
    @start(=> @afterEachSecond(onTimeout))
  pause: ->
    @timeRemaining = @getTimeRemaining()
  resume: ->
    @setTimeRemaining @timeRemaining

root.Timer = Timer
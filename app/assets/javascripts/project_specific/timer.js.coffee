root = exports ? this

class Timer
  constructor: ->
    @timeoutId = null
  isCounting: -> @timeoutId?
  clear: ->
    if @timeoutId?
      clearTimeout(@timeoutId)
      @timeoutId = null
  start: (fn, period)->
    @stop() if @isCounting()
    @timeoutId = setTimeout(fn, period)
  stop: -> @clear()


root.Timer = Timer

class ActionTimer extends Timer
  constructor: (@onTimeout)-> super()
  getTimeRemaining: ->
    parseInt($('.time-remaining').text(), 10)
  setTimeRemaining: (timeRemaining)->
    return if !timeRemaining? || isNaN(timeRemaining)
    timeRemaining = 0 if timeRemaining < 0
    $('.time-remaining').text(timeRemaining)
  start: ->
    super(
      => @afterEachSecond(@onTimeout),
      1000
    )
  afterEachSecond: ->
    timeRemaining = @getTimeRemaining()
    if timeRemaining?
      if timeRemaining <= 0
        @onTimeout()
      else
        @setTimeRemaining timeRemaining - 1
        @start(=> @afterEachSecond(@onTimeout))
    else
      @start(=> @afterEachSecond(@onTimeout))
  pause: ->
    @timeRemaining = @getTimeRemaining()
  resume: ->
    @setTimeRemaining @timeRemaining

root.ActionTimer = ActionTimer

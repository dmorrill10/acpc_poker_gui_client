root = exports ? this

class Timer
  constructor: ->
    @timeoutId = null
  isCounting: -> @timeoutId?
  clear: ()->
    if @timeoutId?
      clearTimeout(@timeoutId)
      @timeoutId = null
  start: (fn, period)->
    @timeoutId = setTimeout(fn, period)

root.Timer = Timer

class Poller
  constructor: (pollTo, period)->
    @pollTo = pollTo
    @period = period
    @timer = Timer
  stop: -> @timer.clear()
  start: ->
    @timer.start(@pollTo, @period)

root.Poller = Poller

class ActionTimer extends Timer
  getTimeRemaining: ->
    parseInt($('.time-remaining').text(), 10)
  setTimeRemaining: (timeRemaining)->
    return if !timeRemaining? || isNaN(timeRemaining)
    timeRemaining = 0 if timeRemaining < 0
    $('.time-remaining').text(timeRemaining)
  start: (fn)-> @timer.start(fn, 1000)
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

root.ActionTimer = ActionTimer

root = exports ? this

class CounterQueue
  constructor: (length=0)->
    @length = length

  push: ()-> @length += 1
  pop: ()-> @length -= 1 unless @isEmpty()
  reset: ()-> @length = 0
  isEmpty: ()-> @length == 0

root.CounterQueue = CounterQueue

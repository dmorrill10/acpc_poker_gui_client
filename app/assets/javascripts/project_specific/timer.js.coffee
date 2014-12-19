root = exports ? this

root.Timer =
  clear: ()->
    clearTimeout(@timeoutId)

  start: (fn)->
    @timeoutId = setTimeout(fn, 1000)

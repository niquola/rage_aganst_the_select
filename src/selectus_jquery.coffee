(($) ->
  $.fn.select2 = ->
    $(@).each ->
      cnt = new window.SelectController(@)
) jQuery

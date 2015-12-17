#= require jquery
#= require jquery_ujs
#= require turbolinks
#= require prism
##= require semantic-ui/dropdown


ready = ->
  Prism.highlightAll()

$(document).ready(ready)
$(document).on('page:load', ready)

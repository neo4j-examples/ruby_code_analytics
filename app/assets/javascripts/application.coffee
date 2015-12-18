#= require jquery
#= require jquery_ujs
#= require turbolinks
#= require prism
##= require semantic-ui/dropdown


ready = ->
  Prism.highlightAll()

  code_block_el = $('pre#code-block')[0]
  if code_block_el?
    code_block_el.scrollTop = 15 + (($(code_block_el).data('first-line') - 3) * 21);

$(document).ready(ready)
$(document).on('page:load', ready)

# This is a manifest file that'll be compiled into application.js, which will include all the files
# listed below.
#
# Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
# vendor/assets/javascripts directory can be referenced here using a relative path.
#
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# compiled file. JavaScript code in this file should be added after the last require_* statement.
#
# Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
# about supported directives.
#
#= require rails-ujs
#= require turbolinks
#= require_tree .
#
#= require jquery
#= require bootstrap-sprockets
#= require underscore

#= require highcharts
#= require chartkick

#= require moment
#= require moment/ru
#= require bootstrap-sortable
#= require bootstrap-datetimepicker

Highcharts.setOptions({
  global: {
    useUTC: false
  }
});

$(document).on "turbolinks:load", ->
  $('.datetimepicker').datetimepicker();

  $('select.reload-on-change').on 'change', ->
    params = $(this).closest('form').serializeArray()
    params = _.reject(params, (param)-> param.name == "authenticity_token")
    query = $.param(params)
    window.location.href = window.location.pathname + "?" + query

  $("form.glass-form").each ->
    form = $(this)
    $('#glass_stock_name').on 'change', ->
      form.submit()

  $("form.arbitrage-graph-form").each ->
    form = $(this)
    $('#pair').on 'change', ->
      form.submit()

# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

show_response = (data) ->
	console.log data
	$("#response").html data

@submit_the_form = (timeout) ->
	if $("#outbound_date").val().length == 7
		url = '/skyscanner_api/cheapest_quotes'
	else
		url = '/skyscanner_api/creating_the_session'
	
	$.ajax {
		url: url,
		data: $("#query").serialize(),
		success: show_response,
		dataType: 'json'
	}

	if timeout && retry < $("#limit").val()
		window.retry++
		setTimeout "submit_the_form(#{timeout})", timeout



$(document).ready ->
	$("#submit_once").click ->
		submit_the_form null
	$("#submit_with_timeout").click ->
		window.retry = 0
		submit_the_form $("#timeout").val()
	
	
	
	

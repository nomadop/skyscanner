# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


array_find = (array, selector) ->
	result = null
	$.each array, (index, el) ->
		result = el if selector(el)
	return result

class Array
	find: (selector) ->
		result = null
		$.each this, (index, el) ->
			result = el if selector(el)
		return result

cheapest_quotes = ->
	show_response = (data) ->
		console.log data
		$("#response").html JSON.stringify(data)
		$('body').css('cursor', 'auto')
	$.ajax {
		url: '/skyscanner_api/cheapest_quotes',
		data: $("#query").serialize(),
		success: show_response,
		dataType: 'json'
	}

living_price = ->
	$.ajax {
		url: '/skyscanner_api/creating_the_session',
		data: $("#query").serialize(),	
		success: (data) ->
			console.log data
			setTimeout "polling_the_session('#{data.SessionKey}')", 1000
		,
		dataType: 'json'
	}

window.polling_the_session = (SessionKey) ->
	show_response = (data) ->
		return unless data.Itineraries
		#$("#response").html JSON.stringify(data)
		$("#response").html "<ul id='list'></ul>"
		$("#response").html "NO RESULT" if data.Itineraries.length == 0
		$.each data.Itineraries, (index, it) ->
			OutboundLeg = array_find data.Legs, (el) ->
				return el.Id == it.OutboundLegId
			InboundLeg = array_find data.Legs, (el) ->
				return el.Id == it.InboundLegId
			
			$("#list").append "<li id='itinerariy#{index}'>
					<ul name='OutboundLeg'>
						前往:<br>
						#{(array_find data.Places, (el) -> return el.Id == OutboundLeg.OriginStation).Name}&nbsp#{OutboundLeg.Departure}&nbsp=>&nbsp#{OutboundLeg.Arrival}&nbsp#{(array_find data.Places, (el) -> return el.Id == OutboundLeg.DestinationStation).Name}<br>
						途径:&nbsp#{OutboundLeg.Stops}<br>
						航空公司:&nbsp#{OutboundLeg.Carriers}
					</ul>
					#{
						if InboundLeg
							'<ul name="InboundLeg">返回:<br>' + InboundLeg.OriginStation + '&nbsp' + InboundLeg.Departure + '&nbsp=>&nbsp' + InboundLeg.Arrival + '&nbsp' + InboundLeg.DestinationStation + '<br>途径:&nbsp' + InboundLeg.Stops + '<br>航空公司:&nbsp' + InboundLeg.Carriers
						else
							""
					}
					<ul name='Prices'>
						价格: #{it.PricingOptions[0].Price}#{data.Query.Currency}
						<a name='details' href='javascript: void(0)' data-outboundLegId='#{OutboundLeg.Id}' data-inboundLegId='#{
							if InboundLeg
								InboundLeg.Id
							else
								''
						}' data-ulId='itinerariy#{index}'>Details</a>
					</ul>
					<ul name='details'></ul>
				</li>"

		$("a[name='details']").click ->
			$('body').css('cursor', 'wait')
			booking_details SessionKey, $(this).attr('data-outboundLegId'), $(this).attr('data-inboundLegId'), $(this).attr('data-ulId')

	$.ajax {
		url: '/skyscanner_api/polling_the_session',
		data: { 'SessionKey' : SessionKey },
		success: (data) ->
			console.log data
			show_response data
			if data.Status != "UpdatesComplete"
				setTimeout "polling_the_session('#{SessionKey}')", 2000
			else
				window.Agents = data.Agents
				$('body').css('cursor', 'auto')
		,
		dataType: 'json'
	}


booking_details = (SessionKey, OutboundLegId, InboundLegId, ulId) ->
	$.ajax {
		url: '/skyscanner_api/creating_booking_details',
		data: {
			'SessionKey': SessionKey,
			'OutboundLegId': OutboundLegId,
			'InboundLegId': InboundLegId
		},
		success: (data) ->
			console.log data
			setTimeout "polling_booking_details('#{SessionKey}', '#{data.IitineraryKey}', '#{ulId}')", 1000
		,
		dataType: 'json'
	}


window.polling_booking_details = (SessionKey, IitineraryKey, ulId) ->
	show_response = (data) ->
		ul = $("##{ulId} ul[name='details']").html "详细信息:<br>Agents:<ul>"
		$.each data.BookingOptions, (index, bo) ->
			$.each bo.BookingItems, (index, bi) ->
				AgentName = bi.AgentID
				$.each Agents, (index, agent) ->
					AgentName = agent['Name'] if agent['Id'] == bi.AgentID
				ul.append "<li>
						<a href='#{bi.Deeplink}'>#{AgentName}:&nbsp#{bi.Price}#{data.Query.Currency}</a>
					</li>"

		# ul.append("</ul>行程:<ul>")
		# $.each data.Segments, (index, seg) ->
			
			
	
	$.ajax {
		url: '/skyscanner_api/polling_booking_details',
		data: {
			'SessionKey': SessionKey,
			'IitineraryKey': IitineraryKey
		},
		success: (data) ->
			console.log data
			show_response data
			if data.Status == "Pending"
				setTimeout "polling_booking_details('#{SessionKey}', '#{IitineraryKey}', '#{ulId}')", 2000
			else
				$('body').css('cursor', 'auto')
		,
		dataType: 'json'
	}


location_autosuggest = (query, input, output) ->
	$.ajax {
		url: '/skyscanner_api/location_autosuggest',
		data: { 'query': query },
		success: (data) ->
			#console.log data
			output.html ""
			$.each data.Places, (index, place) ->
				# console.log place
				output.append "<span data-placeId='#{place.PlaceId}'>#{place.PlaceName}(#{place.PlaceId})</span>;"
			output.find("span").click ->
				input.val $(this).attr('data-placeId')
		,
		dataType: 'json'
	}


$(document).ready ->
	$("#submit_once").click ->
		$('body').css('cursor', 'wait')
		if $("#outbound_date").val().length == 7
			cheapest_quotes()
		else
			living_price()
		
	$("#origin_place").keydown (event) ->
		if event.which == 13 && $(this).val().length > 2
			location_autosuggest $(this).val(), $(this), $("#origin_place_autosuggest")

	$("#destination_place").keydown ->
		if event.which == 13 && $(this).val().length > 2
			location_autosuggest $(this).val(), $(this), $("#destination_place_autosuggest")
	
	
	
	
	

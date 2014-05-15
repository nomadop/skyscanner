class Flight < ActiveRecord::Base
	validates_uniqueness_of	:leg_id

	has_many :booking_items

	def self.searching_flights_by_date origin_place, destination_place, date
		session_key = SkyscannerApi.creating_the_session(origin_place, destination_place, date)
		status = 'UpdatesPending'
		while status == 'UpdatesPending' || status == 304
			sleep 1
			data = SkyscannerApi.polling_the_session session_key
			status = data['Status'] || data['status']
		end

		data['Itineraries'].each do |it|	
			leg = data['Legs'].select { |leg| leg['Id'] == it['OutboundLegId'] }[0]
			origin_station = data['Places'].select { |place| place['Id'] == leg['OriginStation'] }[0]
			destination_station = data['Places'].select { |place| place['Id'] == leg['DestinationStation'] }[0]
			origin_city = data['Places'].select { |place| place['Id'] == origin_station['ParentId'] }[0]
			destination_city = data['Places'].select { |place| place['Id'] == destination_station['ParentId'] }[0]
			flight = Flight.find_by_leg_id leg['Id']
			flight = Flight.new :leg_id => leg['Id'], :origin_city => origin_city['Name'], :destination_city => destination_city['Name'], :departure => leg['Departure'], :arrival => leg['Arrival'] unless flight
			flight.session_key = session_key
			flight.price = it['PricingOptions'][0]['Price']
			flight.save 
		end
	end

	def booking_details
		itinerary_key = SkyscannerApi.creating_booking_details session_key, leg_id
		status = 'Pending'
		while status == 'Pending' || status == 304
			sleep 1
			data = SkyscannerApi.polling_booking_details session_key, itinerary_key
			status = data['Status'] || data['status']
		end

		self.flight_number = data['Segments'].inject("") do |result ,seg|
			carrier = data['Carriers'].select { |carrier| carrier['Id'] == seg['Carrier'] }[0]
			flight_number = carrier['Code'] + seg['FlightNumber']
			result.empty? ? flight_number : "#{result}/#{flight_number}"
		end

		self.booking_items.destroy_all
		data['BookingOptions'].each do |bo|
			bo['BookingItems'].each do |bi|
				booking_item = self.booking_items.new :agent_id => bi['AgentID'], :deeplink => bi['Deeplink'], :price => bi['Price']
				booking_item.save 
			end
		end

		save
	end

end

class Flight < ActiveRecord::Base
	validates_uniqueness_of	:flight_number

	belongs_to :search_task
	has_many :booking_items,	:dependent => :destroy

	class DetailsTask < Thread
		def initialize complete, pending, &block
			@complete = complete
			@pending = pending
			super(block)
		end
	end

	def self.get_flights_by_date origin_place, destination_place, date
		session_key = SkyscannerApi.creating_the_session(origin_place, destination_place, date)
		status = 'UpdatesPending'
		while status == 'UpdatesPending' || status == 304
			sleep 2
			data = SkyscannerApi.polling_the_session session_key
			status = data['Status'] || data.status
		end
		return [] unless data['Status'] == 'UpdatesComplete'

		data['Agents'].each do |a|
			agent = Agent.find_or_initialize_by(id: a['Id'])
			unless agent.persisted?
				agent.id             = a['Id']
				agent.image_url      = a['ImageUrl']
				agent.name           = a['Name']
				agent.booking_number = a['BookingNumber']
				agent.save
			end
		end

		legs = data['Itineraries'].map do |it|
			{
				:session_key => session_key,
				:leg_id => it['OutboundLegId']  
			}
		end

		result = []
		task = []
		devide = 3
		11.times do |i|
			task[i] = Thread.new do
				legs[(devide * i)...(devide * (i + 1))].each do |leg|
					result << Flight.get_flight_by_leg(leg[:session_key], leg[:leg_id])
				end
			end
			sleep 0.1
		end
		task.each { |t| t.join }

		flights = []
		result.each do |res|
			flight = res[0]
			flight.save
			flight.booking_items << res[1]
			flight.booking_items.each do |bi|
				bi.save
			end
			flights << flight
		end

		flights
	end

	def self.get_flight_by_leg session_key, leg_id
		itinerary_key = SkyscannerApi.creating_booking_details(session_key, leg_id)
		return nil unless itinerary_key.class.to_s == 'String'
		status = 'Pending'
		while status == 'Pending' || status == 304
			sleep 2
			data = SkyscannerApi.polling_booking_details(session_key, itinerary_key)
			status = data['Status'] || data.status
		end
		return nil unless data['Status'] == 'Current'

		flight_number = data['Segments'].inject("") do |result ,seg|
			carrier = data['Carriers'].select { |carrier| carrier['Id'] == seg['Carrier'] }[0]
			flight_number = "#{carrier['Code']}#{seg['FlightNumber']}"
			result.empty? ? flight_number : "#{result}/#{flight_number}"
		end

		flight = Flight.new(flight_number: flight_number)
		attrs = {
			:price => data['BookingOptions'][0]['BookingItems'][0]['Price'],
			:updated_at => Time.now
		}

		unless flight.persisted?
			seg1                = data['Segments'][0]
			seg2                = data['Segments'].pop
			origin_station      = data['Places'].select{ |p| p['Id'] == seg1['OriginStation'] }[0]
			destination_station = data['Places'].select{ |p| p['Id'] == seg2['DestinationStation'] }[0]
			origin_city         = data['Places'].select{ |p| p['Id'] == origin_station['ParentId'] }[0]
			destination_city    = data['Places'].select{ |p| p['Id'] == destination_station['ParentId'] }[0]
			attrs.merge!({
				:origin_city => origin_city['Code'],
				:destination_city => destination_city['Code'],
				:departure => seg1['DepartureDateTime'], 
				:arrival => seg2['ArrivalDateTime'] 
			})
		end
		flight.set_attrs(attrs)
		booking_items = []

		# flight.booking_items.destroy_all
		data['BookingOptions'].each do |bo|
			bo['BookingItems'].each do |bi|
				booking_item = BookingItem.new :agent_id => bi['AgentID'], :deeplink => bi['Deeplink'], :price => bi['Price']
				booking_items << booking_item
			end
		end

		return [flight, booking_items]
	end

	def set_attrs attrs
		attrs.keys.each do |key|
			send("#{key}=", attrs[key])
		end
	end

	def agents
		booking_items.map { |b| b.agent }
	end
end

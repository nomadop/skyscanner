class SkyscannerApi

	ENV = [
		{
			:version => 'web_crawler',
			:url => "http://www.skyscanner.net", 
			:live_price_uri => "/dataservices/routedate/v2.0/",
			:browse_quotes_uri => "/dataservices/browse/1.0",
			:default => {
				:market => "CN",
				:currency => "cny",
				:locale => "ZH", 
			}
		},
		{
			:version => "api",
			:apikey => "", 
			:url => "http://partners.api.skyscanner.net",
			:live_price_uri => "/apiservices/pricing/v1.0",
			:browse_quotes_uri => "/apiservices/browsequotes/v1.0",
			:default => {
				:market => "CN",
				:currency => "cny",
				:locale => "zh-CN" 
			}
		}
	]
	VERSION = "api"

	def self.uncamelize string
		string[0].downcase + string[1..-1].gsub(" ", "").gsub(/[A-Z]/){|s| "_#{s.downcase}"}
	end

	def self.get_env
		SkyscannerApi::ENV.select{ |env| env[:version] == SkyscannerApi::VERSION }[0]
	end

	def self.get_conn
		conn = Faraday.new(:url => SkyscannerApi.get_env[:url]) do |builder|
			builder.request		:url_encoded
			builder.response	:logger
			builder.adapter		Faraday.default_adapter
		end
		conn.params['use204'] = true if SkyscannerApi::VERSION == 'web_crawler'
		conn.params['apiKey'] = get_env[:apikey] if SkyscannerApi::VERSION != 'web_crawler'
		conn.headers['User-Agent'] = "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.131 Safari/537.36"
		return conn
	end

	def self.location_autosuggest query
		begin
			conn = get_conn
			response = conn.get "/apiservices/autosuggest/v1.0/#{get_env[:default][:market]}/#{get_env[:default][:currency]}/#{get_env[:default][:locale]}/", { :query => query }
			if response.status == 200
				JSON.parse(response.body)
			else
				response
			end
		rescue Exception => e
			e
		end
	end

	def self.analyzing_quotes hash
		hash
	end

	def self.cheapest_quotes origin_place, destination_place, outbound_date, inbound_date = nil
		# p "*"*100
		# p origin_place
		# p destination_place
		# p  outbound_date
		# p inbound_date
		begin
			conn = get_conn
			url = "#{get_env[:browse_quotes_uri]}/#{get_env[:default][:market]}/#{get_env[:default][:currency]}/#{get_env[:default][:locale]}#{'/calendar' if SkyscannerApi::VERSION == 'web_crawler'}/#{origin_place}/#{destination_place}/#{outbound_date}"
			url += "/#{inbound_date}" if inbound_date != nil
			response = conn.get url, { :includequotedate => true }
			if response.status == 200
				analyzing_quotes JSON.parse(response.body)
			else
				response
			end
		rescue Exception => e
			Exception
		end
	end

	def self.creating_the_session origin_place, destination_place, outbound_date, inbound_date = nil, cabinclass = nil, adults = nil, children = nil
		querys = {
			'country' => get_env[:default][:market],
			'currency' => get_env[:default][:currency],
			'locale' => get_env[:default][:locale],
			'originplace' => origin_place,
			'destinationplace' => destination_place,
			'outbounddate' => outbound_date,
			'locationschema' => 'Sky'
		}
		querys['inbounddate'] = inbound_date if inbound_date != nil

		begin
			conn = get_conn
			conn.headers['Content-Type'] = 'application/x-www-form-urlencoded'
			response = conn.post "#{get_env[:live_price_uri]}", querys
			if response.status == 201
				response.headers['Location'].split('/').pop
			else 
				response
			end
		rescue Exception => e
			Exception
		end
	end

	def self.analyzing_the_session hash
		# return hash
		itineraries = []
		hash['Legs'].each do |leg|
			leg['Carriers'].collect! do |carrier|
				hash['Carriers'].select{ |c| c['Id'] == carrier }[0]['Name']
			end
			leg['OperatingCarriers'].collect! do |carrier|
				hash['Carriers'].select{ |c| c['Id'] == carrier }[0]['Name']
			end
			leg['OriginStation'] = hash['Places'].select{ |place| place['Id'] == leg['OriginStation'] }[0]['Name']
			leg['DestinationStation'] = hash['Places'].select{ |place| place['Id'] == leg['DestinationStation'] }[0]['Name']
			leg['Stops'].map! do |place|
				p = hash['Places'].select{ |p| p['Id'] == place }[0]
				p != nil ? p['Name'] : place
			end
		end
		hash['Itineraries'].each do |it|
			it['OutboundLeg'] = hash['Legs'].select{ |leg| leg['Id'] == it['OutboundLegId'] }[0]
			it['InboundLeg'] = hash['Legs'].select{ |leg| leg['Id'] == it['InboundLegId'] }[0]
			it['PricingOptions'].each do |po|
				po['Agents'].collect! do |agent|
					a = hash['Agents'].select{ |a| a['Id'] == agent }[0]
					a != nil ? a['Name'] : agent
				end
			end
			it.delete 'OutboundLegId'
			it.delete 'InboundLegId'
			# it.delete 'BookingDetailsLink'
			itineraries << it
		end
		{ 'Status' => hash['Status'], 'Itineraries' => itineraries, 'Query' => hash['Query'], 'Agents' => hash['Agents'] }
	end

	def self.polling_the_session session_key
		begin
			conn = get_conn
			response = conn.get "#{get_env[:live_price_uri]}/#{session_key}"
			if response.status == 200
				analyzing_the_session JSON.parse(response.body)
			else
				response
			end
		rescue Exception => e
			{ 'Status' => 'UpdatesComplete', Exception => e.backtrace }
		end
	end

	def self.creating_booking_details session_key, outbound_leg_id, inbound_leg_id = nil
		begin
			conn = get_conn
			response = conn.put "#{get_env[:live_price_uri]}/#{session_key}/booking", {
				'outboundlegid' => outbound_leg_id,
				'inboundlegid' => inbound_leg_id
			}
			if response.status == 201
				response.headers['Location'].split('/').pop
			else
				response
			end
		rescue Exception => e
			e
		end
	end

	def self.analyzing_booking_details hash
		hash['Status'] = 'Current'
		hash['BookingOptions'].each do |bo|
			bo['BookingItems'].each do |bi|
				if bi['Status'] == 'Pending'
					hash['Status'] = 'Pending'
				end
			end
		end
		if hash['Status'] == 'Current'
			hash['Segments'].each do |seg|
				seg['Carrier'] = hash['Carriers'].select{ |c| c['Id'] == seg['Carrier'] }[0]
				seg['FlightNumber'] = seg['Carrier']['Code'] + seg['FlightNumber']
				seg['Carrier'] = seg['Carrier']['Name']
				seg['OperatingCarrier'] = hash['Carriers'].select{ |c| c['Id'] == seg['OperatingCarrier'] }[0]['Name']
				seg['OriginStation'] = hash['Places'].select{ |place| place['Id'] == seg['OriginStation'] }[0]['Name']
				seg['DestinationStation'] = hash['Places'].select{ |place| place['Id'] == seg['DestinationStation'] }[0]['Name']
			end
			hash.delete 'Carriers'
			hash.delete 'Places'
		end
		return hash
	end

	def self.polling_booking_details session_key, itinerary_key
		begin
			conn = get_conn
			response = conn.get "#{get_env[:live_price_uri]}/#{session_key}/booking/#{itinerary_key}"
			if response.status == 200
				analyzing_booking_details JSON.parse(response.body)
			else
				response
			end
		rescue Exception => e
			{ 'Status' => 'Error', 'Exception' => e.backtrace }
		end
	end

end
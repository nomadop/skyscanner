class SkyscannerApi

	ENV = [
		{
			:version => 'web_crawler',
			:url => "http://www.tianxun.cn", 
			:live_price_uri => "/dataservices/routedate/v2.0/",
			:browse_quotes_uri => "/dataservices/browse/1.0",
			:default => {
				:market => "CN",
				:currency => "cny",
				:locale => "ZH", 
			}
		},
		{
			:version => "api_1.0",
			:apikey => "", 
			:url => "http://partners.api.skyscanner.net",
			:live_price_uri => "/apiservices/pricing/v1.0",
			:browse_quotes_uri => "/apiservices/browsequotes/v1.0",
			:default => {
				:market => "UK",
				:currency => "GBP",
				:locale => "en-GB" 
			}
		}
	]
	VERSION = "api_1.0"

	def self.uncamelize string
		string[0].downcase + string[1..-1].gsub(/[A-Z]/){|s| "_#{s.downcase}"}
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

	def self.cheapest_quotes origin_place, destination_place, outbound_date, inbound_date = nil, market = get_env[:default][:market], currency = get_env[:default][:currency], locale = get_env[:default][:locale]
		conn = get_conn
		url = "#{get_env[:browse_quotes_uri]}/#{market}/#{currency}/#{locale}/calendar/#{origin_place}/#{destination_place}/#{outbound_date}"
		url += "/#{inbound_date}" if inbound_date != nil
		response = conn.get url, { :includequotedate => true }
		if response.status == 200
			JSON.parse response.body
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
			'locationschema' => 'Iata'
		}
		querys['inbounddate'] = inbound_date if inbound_date != nil

		conn = get_conn
		conn.headers['Content-Type'] = 'application/x-www-form-urlencoded'
		response = conn.post "#{get_env[:live_price_uri]}", querys
		if response.status == 201
			response.headers['Location'].split('/').pop
		else 
			response
		end
	end

	def self.polling_the_session session_key
		conn = get_conn
		response = conn.get "#{get_env[:live_price_uri]}/#{session_key}"
		if response.status == 200
			JSON.parse response.body
		end
	end

end
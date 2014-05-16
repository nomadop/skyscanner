class SearchTask < ActiveRecord::Base
	before_save :validates_unique

	has_many :flights

	def get_flights
		return nil unless persisted?
		while status == 'Pending'
			sleep 1
		end
		return flights if status == 'Complete' && Time.now - updated_at < 3600
		
		status = 'Pending'
		before_updated = Time.now
		fls = Flight.get_flights_by_date origin_city, destination_city, date
		flights << fls
		flights.destroy flights.where('updated_at < ?', before_updated).map {|f| f}
		self.updated_at = Time.now
		self.status = 'Complete'
		save

		flights
	end

	private
		def validates_unique
			st = SearchTask.where('origin_city = ? and destination_city = ? and date = ?', origin_city, destination_city, date)
			if st.empty? || persisted?
				return true
			else
				return false
			end
		end
end

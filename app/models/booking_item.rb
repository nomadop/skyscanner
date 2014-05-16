class BookingItem < ActiveRecord::Base
	belongs_to :flight
	belongs_to :agent
end

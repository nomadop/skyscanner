class CreateBookingItems < ActiveRecord::Migration
  def change
    create_table :booking_items do |t|
      t.integer 	:agent_id,	:null => false 
      t.integer		:flight_id,	:null	=> false
      t.string 		:deeplink,	:null => false 
      t.float 		:price

      t.timestamps
    end
  end
end

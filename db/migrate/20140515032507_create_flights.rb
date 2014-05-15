class CreateFlights < ActiveRecord::Migration
  def change
    create_table :flights do |t|
      t.string    :session_key,       :null => false
      t.string    :leg_id,            :null => false 
      t.string    :origin_city,       :null => false 
      t.string    :destination_city,  :null => false 
      t.timestamp :departure,         :null => false 
      t.timestamp :arrival,           :null => false
      t.string    :flight_number
      t.float     :price

      t.timestamps
    end
  end
end

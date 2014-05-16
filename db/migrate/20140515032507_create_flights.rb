class CreateFlights < ActiveRecord::Migration
  def change
    create_table :flights do |t|
      t.integer   :search_task_id
      t.string    :origin_city,       :null => false 
      t.string    :destination_city,  :null => false 
      t.timestamp :departure,         :null => false 
      t.timestamp :arrival,           :null => false
      t.string    :flight_number,     :null => false 
      t.float     :price

      t.timestamps
    end
  end
end

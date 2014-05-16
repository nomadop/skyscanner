class CreateAgents < ActiveRecord::Migration
  def change
    create_table :agents do |t|
      t.string :name
      t.string :image_url
      t.string :booking_number

      t.timestamps
    end
  end
end

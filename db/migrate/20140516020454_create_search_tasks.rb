class CreateSearchTasks < ActiveRecord::Migration
  def change
    create_table :search_tasks do |t|
      t.string :origin_city,				:null => false 
      t.string :destination_city,		:null => false 
      t.string :date,								:null => false 
      t.string :status,							:default => ""

      t.timestamps
    end
  end
end

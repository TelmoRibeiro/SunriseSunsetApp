class CreateRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :records do |t|
      t.string :location
      t.date   :date
      t.string :sunrise
      t.string :sunset
      t.string :golden_hour
    end
  end 
end

class CreateSunsetSunriseContents < ActiveRecord::Migration[7.2]
  def change
    create_table :sunset_sunrise_records do |t|
      t.string :location
      t.date   :date
      t.string :sunrise
      t.string :sunset
      t.string :golden_hour
    end
  end 
end

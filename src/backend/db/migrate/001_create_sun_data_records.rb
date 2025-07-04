class CreateSunDataRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :sun_data_records do |t|
      t.float  :latitude
      t.float  :longitude
      t.string :location
      t.date   :date
      t.time   :sunrise
      t.time   :sunset
      t.time   :golden_hour

      t.timestamps
    end
  end
end
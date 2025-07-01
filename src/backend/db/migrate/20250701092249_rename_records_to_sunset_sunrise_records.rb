class RenameRecordsToSunsetSunriseRecords < ActiveRecord::Migration[7.2]
  def change
    rename_table :records, :sunset_sunrise_records
  end
end

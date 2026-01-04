class ChangeEventIdNullableInTags < ActiveRecord::Migration[8.1]
  def change
    change_column_null :tags, :event_id, true
  end
end

class AddBaseShortCodeToCannedResponses < ActiveRecord::Migration[7.1]
  def change
    add_column :canned_responses, :base_short_code, :string
  end
end

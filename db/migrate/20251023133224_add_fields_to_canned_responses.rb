class AddFieldsToCannedResponses < ActiveRecord::Migration[7.1]
  def change
    add_column :canned_responses, :status, :string, null: false, default: 'active'
    add_column :canned_responses, :canned_type, :string, null: false, default: 'generic'
    add_column :canned_responses, :category, :string, null: false, default: 'general'
    add_column :canned_responses, :template_id, :string
    add_reference :canned_responses, :inbox, foreign_key: true, index: true
  end
end

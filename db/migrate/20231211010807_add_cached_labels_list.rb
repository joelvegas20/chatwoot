class AddCachedLabelsList < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :cached_label_list, :string
    Conversation.reset_column_information
    # NOTE: Caching is now handled by acts_as_taggable_on configuration in the model
  end
end

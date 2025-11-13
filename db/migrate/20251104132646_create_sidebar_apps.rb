class CreateSidebarApps < ActiveRecord::Migration[7.1]
  def change
    create_table :sidebar_apps do |t|
      t.string :title, null: false
      t.jsonb :content, default: []
      t.bigint :account_id, null: false
      t.bigint :user_id

      t.timestamps
    end

    add_index :sidebar_apps, :account_id
    add_index :sidebar_apps, :user_id
  end
end

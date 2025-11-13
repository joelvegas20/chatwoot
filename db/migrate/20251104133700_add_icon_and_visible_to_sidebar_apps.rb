class AddIconAndVisibleToSidebarApps < ActiveRecord::Migration[7.1]
  def change
    add_column :sidebar_apps, :icon, :string, default: 'i-lucide-app-window'
    add_column :sidebar_apps, :visible, :boolean, default: true
  end
end

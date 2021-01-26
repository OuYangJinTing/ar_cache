# frozen_string_literal: true

ActiveRecord::Base.connection.create_table(:ar_cache_monitors, force: :cascade) do |t|
  t.string  :table_name, null: false
  t.integer :version, null: false, limit: 10
  t.boolean :disabled
  t.string  :unique_indexes, limit: 1000
  t.string  :ignored_columns, limit: 1000

  t.index   :table_name, unique: true
end

module ArCache
  class Monitor
  end
end

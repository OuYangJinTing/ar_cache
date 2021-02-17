# frozen_string_literal: true

ActiveRecord::Base.connection.create_table(:empties, force: :cascade) do |t|
  t.timestamps null: false
end

class Empty < ApplicationRecord
end

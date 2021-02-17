# frozen_string_literal: true

ActiveRecord::Base.connection.create_table(:identities, force: :cascade) do |t|
  t.integer :user_id, null: false
  t.string :number, null: false

  t.timestamps null: false

  t.index :number, unique: true
  t.index :user_id, unique: true
end

class Identity < ApplicationRecord
  belongs_to :user
end

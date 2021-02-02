# frozen_string_literal: true

ActiveRecord::Base.connection.create_table(:accounts, force: :cascade) do |t|
  t.integer :user_id, null: false
  t.string :username, null: false
  t.string :password, null: false

  t.timestamps null: false

  t.index :user_id, unique: true
  t.index :username, unique: true
end

class Account < ApplicationRecord
  belongs_to :user
  has_one :identity, through: :user
end

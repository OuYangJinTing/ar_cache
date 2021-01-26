# frozen_string_literal: true

ActiveRecord::Base.connection.create_table(:users, force: :cascade) do |t|
  t.string  :name,         null: false
  t.string  :email,        null: false
  t.integer :status,       null: false, default: 0
  t.integer :role,         null: false, default: 0
  t.integer :books_count,  null: false, default: 0
  t.integer :images_count, null: false, default: 0
  t.text    :interest

  t.timestamps null: false

  t.index :email, unique: true
  t.index %i[name status], unique: true
end

class User < ApplicationRecord
  enum status: %i[active archived]
  serialize :interest, Array, default: []

  has_many :books, foreign_key: :author_id
  has_many :images, as: :imagable
end
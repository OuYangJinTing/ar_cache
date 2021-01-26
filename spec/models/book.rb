# frozen_string_literal: true

ActiveRecord::Base.connection.create_table(:books, force: :cascade) do |t|
  t.integer :author_id,    null: false
  t.string  :number,       null: false
  t.string  :title,        null: false
  t.string  :introduction, null: false, default: ''
  t.integer :images_count, null: false, default: 0
  t.decimal :price,        null: false, precision: 5, scale: 2
  t.date    :publish_date, null: false

  t.timestamps null: false

  t.index :number, unique: true
end

class Book < ApplicationRecord
  belongs_to :user, counter_cache: true, touch: true, foreign_key: :author_id
  has_many :images, as: :imagable
end

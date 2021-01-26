# frozen_string_literal: true

ActiveRecord::Base.connection.create_table(:animals, force: :cascade) do |t|
  t.string  :type
  t.string  :name,         null: false
  t.integer :images_count, null: false, default: 0

  t.timestamps null: false
end

class Animal < ApplicationRecord
  has_many :images, as: :imagable
end

class Dog < Animal
end

class Cat < Animal
end

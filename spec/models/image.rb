# frozen_string_literal: true

ActiveRecord::Base.connection.create_table(:images, force: :cascade) do |t|
  t.string  :imagable_type
  t.integer :imagable_id
  t.text    :data

  t.timestamps null: false
end

class Image < ApplicationRecord
  store :data, accessors: %i[bytesize format]

  belongs_to :imagable, polymorphic: true, counter_cache: true, touch: true
end

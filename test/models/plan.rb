# frozen_string_literal: true

ActiveRecord::Base.connection.create_table(:plans, force: :cascade) do |t|
  t.integer :user_id,    null: false
  t.date    :begin_date, null: false
  t.date    :end_date,   null: false

  t.index :begin_date, unique: true
end

class Plan < ApplicationRecord
  belongs_to :user

  before_save -> { self.end_date = begin_date }
end

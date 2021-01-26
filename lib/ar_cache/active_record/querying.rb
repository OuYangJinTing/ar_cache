# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Querying
      delegate :find, :find_by, to: :all
      delegate :skip_ar_cache, to: :all
    end
  end
end

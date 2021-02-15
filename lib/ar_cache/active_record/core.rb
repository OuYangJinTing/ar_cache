# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Core
      module ClassMethods
        delegate :skip_ar_cache, to: :all

        # The #find use statement cache execute querying first, so need force skip.
        def find(...)
          ar_cache_table.enabled? ? all.find(...) : super
        end

        # The #find_by use statement cache execute querying first, so need force skip.
        def find_by(...)
          ar_cache_table.enabled? ? all.find_by(...) : super
        end
      end
    end
  end
end

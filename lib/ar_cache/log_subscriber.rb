# frozen_string_literal: true

module ArCache
  class LogSubscriber < ActiveSupport::LogSubscriber # :nodoc: all
    SUCCESSFULLY = 1
    FAILED = 0

    def read(event)
      # TODO
    end

    def read_multi(event)
      # TODO
    end

    attach_to :ar_cache
  end
end

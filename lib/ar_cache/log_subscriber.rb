# frozen_string_literal: true

module ArCache
  class LogSubscriber < ActiveSupport::LogSubscriber
    SUCCESSFULLY = 1
    FAILED = 0

    def read(event)
      # TODO
    end

    attach_to :ar_cache
  end
end

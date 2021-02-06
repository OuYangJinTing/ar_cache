# frozen_string_literal: true

# TODO
module ArCache
  class LogSubscriber < ActiveSupport::LogSubscriber
    attach_to :ar_cache
  end
end

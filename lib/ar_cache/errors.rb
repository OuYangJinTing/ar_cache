# frozen_string_literal: true

module ArCache
  class Error < StandardError; end

  class InvalidStoreError < Error; end

  class ColumnNotFound < Error; end

  class NotPrimaryIndex < Error; end
end

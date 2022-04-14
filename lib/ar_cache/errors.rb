# frozen_string_literal: true

module ArCache
  class Error < RuntimeError
  end

  class NonCacheable < Error
  end

  class CompositePrimaryKey < Error
  end

  class MissingPrimaryKey < Error
  end

  class CacheStoreError < Error
  end

  class NotSupportLock < Error
  end

  class UnknownDatabase < Error
  end

  class IndexError < Error
  end

  class UnknownArelNode < Error
  end
end

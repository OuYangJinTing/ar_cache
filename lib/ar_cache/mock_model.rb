# frozen_string_literal: true

module ArCache
  module MockModel
    module_function

    def disabled?
      true
    end

    def enabled?
      false
    end

    def select_disabled?
      true
    end

    def select_enabled?
      false
    end

    def version
      0
    end

    def update_version(*)
      0
    end
    alias init_version update_version

    def whole_cache_key_prefix
      ''
    end

    def version_cache_key
      ''
    end

    def primary_cache_key(*)
      ''
    end

    def cache_key(*)
      ''
    end

    def instantiate(*)
      raise
    end

    def index_columns
      []
    end

    def unique_indexes(*)
      []
    end

    def write(*)
      0
    end

    def delete(*)
      0
    end

    def read_records(*)
      []
    end
  end
end

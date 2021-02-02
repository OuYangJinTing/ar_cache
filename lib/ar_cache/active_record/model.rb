# frozen_string_literal: true

module ArCache
  module ActiveRecord
    module Model
      module ClassMethods
        # We need check ignored columns of ActiveRecord Single Table Inheritance Model,
        # because ArCache's cache is shared by between SubClass and BaseClass,
        # if SubClass need columns is in BaseClass ignored columns, read cache will be incomplete.
        def ignored_columns=(_)
          super.tap do
            return if base_class?
            return if ignored_columns.empty?
            return if (base_class.ignored_columns - ignored_columns).empty?

            raise StiError, <<-MSG.strip_heredoc
            ArCache support ActiveRecord Single Table Inheritance, but SubClass.ignored_columns must be in BaseClass.ignored_columns.
            Here, (SubClass)#{name}.ignored_columns #{ignored_columns.inspect} is not in (BaseClass)#{base_class.name}.ignored_columns #{base_class.ignored_columns.inspect}.
            ArCache does not support this special case, but fortunately, you can handle it with the following operations:
            1. New common superclass #{base_class.name}ArCache
              class #{base_class.name}ArCache < #{(defined?(ApplicationRecord) ? ApplicationRecord : ::ActiveRecord::Base).name}
                self.ignored_columns = # The common ignore columns
              end
            2. Modify superclasses that ArCache do not support of model
              class #{base_class.name} < #{base_class.name}ArCache
                ...
              end
            OK, now you can use ArCache happily!
            MSG
          end
        end

        def table_name=(_)
          super.tap { build_ar_cache_model }
        end

        def ar_cache_model
          return build_ar_cache_model unless defined?(@ar_cache_model)
          @ar_cache_model
        end

        private def build_ar_cache_model
          @ar_cache_model = if abstract_class?
            nil
          elsif base_class?
            ArCache::Model.new(self)
          else # is subclass
            base_class.ar_cache_model
          end
        end
      end

      def self.prepended(klass)
        super.tap { klass.singleton_class.prepend(ClassMethods) }
      end

      def ar_cache_model
        self.class.ar_cache_model
      end
    end
  end
end

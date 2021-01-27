# frozen_string_literal: true

module ArCacheHelper
  extend self

  def remove_monitor(klass)
    ArCache::Monitor.get(klass.table_name)&.destroy
  end

  def remove_model(klass)
    ArCache::Model.send(:remove_const, model_const_name(klass))
  end

  # The monitor's attributes maybe changed after model reinstantiation,
  # so must need restore monitor's attributes bofore restore model.
  def with_reset_model(klass, **options)
    original_monitor = ArCache::Monitor.get(ArCache::Model.get(klass).table_name)
    if options.key?(:ignored_columns)
      original_ignored_columns = klass.ignored_columns
      klass.ignored_columns = options.delete(:ignored_columns)
    end
    reset_model(klass, **options)

    yield

    current_monitor = ArCache::Monitor.get(klass.table_name)
    current_monitor.assign_attributes(original_monitor.attributes)
    current_monitor.save
    klass.ignored_columns = original_ignored_columns if original_ignored_columns
    reset_model(klass)
  end

  private def reset_model(klass, **options)
    table_name = klass.table_name
    options = ArCache::Configuration.get_model_options(table_name).merge(options)
    model = ArCache::Model.new(klass.base_class, options)

    remove_model(klass)
    ArCache::Model.const_set(model_const_name(klass), model)
  end

  private def model_const_name(klass)
    "#{klass.table_name.upcase}_TABLE"
  end
end

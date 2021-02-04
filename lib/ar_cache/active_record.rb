# frozen_string_literal: true

require 'ar_cache/active_record/model'
require 'ar_cache/active_record/persistence'
require 'ar_cache/active_record/callbacks'
require 'ar_cache/active_record/relation'
require 'ar_cache/active_record/querying'
require 'ar_cache/active_record/associations/singular_association'
require 'ar_cache/active_record/associations/has_one_through_association'
require 'ar_cache/active_record/connection_adapters/abstract/database_statements'

ActiveSupport.on_load(:active_record, run_once: true) do
  ActiveRecord::Base.prepend(ArCache::ActiveRecord::Model)
  ActiveRecord::Base.prepend(ArCache::ActiveRecord::Querying)
  ActiveRecord::Base.include(ArCache::ActiveRecord::Callbacks)

  ActiveRecord::Relation.prepend(ArCache::ActiveRecord::Relation)

  ActiveRecord::Persistence.prepend(ArCache::ActiveRecord::Persistence)

  ActiveRecord::Associations::SingularAssociation.prepend(ArCache::ActiveRecord::Associations::SingularAssociation)
  ActiveRecord::Associations::HasOneThroughAssociation.prepend(ArCache::ActiveRecord::Associations::HasOneThroughAssociation) # rubocop:disable Layout/LineLength

  ActiveRecord::ConnectionAdapters::DatabaseStatements.prepend(ArCache::ActiveRecord::ConnectionAdapters::DatabaseStatements) # rubocop:disable Layout/LineLength
end

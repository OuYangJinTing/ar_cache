# frozen_string_literal: true

require 'ar_cache/active_record/model_schema'
require 'ar_cache/active_record/relation'
require 'ar_cache/active_record/core'
require 'ar_cache/active_record/persistence'
require 'ar_cache/active_record/associations/singular_association'
require 'ar_cache/active_record/associations/has_one_through_association'
require 'ar_cache/active_record/connection_adapters/abstract/transaction'
require 'ar_cache/active_record/connection_adapters/abstract/database_statements'

# rubocop:disable Layout/LineLength
ActiveSupport.on_load(:active_record, run_once: true) do
  ActiveRecord::Core::ClassMethods.prepend(ArCache::ActiveRecord::Core::ClassMethods)

  ActiveRecord::ModelSchema.prepend(ArCache::ActiveRecord::ModelSchema)
  ActiveRecord::ModelSchema::ClassMethods.prepend(ArCache::ActiveRecord::ModelSchema::ClassMethods)

  ActiveRecord::Persistence.prepend(ArCache::ActiveRecord::Persistence)
  ActiveRecord::Persistence::ClassMethods.prepend(ArCache::ActiveRecord::Persistence::ClassMethods)

  ActiveRecord::Relation.prepend(ArCache::ActiveRecord::Relation)

  ActiveRecord::Associations::SingularAssociation.prepend(ArCache::ActiveRecord::Associations::SingularAssociation)
  ActiveRecord::Associations::HasOneThroughAssociation.prepend(ArCache::ActiveRecord::Associations::HasOneThroughAssociation)

  ActiveRecord::ConnectionAdapters::NullTransaction.prepend(ArCache::ActiveRecord::ConnectionAdapters::NullTransaction)
  ActiveRecord::ConnectionAdapters::RealTransaction.prepend(ArCache::ActiveRecord::ConnectionAdapters::Transaction)
  ActiveRecord::ConnectionAdapters::SavepointTransaction.prepend(ArCache::ActiveRecord::ConnectionAdapters::Transaction)
  ActiveRecord::ConnectionAdapters::TransactionManager.prepend(ArCache::ActiveRecord::ConnectionAdapters::TransactionManager)

  ActiveRecord::ConnectionAdapters::DatabaseStatements.prepend(ArCache::ActiveRecord::ConnectionAdapters::DatabaseStatements)
end
# rubocop:enable Layout/LineLength

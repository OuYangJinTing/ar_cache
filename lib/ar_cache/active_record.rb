# frozen_string_literal: true

require 'ar_cache/active_record/persistence'
require 'ar_cache/active_record/transactions'
require 'ar_cache/active_record/callbacks'
require 'ar_cache/active_record/relation'
require 'ar_cache/active_record/querying'
require 'ar_cache/active_record/counter_cache'
require 'ar_cache/active_record/associations/has_one_association'
require 'ar_cache/active_record/associations/has_one_through_association'
require 'ar_cache/active_record/connection_adapters/abstract_adapter'
require 'ar_cache/active_record/connection_adapters/abstract/database_statements'

ActiveSupport.on_load(:active_record, run_once: true) do
  ActiveRecord::Base.extend(ArCache::ActiveRecord::Querying)

  ActiveRecord::Relation.prepend(ArCache::ActiveRecord::Relation)

  ActiveRecord::Persistence.prepend(ArCache::ActiveRecord::Persistence)

  ActiveRecord::Transactions.prepend(ArCache::ActiveRecord::Transactions)

  ActiveRecord::CounterCache::ClassMethods.prepend(ArCache::ActiveRecord::CounterCache::ClassMethods)

  ActiveRecord::Associations::HasOneAssociation.prepend(ArCache::ActiveRecord::Associations::HasOneAssociation)
  ActiveRecord::Associations::HasOneThroughAssociation.prepend(ArCache::ActiveRecord::Associations::HasOneThroughAssociation) # rubocop:disable Layout/LineLength

  ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(ArCache::ActiveRecord::ConnectionAdapters::AbstractAdapter)
  ActiveRecord::ConnectionAdapters::DatabaseStatements.prepend(ArCache::ActiveRecord::ConnectionAdapters::DatabaseStatements) # rubocop:disable Layout/LineLength
end

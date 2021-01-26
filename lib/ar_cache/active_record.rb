# frozen_string_literal: true

ActiveSupport.on_load(:active_record, run_once: true) do
  ActiveRecord::Base.include(ArCache::ActiveRecord::Callbacks)
  ActiveRecord::Base.extend(ArCache::ActiveRecord::Querying)

  ActiveRecord::Relation.prepend(ArCache::ActiveRecord::Relation)

  ActiveRecord::Persistence.prepend(ArCache::ActiveRecord::Persistence)

  ActiveRecord::Transactions.prepend(ArCache::ActiveRecord::Transactions)

  ActiveRecord::CounterCache::ClassMethods.prepend(ArCache::ActiveRecord::CounterCache::ClassMethods)

  ActiveRecord::Associations::HasOneAssociation.prepend(ArCache::ActiveRecord::Associations::HasOneAssociation)
  ActiveRecord::Associations::HasOneThroughAssociation.prepend(ArCache::ActiveRecord::Associations::HasOneThroughAssociation)

  ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(ArCache::ActiveRecord::ConnectionAdapters::AbstractAdapter)
  ActiveRecord::ConnectionAdapters::DatabaseStatements.prepend(ArCache::ActiveRecord::ConnectionAdapters::DatabaseStatements)
end

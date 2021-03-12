# ArCache

![Test Status](https://github.com/OuYangJinTing/ar_cache/workflows/CI/badge.svg)
[![Gem Version](https://badge.fury.io/rb/ar_cache.svg)](https://badge.fury.io/rb/ar_cache)

`ArCache` is an modern cacheing library for `ActiveRecord` inspired by cache-money and second_level_cache.  
It works automatically by overridden `ActiveRecord` related CURD code.
When executing standard `ActiveRecord` query, it will first query the cache, and if there is none in the cache,
then query the database and write the result to the cache.

> **! WARNING: Please read these [information](#Warning) before using `ArCache`.**

## Features

- `Low impact`: If your code strictly comply with the activerecord style, you don’t need to modify any code.([see more details](#Warning))
- `Read cache`: Automatically intercept ActiveRecord queries, then try to fetch data from cache.
- `Write cache`: If the query is cacheable and the cached data is not exists, it will be automatically written to the cache after the query.
- `Expire cache`: Automatically expire cache after updated/modified data.
- `Iterative cache`: The cache version will be updated after table fields, `ArCache` switch or `ArCache` coder changed.
- `Shared cache`: The cache is not only used with ActiveRecord, you can easily use it in other places.([see examples](examples))

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ar_cache'
```

And then execute:

```shell
bundle install
```

## Post Installation

If is an `rails` application:

```shell
rails generate ar_cache:install
```

Otherwise copy [configuration](lib/generators/ar_cache/templates/configuration.rb) and [migration](lib/generators/ar_cache/templates/migrate/create_ar_cache_records.rb.tt) files to your application.

After that review the migrations then migrate:

```shell
rake db:migrate
```

## Usage

`ArCache` works automatically, so you don’t need to care about how to use the cache, just need to know how to skip and delete the cache.

Skip cache:

- `ArCache#skip`, eg:

```ruby
# All queries in the block will not use the cache.
ArCache.skip { User.find(1) }
```

- `ActiveRecord::Persistence#reload`, eg:

```ruby
User.find(1).reload
```

- `ActiveRecord::Relation#reload`, eg:

```ruby
# When reload is called after the associated target has been loaded, the cache will be skipped.
User.where(id: 1).load.reload
```

- `ActiveRecord::Associations::Association#reload`, eg:

```ruby
# When reload is called after the associated target has been loaded, the cache will be skipped.
user.association(:account).load_target.reload
```

Delete cache:

- `ArCache::Table`, eg:

```ruby
User.ar_cache_table.delete(id...)
User.first.ar_cache_table.delete(id...)
```

## Configuration

For configuration information, please see [configuration](lib/generators/ar_cache/templates/configuration.rb) file.

## Cacheable query

If all the following conditions are met, ArCache will try to read the cache:

- **Use hash as `#where` parameter**.
- Query condition contains unique index.
- Condition of unique index is only one array or no array.
- No call `#select` or select value is table column.
- No call `#order` or order value is table column and only one.
- No call `#limit` or value of the unique index isn't array.
- No call `#joins`, `#left_joins`, `#skip_query_cache!`, `#explain`, `#from`, `#group`, `#offset`, `#lock`
- ...

**Cacheable example:**

```ruby
User.find(1) # support primary key cache
User.where(id: [1, 2]) # support multi-value unique index cache
User.where(email: 'foobar@gmail.com') # support sigle-column unique index cache
User.where(name: 'foobar', status: :active) # support multi-column unique index cache
User.includes(:account).where(id: [1, 2]) # support association preload cache
User.first.account # support association reader cach
```

The association cache support belongs_to and has_one, small amount of complex has_one(scope, through:, as:) don't support, then has_many cache support, please watch to future version.

## Cache iteration

The following cases will cause cache iteration：

- Table field changes.
- Turn on `ArCache` or turn off `ArCache`.
- Call `#upsert_all` method.

**Notice: After iteration, all existing caches of the table will be expired!**

## How it works(Work in progress)

`ArCache` works based on the unique index of the table.

## Warning

- Prohibit the use of `#execute` update/delete operations!
- Prohibit use `ActiveRecord` other underlying methods to directly update/delete data! (You is a fake activerecord user if this code appears)
- Prohibit skip `ActiveRecord` directly update/delete data!

If you have to do this, please consider turning off ArCache.

## Alternatives

There are some other gems implementations for `ActiveRecord` cache such as:

- [identity_cache](https://github.com/Shopify/identity_cache)
- [second_level_cache](https://github.com/hooopo/second_level_cache)
- [cache-money](https://github.com/ngmoco/cache-money)

However, `ArCache` has some differences:

- It don’t depend with `ActiveRecord` callbacks, so don’t need to deal with dirty cache manually.
- It cache real database data, so can use it's cache at other places.
- It can automatically handle cache iteration, so don't need to update cache version manually.
- It proxy standard ActiveRecord query, so don't need to modify the code and remember the additional api.
- The new data need to perform a query before the cache will take effect.
- The cache will not be updated after the data is updated, but the cache will be expired directly.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/OuYangJinTing/ar_cache>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/OuYangJinTing/ar_cache/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the `ArCache` project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/OuYangJinTing/ar_cache/blob/master/CODE_OF_CONDUCT.md).

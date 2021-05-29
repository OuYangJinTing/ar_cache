# ArCache

![Test Status](https://github.com/OuYangJinTing/ar_cache/workflows/CI/badge.svg)
[![Gem Version](https://badge.fury.io/rb/ar_cache.svg)](https://badge.fury.io/rb/ar_cache)

`ArCache` 是一个现代的 `ActiveRecord` 查询缓存库，它受 [`cache-money`](https://github.com/ngmoco/cache-money) 和 [`second_level_cache`](https://github.com/hooopo/second_level_cache) 的启发而创作。
当 `ActiveRecord` 实例化查询条件命中唯一索引时，`ArCache` 会拦截此次查询，尝试从缓存中获取结果；如果缓存缺失，
将在 `ActiveRecord` 查询完成后自动填充缓存。`ArCache` 会自动维护缓存的正确性。

## 特点

- **低影响**：如果项目里数据库操作的相关代码符合 `ActiveRecord` 风格的话，那么你可以直接引入 `ArCache`，无需修改任何代码。（[具体细节](#警告)）
- **读缓存**：当实例化查询的条件命中唯一索引时，`ArCache` 会尝试从缓存中获取结果返回。
- **写缓存**：当读缓存操作没有获取到结果时，`ArCache` 会在 `ActiveRecord` 查询操作结束后，写入缓存。
- **删缓存**：在更新或删除数据后，`ArCache` 会自动移除对应的缓存。
- **迭代缓存**：当表结构发生改变后，`ArCache` 会更新这个表对应的缓存版本。
- **共享缓存**：`ArCache` 里面缓存是完整的表字段和数据的哈希结果的 `json` 序列化字符串（仅当使用 `redis/memcached` 作为存储器时），因此缓存的使用是没有局限的。（[实例](examples)）

## 安装

向项目的 `Gemfile` 文件里增加一行内容：

```ruby
gem 'ar_cache'
```

之后，执行：

```shell
bundle install
```

## 初始化配置文件

如果是 `rails` 项目，直接执行命令：

```shell
rails generate ar_cache:install
```

不是，则将 [configuration.rb](lib/generators/ar_cache/templates/configuration.rb) 文件手动复制到项目对应的目录。

## 配置项

关于配置项的说明，请直接查看 [configuration.rb](lib/generators/ar_cache/templates/configuration.rb) 文件.

## 用法

删除缓存：

- `ArCache::Table#delete`, 例如：

```ruby
User.ar_cache_table.delete(id...)
User.first.ar_cache_table.delete(id...)
```

跳过缓存：

- `ArCache#skip_cache`, 例如：

```ruby
ArCache.skip_cache do
  # 块里面的全部查询将跳过缓存
end
```

- `ActiveRecord::Persistence#reload`, 例如：

```ruby
User.find(1).reload
```

- `ActiveRecord::Relation#reload`, 例如：

```ruby
# 当 relation 已加载查询后，再调用 reload 方法时，将跳过缓存 
User.where(id: 1).load.reload
```

- `ActiveRecord::Associations::Association#reload`, 例如：

```ruby
# 当关联对象已加载查询后，再调用 reload 方法时，将跳过缓存 
user.association(:account).load_target.reload
```

其它的都是没必要知道的。

## 可读缓存的查询

必须满足下列全部条件:

- 使用哈希作为查询条件
- 查询条件包含唯一索引
- 没有事务存在，或者事务里面没有查询表的更新或删除操作（后续会尝试解除这个限制）
- 没有调用过 `select` 方法，或者 `select` 字段都是表字段
- 没有调用过 `order/order!` 方法，或者 `order` 字段只有一个，并且该字段是表字段
- 没有调用过 `limit/limit!` 方法，或者查询条件只能命中一个结果
- 没有调用过 `skip_query_cache!` 方法
- 没有调用过 `lock/lock!` 方法
- 没有调用过 `distinct/distinct!` 方法
- 没有调用过 `group/group!` 方法
- 没有调用过 `joins/joins!` 方法
- 没有调用过 `left_outer_joins/left_outer_joins!` 方法
- 没有调用过 `offset/offset!` 方法
- 没有调用过 `eager_load/eager_load!` 方法
- 没有调用过 `references/references!` 方法
- 没有调用过 `from/from!` 方法
- ...

```ruby
User.find(1) # 主键查询是可读缓存的
User.where(email: 'foobar@gmail.com') # 唯一索引查询是可读缓存的
User.where(id: [1, 2]) # 唯一索引有多个值的情况，依然是可读缓存的
User.where(name: 'foobar', status: :active) # 联合字段的唯一索引查询是可读缓存的
User.includes(:account).where(id: [1, 2]) # ActiveRecord 的预加载是可读缓存的（仅当为 has_one 关联时）
User.first.account # ActiveRecord 的关联对象是可读缓存的（仅当为 has_one 关联时）
```

NOTE: `has_many` 的关联缓存，后续会尝试支持，但希望不大。

## 缓存迭代

`ArCache` 的缓存是以表为层级的，当触发缓存迭代后，这个表的全部缓存都会失效，导致一种类似缓存雪崩的情况，请特别注意。
下述的这些情况会导致缓存迭代：

- 表结构发生变化
- 激活/禁用 `ArCache`
- 使用 `ActiveRecord::Persistence::ClassMethods#upsert_all` 方法

## 注意事项

- `ArCache` 的缓存清除操作，是在事务提交或 `sql` 操作结束后开始的，这意味是可能出现脏读的（后续会尝试解决）。
- `ArCache` 缓存数据是完整的表行数据，因此当 `sql` 包含 `select` 字段，并且缓存缺失时，`ArCache` 会将其改成 `select *`，但最终实例化的对象依旧符合预期。
- 当使用跳过 `ActiveReord` 的回调方法，更新/删除数据时，`ArCache` 可能会多执行一条 `select primary_key` 的 `sql`，因为清除缓存需要 `primary_key` 数据。

## 警告

下述的这些情况都是严禁发生的行为，这些行为会导致 `ArCache` 的缓存正确性。  
PS：`ActiveRecord` 使用者，不应该写出这些代码。

- 直接使用 `execute` 方法 更新/删除 数据。
- 直接使用比 `execute` 更底层方式，更新/删除 数据。
- 跳过 `ActiveRecord` 直接 更新/删除 数据。（后续会提供数据库触发器来解除这个限制）

如果这些行为无法避免的话，请按照上述[删除缓存](#用法)的方法，手动删除受影响的缓存数据，或者干脆直接禁止对应表的 `ArCache` 功能。

## 其它类似的库

这里还有一些其它的 `gem`，也提供了 `ActiveRecord` 的查询缓存功能。

- [identity_cache](https://github.com/Shopify/identity_cache)
- [second_level_cache](https://github.com/hooopo/second_level_cache)
- [cache-money](https://github.com/ngmoco/cache-money)

`ArCache` 跟他们存在一些下述的差异：

- `ArCache` 不依赖 `ActiveRecord` 的 `commit` 回调，所以你可以无所顾虑的直接使用跳过回调的方法。
- `ArCache` 的缓存是 `json` 序列化，不是 `Marshal` 序列化，所以缓存的使用是没有局限的。（仅当使用 `redis/memcached` 作为存储器时）
- `ArCache` 自动代理了标准的 `ActiveRecord` 实例化查询请求，所以不需要额外学习怎么使用缓存。
- `ArCache` 缓存是懒写入的，因此新创建的数据，不会直接写入缓存。
- `ArCache` 不会热更新缓存，因此数据被更新后，缓存就没有了。
- ...

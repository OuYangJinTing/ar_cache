# Change log

## main

## 1.4.0 (2021-03-15 UTC)

[Commit [#7cc9ec8](https://github.com/OuYangJinTing/ar_cache/commit/7cc9ec8047394bb7758e25edd3b42fa48bb88640)]:

- Remove `ArCache::Table` `ignored_columns` configuration.
- Fix `ActiveRecord` call `#select` write to cache data is incomplete.

## 1.3.0 (2021-03-13 UTC)

- [Commit [#4ec14e9](https://github.com/OuYangJinTing/ar_cache/commit/4ec14e9e762abb57a8ff18aa8c93a514db49c552)]: Optimize association cache, only cacheable association use ArCache query now.

## 1.2.0 (2021-03-12 UTC)

[Commit [#c830907](https://github.com/OuYangJinTing/ar_cache/commit/c830907595b7d1d46a2f29204ee6051ecc3ff30c)]:

- Remove methods: `ArCache::MockTable#enabled?`, `ArCache::MockTable#select_enabled?`, `ArCache::Table.enabled?`, `ArCache::Table.select_enabled?`, `ActiveRecord::Relation#skip_ar_cache`.
- Rename methods: `ArCache#skip_cache? => ArCache#skip?`, `ArCache#skip_cache => ArCache#skip`, `ArCache#pre_expire? => ArCache#expire?`, `ArCache#pre_expire => ArCache#expire`.
- Now, `ArCache#skip` method only skip read cache, but still try delete cache.

## 1.1.0 (2021-03-10 UTC)

- [Commit [#92965d2](https://github.com/OuYangJinTing/ar_cache/commit/92965d26e130da9a13bd52ea31f3f668851f6f12)] Fully automatic delete cache when call delete_all/update_all method.
- [Commit [#231cfd3](https://github.com/OuYangJinTing/ar_cache/commit/231cfd35c2c197bf41628f4f914ba39fb8debd81)] Optimize has_one(through:) cache implementation.
- [Commit [#ce5444c](https://github.com/OuYangJinTing/ar_cache/commit/ce5444c8c4ec0a61bec5e07d694295d3cc5decf8)]  ActiveRecord::Relation#reload and ActiveRecord::Associations::Association#reload should skip read cache if associated target is already loaded.

## 1.0.0 (2021-03-02 UTC)

- Initial version.

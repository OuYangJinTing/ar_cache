# Change log

## main

## 1.2.0 (2021-03-12)

[Commit [#c830907](https://github.com/OuYangJinTing/ar_cache/commit/c830907595b7d1d46a2f29204ee6051ecc3ff30c)]:

- Remove methods: `ArCache::MockTable#enabled?`, `ArCache::MockTable#select_enabled?`, `ArCache::Table.enabled?`, `ArCache::Table.select_enabled?`, `ActiveRecord::Relation#skip_ar_cache`.
- Rename methods: `ArCache#skip_cache? => ArCache#skip?`, `ArCache#skip_cache => ArCache#skip`, `ArCache#pre_expire? => ArCache#expire?`, `ArCache#pre_expire => ArCache#expire`.
- Now, `ArCache#skip` method only skip read cache, but still try delete cache.

## 1.1.0 (2021-03-11)

- [Commit [#92965d2](https://github.com/OuYangJinTing/ar_cache/commit/92965d26e130da9a13bd52ea31f3f668851f6f12)] Fully automatic delete cache when call delete_all/update_all method.
- [Commit [#231cfd3](https://github.com/OuYangJinTing/ar_cache/commit/231cfd35c2c197bf41628f4f914ba39fb8debd81)] Optimize has_one(through:) cache implementation.
- [Commit [#ce5444c](https://github.com/OuYangJinTing/ar_cache/commit/ce5444c8c4ec0a61bec5e07d694295d3cc5decf8)]  ActiveRecord::Relation#reload and ActiveRecord::Associations::Association#reload should skip read cache if associated target is already loaded.

## 1.0.0 (2021-03-02)

- Initial version.

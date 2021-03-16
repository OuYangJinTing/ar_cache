# Change log

## main

## 1.4.0 (2021-03-15 UTC)

[Compare [#3ff0bb8..7cc9ec8](https://github.com/OuYangJinTing/ar_cache/compare/3ff0bb8..7cc9ec8)]:

- Remove `ArCache::Table` `ignored_columns` configuration.
- Fix `ActiveRecord` call `#select` write to cache data is incomplete.

## 1.3.0 (2021-03-13 UTC)

[Compare [#4328f38..4ec14e9](https://github.com/OuYangJinTing/ar_cache/compare/4328f38..4ec14e9)]:

- Optimize association cache, only cacheable association use ArCache query now.

## 1.2.0 (2021-03-12 UTC)

[Compare [#eb27f99..c830907](https://github.com/OuYangJinTing/ar_cache/compare/eb27f99..c830907)]:

- Remove methods: `ArCache::MockTable#enabled?`, `ArCache::MockTable#select_enabled?`, `ArCache::Table.enabled?`, `ArCache::Table.select_enabled?`, `ActiveRecord::Relation#skip_ar_cache`.
- Rename methods: `ArCache#skip_cache? => ArCache#skip?`, `ArCache#skip_cache => ArCache#skip`, `ArCache#pre_expire? => ArCache#expire?`, `ArCache#pre_expire => ArCache#expire`.
- Now, `ArCache#skip` method only skip read cache, but still try delete cache.

## 1.1.0 (2021-03-10 UTC)

[Compare [#a15d5f5..ce5444c](https://github.com/OuYangJinTing/ar_cache/compare/a15d5f5...ce5444c)]:

- Fully automatic delete cache when call delete_all/update_all method.
- Optimize has_one(through:) cache implementation.
- ActiveRecord::Relation#reload and ActiveRecord::Associations::Association#reload should skip read cache if associated target is already loaded.

## 1.0.0 (2021-03-02 UTC)

- Initial version.

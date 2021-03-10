# Change log

## main

## 1.0.0 (2021-03-02)

- Initial version.

## 1.1.0 (2021-03-11)

- Fully automatic delete cache when call delete_all/update_all method.
- Optimize has_one(through:) cache implementation.
- ActiveRecord::Relation#reload and ActiveRecord::Associations::Association#reload should skip read cache if associated target is already loaded.

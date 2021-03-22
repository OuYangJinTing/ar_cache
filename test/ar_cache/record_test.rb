# frozen_string_literal: true

require 'test_helper'

module ArCache
  describe Record do
    it 'should disable ArCache' do
      assert ArCache::Record.ar_cache_table.disabled?
    end

    it '#store should update version if table_md5 changed' do
      savepoint do
        User.ar_cache_table.stub :md5, '1' * 32 do
          record = ArCache::Record.get(User.table_name)
          record.store(User.ar_cache_table)
          assert(record.previous_changes.any? { |k, _| k == 'version' })
        end
      end
    end

    it '#with_optimistic_retry should correctly udpate when udpate a row at same tiem' do
      first_user_record = ArCache::Record.get(User.table_name)
      second_user_record = ArCache::Record.get(User.table_name)

      first_user_record.update_version
      second_user_record.update_version

      assert_equal first_user_record.version + 1, second_user_record.version
    end
  end
end

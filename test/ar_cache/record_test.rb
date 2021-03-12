# frozen_string_literal: true

require 'test_helper'

module ArCache
  describe Record do
    User.ar_cache_table # Initialize table object

    let(:record) { ArCache::Record.new(table_name: 'mock') }
    let(:user_record) { ArCache::Record.get(User.table_name) }

    describe '#attributes' do
      it 'should respond to table_name' do
        assert_respond_to record, :table_name
      end

      it 'table_name should be is unique' do
        record.save!
        record.dup.save!
      rescue ::ActiveRecord::RecordNotUnique => e
        assert_includes e.message, 'table_name'
      end

      it 'table_md5 should has a default value' do
        assert '0' * 32, record.table_md5
      end

      it 'version should has a default value' do
        assert 0, record.version
      end

      it 'lock_version should has a default value' do
        assert 0, record.lock_version
      end
    end

    describe '#store' do
      it 'should update version if table_md5 changed' do
        savepoint do
          User.ar_cache_table.stub :md5, '1' * 32 do
            user_record.store(User.ar_cache_table)
            assert(user_record.previous_changes.any? { |k, _| k == 'version' })
          end
        end
      end
    end

    describe '#with_optimistic_retry' do
      it 'should correctly udpate when udpate a row at same tiem' do
        first_user_record = ArCache::Record.get(User.table_name)
        second_user_record = ArCache::Record.get(User.table_name)

        first_user_record.update_version
        second_user_record.update_version

        assert_not_equal first_user_record.version, second_user_record.version
      end
    end
  end
end

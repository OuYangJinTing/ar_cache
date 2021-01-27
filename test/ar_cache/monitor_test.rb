# frozen_string_literal: true

require 'test_helper'

module ArCache
  describe Monitor do
    let(:monitor) { ArCache::Monitor.new }
    let(:user_model) { ArCache::Model.get(User) }

    describe '.attributes method' do
      it '.table_name' do
        assert_respond_to monitor, :table_name
      end

      it '.version' do
        assert_respond_to monitor, :version
      end

      it '.disabled' do
        assert_respond_to monitor, :disabled
      end

      it '.unique_indexes' do
        assert_respond_to monitor, :unique_indexes
      end

      it '.ignored_columns' do
        assert_respond_to monitor, :ignored_columns
      end
    end

    describe '#default_scope' do
      it 'default call skip_ar_cache' do
        assert Monitor.all.instance_variable_get(:@skip_ar_cache)
      end
    end

    describe '#activate' do
      it 'should create if model monitor not found' do
        ArCacheHelper.remove_monitor(User)
        Monitor.activate(user_model)

        assert Monitor.get(user_model.table_name).persisted?
      end

      describe 'should not update version' do
        it 'when model.disabled equal monitor.disabled' do
          last_verion = Monitor.get(user_model.table_name).version

          ArCacheHelper.with_reset_model(User, disabled: user_model.disabled) do
            assert_equal last_verion, Monitor.get(user_model.table_name).version
          end
        end

        it 'when model.unique_indexes include monitor.unique_indexes' do
          refute(user_model.unique_indexes.any? { |index| index == ['created_at'] })

          last_verion = Monitor.get(user_model.table_name).version

          ArCacheHelper.with_reset_model(User, unique_indexes: user_model.unique_indexes + [['created_at']]) do
            assert_equal last_verion, Monitor.get(user_model.table_name).version
          end
        end

        it 'when model.ignored_columns include monitor.ignored_columns' do
          assert_not_includes User.ignored_columns, 'role'

          last_verion = Monitor.get(user_model.table_name).version

          ArCacheHelper.with_reset_model(User, ignored_columns: User.ignored_columns + ['role']) do
            assert_equal last_verion, Monitor.get(user_model.table_name).version
          end
        end
      end

      describe 'should update version' do
        it 'when model.disabled not equal monitor.disabled' do
          last_verion = Monitor.get(user_model.table_name).version

          ArCacheHelper.with_reset_model(User, disabled: !user_model.disabled) do
            assert_not_equal last_verion, Monitor.get(user_model.table_name).version
          end
        end

        it 'when model.unique_indexes not include monitor.unique_indexes' do
          assert user_model.unique_indexes.any?

          last_verion = Monitor.get(user_model.table_name).version

          ArCacheHelper.with_reset_model(User, unique_indexes: []) do
            assert_not_equal last_verion, Monitor.get(user_model.table_name).version
          end
        end

        it 'when model.ignored_columns not include monitor.ignored_columns' do
          assert_not_empty User.ignored_columns

          last_verion = nil
          ArCacheHelper.with_reset_model(User, ignored_columns: []) do
            last_verion = Monitor.get(user_model.table_name).version
          end

          assert_not_equal last_verion, Monitor.get(user_model.table_name).version
        end
      end
    end

    describe '#extract_table_from_sql' do
      it 'should raise SqlOperationError if type is not update and delete' do
        assert_raise(ArCache::SqlOperationError) { Monitor.extract_table_from_sql('', :insert) }
      end

      it 'should extract table name from update sql statement' do
        sql = <<-SQL
          UPDATE
            `#{User.table_name}`
          SET
            status = 1
          WHERE
            status = 1;
        SQL

        assert_equal User.table_name, Monitor.extract_table_from_sql(sql, :update)
      end

      it 'should extract table name from delete sql statement' do
        sql = <<-SQL
          DELETE
          FROM
            `#{User.table_name}`
          WHERE
            status = 1;
        SQL

        assert_equal User.table_name, Monitor.extract_table_from_sql(sql, :delete)
      end
    end

    it '#update_version' do
      old_user_model_version   = user_model.version
      old_user_monitor_version = ArCache::Monitor.get(user_model.table_name).version
      assert_equal old_user_monitor_version, old_user_model_version

      ArCache::Monitor.update_version(user_model.table_name)

      new_user_model_version   = ArCache::Model.get(User).version
      new_user_monitor_version = ArCache::Monitor.get(user_model.table_name).version
      assert_equal new_user_monitor_version, new_user_model_version

      assert_not_equal old_user_monitor_version, new_user_monitor_version
      assert_not_equal old_user_model_version, new_user_model_version
    end

    it '.update_version' do
    end
  end
end

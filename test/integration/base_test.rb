# frozen_string_literal: true

require 'test_helper'

# describe 'BaseTest' do
#   let(:foobar) { users(:foobar) }
#   let(:foobar_primary_cache_key) { primary_cache_key(foobar) }
#   let(:zhangsan) { users(:zhangsan) }
#   let(:zhangsan_primary_cache_key) { primary_cache_key(zhangsan) }

#   describe 'UseUniqueIndexQuery' do
#     it 'should fetch from cache first' do
#       assert_cache(:any_read, foobar_primary_cache_key) do
#         User.find_by(id: foobar.id)
#       end
#     end

#     it 'should write cache if missing' do
#       delete_cache(foobar)
#       assert_cache(:any_write, foobar_primary_cache_key) do
#         User.find(foobar.id)
#       end
#     end

#     it 'should use cache if exist' do
#       write_cache(foobar)
#       assert_no_queries do
#         assert_model_equal foobar, User.find(foobar.id)
#       end
#     end

#     it 'should support fetch cache by combined column' do
#       write_cache(foobar)
#       assert_no_queries do
#         assert_model_equal foobar, User.find_by(name: foobar.name, status: foobar.status)
#       end
#     end

#     it 'should support batch fetch cache' do
#       write_cache(foobar, zhangsan)
#       assert_no_queries do
#         assert_model_equal [foobar, zhangsan], User.find(foobar.id, zhangsan.id)
#       end
#     end

#     it 'should support batch fetch cache by combined column' do
#       write_cache(foobar, zhangsan)
#       assert_no_queries do
#         assert_model_equal [foobar, zhangsan], User.where(name: [foobar.name, zhangsan.name], status: foobar.status).to_a # rubocop:disable Layout/LineLength
#       end
#     end
#   end

#   describe 'ExpireCache' do
#     it 'should expire cache after update record' do
#       write_cache(foobar)
#       foobar.update(status: :archived)
#       assert_blank_cache foobar_primary_cache_key
#     end

#     it 'should expire cache after delete record' do
#       write_cache(foobar)
#       foobar.destroy
#       assert_blank_cache foobar_primary_cache_key
#     end

#     it 'should expire cache after update(skip callback) record' do
#       write_cache(foobar)
#       foobar.update_columns(status: :archived)
#       assert_blank_cache foobar_primary_cache_key
#     end

#     it 'should expire cache after delete(skip callback) record' do
#       write_cache(foobar)
#       foobar.delete
#       assert_blank_cache foobar_primary_cache_key
#     end

#     it 'should batch expire cache after update all records' do
#       write_cache(foobar, zhangsan)
#       User.update_all(status: :archived)
#       assert_blank_cache foobar_primary_cache_key
#       assert_blank_cache zhangsan_primary_cache_key
#     end

#     it 'should batch expire cache after delete all records' do
#       write_cache(foobar, zhangsan)
#       User.delete_all
#       assert_blank_cache foobar_primary_cache_key
#       assert_blank_cache zhangsan_primary_cache_key
#     end
#   end

#   describe 'Transaction' do
#     it 'should skip read and write cache if exist table transaction' do
#       key = nil

#       User.transaction do
#         user = User.new(name: 'lisi', email: 'lisi@test.com')
#         user.save
#         key = primary_cache_key(user)
#         assert_no_cache(:any_read, key) do
#           assert_no_cache(:any_write, key) do
#             User.find(user.id)
#           end
#         end
#       end

#       assert_not ArCache.read(key)
#     end
#   end

#   describe 'AssociationCache' do
#     # TODO
#   end
# end

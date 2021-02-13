# frozen_string_literal: true

module ArCache
  describe Store do
    it 'should respond to write' do
      assert_respond_to ArCache::Store, :write
    end

    it 'should respond to write_multi' do
      assert_respond_to ArCache::Store, :write_multi
    end

    it 'should respond to read' do
      assert_respond_to ArCache::Store, :read
    end

    it 'should respond to read_multi' do
      assert_respond_to ArCache::Store, :read_multi
    end

    it 'should respond to delete' do
      assert_respond_to ArCache::Store, :delete
    end

    it 'should respond to delete_multi' do
      assert_respond_to ArCache::Store, :delete_multi
    end

    it 'should call dump when call write' do
      assert_called ArCache::Store, :dump do
        ArCache::Store.write(:foo, :bar)
      end
    end

    it 'should call dump when call write_multi' do
      assert_called ArCache::Store, :dump do
        ArCache::Store.write_multi(foo: :bar)
      end
    end

    it 'should call load when call read' do
      assert_called ArCache::Store, :load do
        ArCache::Store.write(:foo, :bar)
        ArCache::Store.read(:foo)
      end
    end

    it 'should call load when call read_multi' do
      assert_called ArCache::Store, :load do
        ArCache::Store.write(:foo, :bar)
        ArCache::Store.read_multi(:foo)
      end
    end
  end
end

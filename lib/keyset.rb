require 'active_support/core_ext/module/aliasing'

class KeySet < Set

  def initialize(store, store_key)
    @store = store
    @mutex = Mutex.new
    @store_key = store_key
    super(get_keys)
    @keys = self.keys
  end

  def get_keys
    existing = nil
    with_mutex do
      existing = @store.send(:read_entry, @store_key, {})
    end

    if existing
      if existing.is_a? ActiveSupport::Cache::Entry
        YAML.load(existing.value)
      else
        YAML.load(existing)
      end
    else
      []
    end
  end

  def keys
    @keys ||= []
  end

  def add_with_cache(value)
    add_without_cache(value)
  ensure
    @keys = (self.to_a + get_keys).uniq
    store
  end

  alias_method_chain :add, :cache

  def delete_with_cache(value)
    delete_without_cache(value)
  ensure
    @keys = (self.to_a + get_keys).uniq - [value]
    store
  end

  alias_method_chain :delete, :cache

  def clear_with_cache
    clear_without_cache
  ensure
    @keys = []
    store
  end

  alias_method_chain :clear, :cache

  private
  def store
    with_mutex do
      @store.with do |connection|
        @store.send(:write_entry_without_match_support, @store_key, keys.to_yaml, {connection: connection})
      end
    end
  end

  def with_mutex
    #@mutex.synchronize { yield }
    yield
  end
end

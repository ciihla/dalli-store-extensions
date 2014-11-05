require 'active_support/core_ext/module/aliasing'

class KeySet < Set
  @@singleton__instance__ = nil
  @@singleton__mutex__ = Mutex.new

  def self.instance(store, store_key)
    return @@singleton__instance__ if @@singleton__instance__
    @@singleton__mutex__.synchronize do
      return @@singleton__instance__ if @@singleton__instance__
      @@singleton__instance__ = new(store, store_key)
    end
    @@singleton__instance__
  end

  def initialize(store, store_key)
    @store = store
    @store_key = store_key

    if existing=@store.send(:read_entry, @store_key, {})
      if existing.is_a? ActiveSupport::Cache::Entry
        super(YAML.load(existing.value))
      else
        super(YAML.load(existing))
      end
    else
      super([])
    end
  end

  def add_with_cache(value)
    add_without_cache(value)
  ensure
    store
  end

  alias_method_chain :add, :cache

  def delete_with_cache(value)
    delete_without_cache(value)
  ensure
    store
  end

  alias_method_chain :delete, :cache

  def clear_with_cache
    clear_without_cache
  ensure
    store
  end

  alias_method_chain :clear, :cache
  private
  def store
    @store.with do |connection|
      @store.send(:write_entry_without_match_support, @store_key, self.to_a.to_yaml, { connection: connection})
    end
  end
end

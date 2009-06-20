module Cash
  module Accessor
    def self.included(a_module)
      a_module.module_eval do
        extend ClassMethods
        include InstanceMethods
      end
    end

    module ClassMethods
      NIL_CACHE_VALUE = 'NIL_CACHE_VALUE'
      
      def fetch(keys, options = {}, &block)
        case keys
        when Array
          cache_and_actual_keys = keys.inject({}) { |memo, key| memo[cache_key(key)] = key; memo }
          cache_keys = keys.collect {|key| cache_key(key)}
          
          hits = repository.get_multi(cache_keys)
          if (missed_cache_keys = cache_keys - hits.keys).any?
            actual_missed_keys = missed_cache_keys.collect {|missed_cache_key| cache_and_actual_keys[missed_cache_key]}
            misses = block.call(actual_missed_keys)

            hits.merge!(misses)
          end
          hits
        else
          repository.get(cache_key(keys), options[:raw]) || (block ? block.call : nil)
        end
      end

      def get(keys, options = {}, &block)
        case keys
        when Array
          results = fetch(keys, options) do |missed_keys|
            results = yield(missed_keys)
            results.each {|key, value| add(key, wrap_nil(value), options)}
            results
          end
          results.each { |key, result| results[key] = unwrap_nil(result) }
        else
          result = fetch(keys, options) do
            if block_given?
              result = yield(keys)
              value = result.is_a?(Hash) ? result[cache_key(keys)] : result
              add(keys, wrap_nil(value), options)
              result
            end
          end
          unwrap_nil(result)
        end
      end
      
      def add(key, value, options = {})
        if repository.add(cache_key(key), value, options[:ttl] || 0, options[:raw]) == "NOT_STORED\r\n"
          yield if block_given?
        end
      end

      def set(key, value, options = {})
        repository.set(cache_key(key), value, options[:ttl] || 0, options[:raw])
      end

      def incr(key, delta = 1, ttl = 0)
        repository.incr(cache_key = cache_key(key), delta) || begin
          repository.add(cache_key, (result = yield).to_s, ttl, true) { repository.incr(cache_key) }
          result
        end
      end

      def decr(key, delta = 1, ttl = 0)
        repository.decr(cache_key = cache_key(key), delta) || begin
          repository.add(cache_key, (result = yield).to_s, ttl, true) { repository.decr(cache_key) }
          result
        end
      end

      def expire(key)
        repository.delete(cache_key(key))
      end

      def cache_key(key)
        ready = key =~ /#{name}:#{cache_config.version}/
        ready ? key : "#{name}:#{cache_config.version}/#{key.to_s.gsub(' ', '+')}"
      end
      
      private
      
      def wrap_nil(value)
        value.nil? ? NIL_CACHE_VALUE : value
      end

      def unwrap_nil(value)
        value == NIL_CACHE_VALUE ? nil : value
      end

    end

    module InstanceMethods
      def expire
        self.class.expire(id)
      end
    end
  end
end

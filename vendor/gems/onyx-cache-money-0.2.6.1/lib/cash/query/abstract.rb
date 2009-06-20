module Cash
  module Query
    class Abstract
      delegate :with_exclusive_scope, :get, :quoted_table_name, :connection, :indices, 
        :find_every_without_cache, :cache_key, :columns_hash, :quote_value, :to => :@active_record

      def self.perform(*args)
        new(*args).perform
      end

      def initialize(active_record, options1, options2)
        @active_record, @options1, @options2 = active_record, options1, options2 || {}
      end

      def perform(find_options = {}, get_options = {})
        if cache_config = cacheable?(@options1, @options2, find_options)
          cache_keys, index = cache_keys(cache_config[0]), cache_config[1]

          misses, missed_keys, objects = hit_or_miss(cache_keys, index, get_options)
          format_results(cache_keys, choose_deserialized_objects_if_possible(missed_keys, cache_keys, misses, objects))
        else
          uncacheable
        end
      end

      DESC = /DESC/i

      def order
        @order ||= begin
          if order_sql = @options1[:order] || @options2[:order]
            matched, table_name, column_name, direction = *(ORDER.match(order_sql))
            [column_name, direction =~ DESC ? :desc : :asc]
          else
            ['id', :asc]
          end
        end
      end

      def limit
        @limit ||= @options1[:limit] || @options2[:limit]
      end

      def offset
        @offset ||= @options1[:offset] || @options2[:offset] || 0
      end

      def calculation?
        false
      end

      private
      def cacheable?(*optionss)
        # Cache money used to cache queries with order option only when order was "id asc";
        #   For now, we just want all order queries to go to the database always.
        return if optionss.find {|options| options[:order] }
        optionss.each { |options| return unless safe_options_for_cache?(options) }
        partial_indices = optionss.collect { |options| attribute_value_pairs_for_conditions(options[:conditions]) }
        return if partial_indices.flatten.include?(nil)
        attribute_value_pairs = partial_indices.sum.sort { |x, y| x[0] <=> y[0] }
        if index = indexed_on?(attribute_value_pairs.collect { |pair| pair[0] })
          if index.matches?(self)
            [attribute_value_pairs, index]
          end
        end
      end

      def hit_or_miss(cache_keys, index, options)
        misses, missed_keys = nil, nil
        objects = @active_record.get(cache_keys, options.merge(:ttl => index.ttl)) do |missed_keys|
          misses = miss(missed_keys, @options1.merge(:limit => index.window))
          serialize_objects(index, misses)
        end
        [misses, missed_keys, objects]
      end

      def cache_keys(attribute_value_pairs)
        cache_keys = collect_cache_keys(attribute_value_pairs)
        cache_keys.size == 1 ? cache_keys.first : cache_keys
      end
      
      def collect_cache_keys(pairs)
        return [] if pairs.empty?
        key, values = pairs.shift
        Array(values).inject([]) do |memo,value|
          partial_keys = collect_cache_keys(pairs.clone)

          memo << "#{key}/#{value}" if partial_keys.empty?
          partial_keys.each { |partial_key| memo << "#{key}/#{value}/#{partial_key}" }
          memo
        end
      end

      def safe_options_for_cache?(options)
        return false unless options.kind_of?(Hash)
        options.except(:conditions, :readonly, :limit, :offset, :order).values.compact.empty? && !options[:readonly]
      end

      def attribute_value_pairs_for_conditions(conditions)
        case conditions
        when Hash
          conditions.to_a.collect { |key, value| [key.to_s, value] }
        when String
          parse_indices_from_condition(conditions)
        when Array
          # do not cache find(:conditions => ["... :attr", {:attr => 1}]
          return nil if conditions.last.is_a?(Hash)
          parse_indices_from_condition(*conditions)
        when NilClass
          []
        end
      end

      AND = /\s+AND\s+/i
      TABLE_AND_COLUMN = /(?:(?:`|")?(\w+)(?:`|")?\.)?(?:`|")?(\w+)(?:`|")?/              # Matches: `users`.id, `users`.`id`, users.id, id
      VALUE = /'?(\d+|\?|(?:(?:[^']|'')*?))'?/                                            # Matches: 123, ?, '123', '12 ''3'
      KEY_EQ_VALUE = /^\(?#{TABLE_AND_COLUMN}\s+(?:=|IN)\s+\(?(?:#{VALUE})\)?\)?$/      # Matches: KEY = VALUE, (KEY = VALUE), KEY IN (VALUE,VALUE,..)
      ORDER = /^#{TABLE_AND_COLUMN}\s*(ASC|DESC)?$/i                                      # Matches: COLUMN ASC, COLUMN DESC, COLUMN

      def parse_indices_from_condition(conditions = '', *values)
        values = values.dup
        conditions.split(AND).inject([]) do |indices, condition|
          matched, table_name, column_name, sql_values = *(KEY_EQ_VALUE.match(condition))
          if matched
            actual_values = sql_values.split(',').collect do |sql_value|
              sql_value == '?' ? values.shift : columns_hash[column_name].type_cast(sql_value)
            end
            actual_values.flatten!
            indices << [column_name, actual_values]
          else
            return nil
          end
        end
      end

      def indexed_on?(attributes)
        indices.detect { |index| index == attributes }
      end
      alias_method :index_for, :indexed_on?

      def format_results(cache_keys, objects)
        return [] if objects.blank?
        objects = convert_to_array(cache_keys, objects)
        objects = apply_limits_and_offsets(objects, @options1)
        deserialize_objects(objects)
      end

      def choose_deserialized_objects_if_possible(missed_keys, cache_keys, misses, objects)
        missed_keys == cache_keys ? misses : objects
      end

      def serialize_objects(index, objects_hash)
        objects_hash.each do |key, objects|
          objects_hash[key] = index.serialize_objects(objects)
        end
      end

      def convert_to_array(cache_keys, object)
        if object.kind_of?(Hash)
          cache_keys.collect { |key| object[cache_key(key)] }.flatten.compact
        else
          Array(object)
        end
      end

      def apply_limits_and_offsets(results, options)
        results.slice((options[:offset] || 0), (options[:limit] || results.length))
      end

      def deserialize_objects(objects)
        if objects.first.kind_of?(ActiveRecord::Base)
          objects
        else
          cache_keys = objects.collect { |id| "id/#{id}" }
          objects = get(cache_keys) {|missed_keys| find_from_keys(missed_keys)}
          convert_to_array(cache_keys, objects)
        end
      end

      def find_from_keys(missing_keys, options = {})
        #[[id/1/title/foo], [id/1/title/foo]]
        missing_keys_values_pairs = Array(missing_keys).flatten.collect { |key| key.split('/') }
        #[[id,1,title,foo], [id,2,title,foo]]

        conditions = conditions_from_missing_keys_values_pairs(missing_keys_values_pairs)
        results = find_every_without_cache options.merge(:conditions => conditions)
        # [<object1>, <object2>, <object3>]

        collect_results_into_hash(missing_keys_values_pairs, Array(results))
        #{ id/1/title/foo => [<object1>], id/2/title/foo => [<object2>,<object3>] }
      end
      
      def collect_results_into_hash(missing_keys_values_pairs, results)
        missing_keys_values_pairs.inject({}) do |memo, missing_keys_values_pair|
          match = results.select do |result|
            found_match = false
            missing_keys_values_pair.each_slice(2) do |key, value|
              found_match = upcase_if_possible(result.send(key)) == upcase_if_possible(type_cast(key,value))
              break unless found_match
            end
            found_match
          end
          memo[cache_key(missing_keys_values_pair.join('/'))] = match
          memo
        end
      end
      
      def conditions_from_missing_keys_values_pairs(missing_keys_values_pairs)
        keys_values = missing_keys_values_pairs.inject({}) do |memo, missing_keys_values_pair|
          missing_keys_values_pair.each_slice(2) do |key, value|
            memo[key] ||= []
            memo[key] << value
          end
          memo
        end
        # { :id => [1,2], :title => [foo] }

        conditions = keys_values.collect do |key,values|
          quoted_values = values.collect do |value|
            quote_value(type_cast(key, value), columns_hash[key])
          end
          quoted_table_and_column_name = "#{quoted_table_name}.#{connection.quote_column_name(key)}"
          if quoted_values.size == 1
            "#{quoted_table_and_column_name} = #{quoted_values}"
          else
            "#{quoted_table_and_column_name} IN (#{quoted_values.join(',')})"
          end
        end.join(' AND ')
      end
      
      protected 
      
      def type_cast(column_name, value)
        columns_hash[column_name].type_cast(value)
      end
      
      def upcase_if_possible(value)
        value.respond_to?(:upcase) ? value.upcase : value
      end
    end
  end
end

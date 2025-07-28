module ORM
  class QueryBuilder
    include Enumerable

    attr_reader :klass, :query_state

    QUERY_STATE = {
      conditions: [],
      bind_values: [],
      select_attributes: [],
      order_clauses: [],
      limit_value: nil,
      offset_value: nil,
      join_clause: [],
    }.freeze

    class InvalidQueryError < StandardError; end

    def initialize(klass, query_state = {})
      @klass = klass
      @query_state = QUERY_STATE.merge(query_state)
      @loaded = false
      @records = []
    end

    def method_missing(method_name, *args, &block)
      if @klass.respond_to?(method_name)
        result = @klass.send(method_name, *args, &block)
        if result.is_a?(QueryBuilder)
          # 既存のクエリ状態と新しいクエリ状態をマージ
          merge_query_states(result)
        else
          result
        end
      else
        super
      end
    end
    
    def respond_to_missing?(method_name, include_private = false)
      @klass.respond_to?(method_name, include_private) || super
    end

    def all
      self.class.new(@klass)
    end

    def to_a
      self.class.new(@klass,  @query_state).execute
    end

    def first
      new_query_state = @query_state.merge(limit_value: 1)
      self.class.new(@klass, new_query_state).execute.first
    end

    def last
      new_query_state = @query_state.merge(
        order_clauses: [id: :desc],
        limit_value: 1
      )
      self.class.new(@klass, new_query_state).execute.last
    end

    def count
      new_query_state = @query_state.merge(
        select_attributes: ["COUNT(*)"]
      )
      self.class.new(@klass, new_query_state).execute
    end

    def where(attributes = {})
      new_query_state = @query_state.merge(
        conditions: @query_state[:conditions] + [attributes],
        bind_values: @query_state[:bind_values] + normalize_bind_values(attributes.values)
      )
      self.class.new(@klass, new_query_state)
    end

    def select(*attributes)
      new_query_state = @query_state.merge(
        select_attributes: @query_state[:select_attributes] + attributes
      )
      self.class.new(@klass, new_query_state)
    end

    def order(*attributes)
      new_query_state = @query_state.merge(
        order_clauses: @query_state[:order_clauses] + attributes
      )
      self.class.new(@klass, new_query_state)
    end

    def limit(num)
      new_query_state = @query_state.merge(limit_value: num)
      self.class.new(@klass, new_query_state)
    end

    def offset(num)
      new_query_state = @query_state.merge(offset_value: num)
      self.class.new(@klass, new_query_state)
    end
    
    def join(association)
      new_query_state = @query_state.merge(join_clause: association)
      self.class.new(@klass, new_query_state)
    end

    def to_sql
      [
        build_select_clause,
        build_from_clause,
        build_join_clause,
        build_where_clause,
        build_order_clause,
        build_limit_clause,
        build_offset_clause,
      ].reject(&:empty?).join(' ')
    end

    def each(&block)
      load_records unless @loaded
      @records.each(&block)
    end

    def execute
      validate_query_state!
      puts "[SQL] #{to_sql} #{@query_state}"
      raw_records = klass.connection.execute(to_sql, @query_state[:bind_values])
      convert_to_instances(raw_records)
    end

    private
    
    def merge_query_states(other_query_builder)
      new_state = @query_state.dup
      other_state = other_query_builder.query_state
      
      # 条件とバインド値をマージ
      new_state[:conditions] += other_state[:conditions]
      new_state[:bind_values] += other_state[:bind_values]
      
      QueryBuilder.new(@klass, new_state)
    end

    def load_records
      @records = execute
      puts "[CACHE] #{@records}"
      @loaded = true
    end

    def build_select_clause
      select = @query_state[:select_attributes].empty? ?  "*" : @query_state[:select_attributes].join(', ') 
      "SELECT #{select}"
    end

    def build_from_clause
      "FROM #{@klass.table_name}"
    end
    
    def build_where_clause
      return "" if @query_state[:conditions].empty?

      conditions = @query_state[:conditions].flat_map do |h|
                     h.map { |k,v| build_sql_placeholder(k, v) }
                   end.join(' AND ')

      "WHERE #{conditions}"
    end

    def build_join_clause
      return "" if @query_state[:join_clause].empty?

      table_name = @query_state[:join_clause].to_s
      model_name = table_name.chomp("s").capitalize
      @associate_model = Object.const_get(model_name)

      foreign_key = "#{@klass.name.downcase}_id"
      "INNER JOIN #{table_name} ON #{@klass.table_name}.id = #{table_name}.#{foreign_key}"
    end

    def build_order_clause
      return "" if @query_state[:order_clauses].empty?

      value = @query_state[:order_clauses].map do |h|
                h.is_a?(Symbol) ? h.to_s : h.map { |k,v| "#{k.to_s} #{v.to_s.upcase}" }.join(', ')
              end.join
      "ORDER BY #{value}"
    end

    def build_limit_clause
      return "" unless @query_state[:limit_value]

      "LIMIT #{@query_state[:limit_value]}"
    end

    def build_offset_clause
      return "" unless @query_state[:limit_value] && @query_state[:offset_value]

      "OFFSET #{@query_state[:offset_value]}"
    end

    def normalize_bind_values(values)
      if values.first.is_a?(Range)
        [values.first.begin, values.first.end]
      else
        values
      end
    end

    def build_sql_placeholder(key, value)
      value.is_a?(Range) ? "#{key} BETWEEN ? and ?" : "#{key} = ?"
    end

    def convert_to_instances(raw_records)
      return handle_join_result(raw_records) if has_join?

      # 集約関数ならreturn
      return raw_records.flatten.first if aggregation_query?(raw_records)

      handle_normal_result(raw_records)
    end

    def has_join?
      !@query_state[:join_clause].empty?
    end

    def handle_join_result(raw_records)
      records = raw_records.map(&:dup).flatten

      klass_columns     = @klass.column_names
      associate_columns = @associate_model.column_names

      klass_values     = records[0...klass_columns.size]
      associate_values = records[klass_columns.size...klass_columns.size + associate_columns.size]

      klass_instance     = @klass.new(Hash[klass_columns.zip(klass_values)])
      associate_instance = @associate_model.new(Hash[associate_columns.zip(associate_values)])

      {
        @klass.name.downcase.to_sym => klass_instance,
        @associate_model.name.downcase.to_sym => associate_instance
      }
    end

    def aggregation_query?(raw_records)
      raw_records.flatten.size == 1 && aggregation_result?(raw_records.flatten)
    end

    def handle_normal_result(raw_records)
      raw_records.map { |raw_record|
        build_instance_from_record(raw_record)
      }
    end

    def aggregation_result?(res)
      @query_state[:select_attributes].any? { |attr|
        attr.to_s.match?(/\A\w+\(.+\)\z/) # COUNT(*) などにマッチする
      } && (res.first.is_a?(Numeric) || res.first.is_a?(Float))
    end

    def build_instance_from_record(raw_record)
      attributes = Hash[klass.column_names.zip(raw_record)]
      klass.new(attributes)
    end

    def validate_query_state!
      if @query_state[:offset_value] && !@query_state[:limit_value]
        raise InvalidQueryError, "OFFSET requires LIMIT"
      end
    end
  end
end

module ORM
  class QueryBuilder
    attr_reader :klass, :query_state

    def initialize(klass, query_state = {})
      @klass = klass
      @query_state = {
        conditions: [],
        bind_values: [],
        select_attributes: [],
        order_clauses: [],
        limit_value: nil
      }.merge(query_state)
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

    def to_sql
      [
        build_select_clause,
        build_from_clause,
        build_where_clause,
        build_order_clause,
        # build_limit_clause,
        # build_offset_clause,
      ].reject(&:empty?).join(' ')
    end

    def execute
      raw_records = klass.connection.execute(to_sql, @query_state[:bind_values])
      convert_to_instances(raw_records)
    end

    private


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

    def build_order_clause
      return "" if @query_state[:order_clauses].empty?

      value = @query_state[:order_clauses].map do |h|
                h.is_a?(Symbol) ? h.to_s : h.map { |k,v| "#{k.to_s} #{v.to_s.upcase}" }.join(', ')
              end.join
      "ORDER BY #{value}"
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
      return raw_records.flatten.first if raw_records.flatten.size == 1 && aggregation_result?(raw_records.flatten)

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
  end
end
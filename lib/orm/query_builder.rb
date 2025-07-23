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

    def to_sql
      return select_sql if @query_state[:conditions].empty?

      "#{select_sql} WHERE #{build_where_clauses}"
    end

    def execute
      raw_records = klass.connection.execute(to_sql, @query_state[:bind_values])
      convert_to_instances(raw_records)
    end

    private

    def select_sql
      attr = @query_state[:select_attributes].empty? ?  "*" : @query_state[:select_attributes].join(', ') 
      "SELECT #{attr} FROM #{@klass.table_name}"
    end

    def build_where_clauses
      @query_state[:conditions].flat_map do |h|
        h.map { |k,v| build_sql_placeholder(k, v) }
      end.join(' AND ')
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
      raw_records.map { |raw_record|
        build_instance_from_record(raw_record)
      }
    end

    def build_instance_from_record(raw_record)
      attributes = Hash[klass.column_names.zip(raw_record)]
      klass.new(attributes)
    end
  end
end
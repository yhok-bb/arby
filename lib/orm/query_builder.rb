module ORM
  class QueryBuilder
    attr_reader :klass, :conditions, :bind_values

    def initialize(klass, conditions = [], bind_values = [])
      @klass = klass
      @conditions = conditions
      @bind_values = bind_values
    end

    def where(attributes = {})
      conditions = @conditions + [attributes]
      bind_values = normalize_bind_values(attributes.values)
      self.class.new(@klass, conditions, bind_values)
    end

    def to_sql
      return select_sql if @conditions.empty?

      "#{select_sql} WHERE #{build_where_clauses}"
    end

    def execute
      raw_records = klass.connection.execute(to_sql, @bind_values)
      convert_to_instances(raw_records)
    end

    private

    def select_sql
      "SELECT * FROM #{@klass.table_name}"
    end

    def build_where_clauses
      @conditions.flat_map do |h|
        h.map { |k,v| build_sql_placeholder(k, v) }
      end.join(' AND ')
    end

    def normalize_bind_values(values)
      if values.first.is_a?(Range)
        @bind_values + [values.first.begin, values.first.end]
      else
        @bind_values + values
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
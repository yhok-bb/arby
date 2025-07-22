module ORM
  class QueryBuilder
    attr_reader :klass, :conditions

    def initialize(klass, conditions = [])
      @klass = klass
      @conditions = conditions
    end

    def where(attributes = {})
      conditions = @conditions + [attributes]
      self.class.new(@klass, conditions)
    end

    def to_sql
      return "SELECT * FROM #{@klass.table_name}" if @conditions.empty?

      where_query = @conditions.map do |h|
        h.map do |k,v|
          if v.is_a?(Range)
            "#{k} BETWEEN #{v.begin} and #{v.end}"
          else
            "#{k} = '#{v}'" # TODO プレースホルダの使用
          end
        end
      end.flatten.join(' AND ')

      "SELECT * FROM #{@klass.table_name} WHERE #{where_query}"
    end

    def execute
      record = klass.connection.execute(to_sql)
      attributes = record.map { |r| Hash[klass.column_names.zip(r)] }
      attributes.map { |attr| klass.new(attr) }
    end
  end
end
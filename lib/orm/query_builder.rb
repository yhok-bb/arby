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
        h.map { |k,v| "#{k} = '#{v}'" } # TODO プレースホルダの使用
      end.flatten.join(' AND ')

      "SELECT * FROM #{@klass.table_name} WHERE #{where_query}"
    end
  end
end
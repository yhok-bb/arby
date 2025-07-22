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
  end
end
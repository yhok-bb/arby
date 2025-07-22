module ORM
  class QueryBuilder
    attr_reader :klass, :conditions

    def initialize(klass, conditions = [])
      @klass = klass
      @conditions = conditions
    end
  end
end
require_relative '../../lib/orm/base'
require_relative '../../lib/orm/query_builder'
require_relative '../../app/models/user'

RSpec.describe ORM::QueryBuilder do
  before(:each) do
    ORM::Base.establish_connection(database: ":memory:")
    User.create_table
  end

  describe "#initialize" do
    it "creates a QueryBuilder instance with model class" do
      builder = ORM::QueryBuilder.new(User)
      expect(builder).to be_instance_of(ORM::QueryBuilder)
    end
  end
end
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

  describe "#where" do
    it "where user" do
      User.create(name: "Alice", email: "alice@example.com")
      User.create(name: "Tom", email: "tom@example.com")
      builder = ORM::QueryBuilder.new(User)
      result = builder.where(name: "Alice").where(email: "alice@example.com")

      expect(result).to be_instance_of(ORM::QueryBuilder)
      expect(builder).not_to equal(result)
      expect(result.conditions).to eq([{:name=>"Alice"}, {:email=>"alice@example.com"}])
    end
  end
end
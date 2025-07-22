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

  describe "#to_sql" do
    it "constructing a query string when conditions apply" do
      User.create(name: "Alice", email: "alice@example.com")
      User.create(name: "Tom", email: "tom@example.com")
      builder = ORM::QueryBuilder.new(User)
      result = builder.where(name: "Alice").where(email: "alice@example.com")

      expect(result.to_sql).to eq("SELECT * FROM users WHERE name = 'Alice' AND email = 'alice@example.com'")
    end

    it "constructing a query string when conditions none" do
      User.create(name: "Alice", email: "alice@example.com")
      User.create(name: "Tom", email: "tom@example.com")
      builder = ORM::QueryBuilder.new(User)
      expect(builder.to_sql).to eq("SELECT * FROM users")
    end
  end

  describe "#execute" do
    it "returns single records when multiple matches exist" do
      User.create(name: "Alice", email: "alice@example.com")
      User.create(name: "Tom", email: "tom@example.com")
      builder = ORM::QueryBuilder.new(User)
      results = builder.where(name: "Alice").execute

      expect(results).to be_an(Array)
      expect(results.size).to eq(1)
      expect(results.first).to be_instance_of(User)
      expect(results.first.name).to eq("Alice")
      expect(results.first.email).to eq("alice@example.com")
    end

    it "returns multiple records when multiple matches exist" do
      User.create(name: "Alice", email: "alice1@example.com")
      User.create(name: "Alice", email: "alice2@example.com")

      results = ORM::QueryBuilder.new(User).where(name: "Alice").execute
      expect(results.size).to eq(2)
    end
  end
end
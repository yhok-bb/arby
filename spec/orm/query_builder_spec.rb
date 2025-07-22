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

    it "when range specification" do
      User.create(name: "Alice", age: 15)
      User.create(name: "Taro", age: 25)
      User.create(name: "Yoshida", age: 35)

      users = User.where(age: 20..30)
      expect(users.to_sql).to eq("SELECT * FROM users WHERE age BETWEEN ? and ?")

      results = users.execute
      expect(results.size).to eq(1)
      expect(results.first.name).to eq("Taro")
    end
  end

  describe "#to_sql" do
    it "constructing a query string when conditions apply" do
      User.create(name: "Alice", email: "alice@example.com")
      User.create(name: "Tom", email: "tom@example.com")
      builder = ORM::QueryBuilder.new(User)
      result = builder.where(name: "Alice").where(email: "alice@example.com")

      expect(result.to_sql).to eq("SELECT * FROM users WHERE name = ? AND email = ?")
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

    it "when sql injection query" do
      User.create(name: "Alice", email: "alice@example.com")
      User.create(name: "Tom", email: "tom@example.com")
      builder = ORM::QueryBuilder.new(User)
      results = builder.where(name: "' OR 1=1 --").where(age: 15).execute

      expect(results).to be_an(Array)
      expect(results.size).to eq(0)
    end

    it "returns multiple records when multiple matches exist" do
      User.create(name: "Alice", email: "alice1@example.com")
      User.create(name: "Alice", email: "alice2@example.com")

      results = ORM::QueryBuilder.new(User).where(name: "Alice").execute
      expect(results.size).to eq(2)
    end

    it "returns database not connection error" do
      ORM::Base.establish_connection(database: "/tmp/sqlite3")

      expect {
        ORM::QueryBuilder.new(User).execute
    }.to raise_error(SQLite3::Exception)
    end
  end
end
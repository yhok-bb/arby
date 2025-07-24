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
      expect(result.query_state[:conditions]).to eq([{:name=>"Alice"}, {:email=>"alice@example.com"}])
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

  describe "#select" do
    it "when single select" do
      User.create(name: "Alice", email: "alice@example.com", age: 15)
      User.create(name: "Tom", email: "tom@example.com", age: 25)

      builder = ORM::QueryBuilder.new(User)
      result = builder.select(:name)

      expect(result.to_sql).to eq("SELECT name FROM users")
    end
    it "when multiple select" do
      User.create(name: "Alice", email: "alice@example.com", age: 15)
      User.create(name: "Tom", email: "tom@example.com", age: 25)

      builder = ORM::QueryBuilder.new(User)
      result = builder.select(:name, :email)

      expect(result.to_sql).to eq("SELECT name, email FROM users")
    end
    it "when select and method chain" do
      User.create(name: "Alice", email: "alice@example.com", age: 15)
      User.create(name: "Tom", email: "tom@example.com", age: 25)

      builder = ORM::QueryBuilder.new(User)
      result = builder.select(:name, :email).where(name: "Alice")

      expect(result.to_sql).to eq("SELECT name, email FROM users WHERE name = ?")
    end

    it "returns count of records" do
      User.create(name: "Alice")
      User.create(name: "Bob")

      builder = ORM::QueryBuilder.new(User)
      res = builder.select("COUNT(*)").execute
      expect(res).to eq(2)
    end

    it "returns name count of records" do
      User.create(name: "Alice")
      User.create(name: "Bob")
      User.create(age: 15)

      builder = ORM::QueryBuilder.new(User)
      res = builder.select("COUNT(name)").execute
      expect(res).to eq(2)
    end

    it "returns sum age of records" do
      User.create(name: "Alice")
      User.create(age: 30)
      User.create(age: 15)

      builder = ORM::QueryBuilder.new(User)
      res = builder.select("SUM(age)").execute
      expect(res).to eq(45)
    end

    it "returns avg age of records" do
      User.create(name: 25)
      User.create(age: 30)
      User.create(age: 15)

      builder = ORM::QueryBuilder.new(User)
      res = builder.select("AVG(age)").execute
      expect(res).to eq(22.5)
    end
  end

  describe "#order" do
    it "returns age asc of records" do
      User.create(age: 25)
      User.create(age: 15)
      User.create(age: 20)

      builder = ORM::QueryBuilder.new(User)
      res = builder.order(:age).execute

      expect(res[0].age).to eq(15)
      expect(res[1].age).to eq(20)
      expect(res[2].age).to eq(25)
    end

    it "returns age desc of records" do
      User.create(age: 15)
      User.create(age: 20)
      User.create(age: 25)

      builder = ORM::QueryBuilder.new(User)
      res = builder.order(age: :desc).execute
      
      expect(res[0].age).to eq(25)
      expect(res[1].age).to eq(20)
      expect(res[2].age).to eq(15)
    end

    it "returns age desc and name desc of records" do
      User.create(name: "Alice", age: 15)
      User.create(name: "Blice", age: 20)
      User.create(name: "Clice", age: 25)
      User.create(name: "Dlice", age: 15)
      User.create(name: "Elice", age: 20)
      User.create(name: "Flice", age: 25)

      builder = ORM::QueryBuilder.new(User)
      res = builder.order(age: :desc, name: :desc).execute
      
      expect(res[0].name).to eq("Flice")
      expect(res[1].name).to eq("Clice")
      expect(res[2].name).to eq("Elice")
      expect(res[3].name).to eq("Blice")
      expect(res[4].name).to eq("Dlice")
      expect(res[5].name).to eq("Alice")
    end
  end

  describe "#limit, #offset" do
    it "returns limit users of records" do
      User.create(name: "Alice", age: 15)
      User.create(name: "Blice", age: 20)
      User.create(name: "Clice", age: 25)

      builder = ORM::QueryBuilder.new(User)
      res = builder.limit(2).execute

      expect(res.size).to eq(2)
    end

    it "returns offset users of records" do
      User.create(name: "Alice", age: 15)
      User.create(name: "Blice", age: 20)
      User.create(name: "Clice", age: 25)
      User.create(name: "Dlice", age: 15)
      User.create(name: "Elice", age: 20)
      User.create(name: "Flice", age: 25)

      builder = ORM::QueryBuilder.new(User)
      res = builder.limit(2).offset(2).execute

      expect(res.size).to eq(2)
      expect(res.first.name).to eq("Clice")
      expect(res.last.name).to eq("Dlice")
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
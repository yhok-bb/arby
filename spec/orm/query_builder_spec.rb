require_relative '../../lib/orm/base'
require_relative '../../lib/orm/query_builder'
require_relative '../../app/models/user'
require_relative '../../app/models/post'

RSpec.describe ORM::QueryBuilder do
  before(:each) do
    ORM::Base.establish_connection(database: ":memory:")
    User.create_table
    Post.create_table
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

      users = User.where(age: 20..30) # SQLは実行しない
      expect(users.to_sql).to eq("SELECT * FROM users WHERE age BETWEEN ? and ?")

      # キャッシュ前
      expect(users.instance_variable_get(:@loaded)).to eq(false)
      expect(users.instance_variable_get(:@records)).to eq([])

      user = users.first
      expect(user.name).to eq("Taro") # 遅延評価

      # キャッシュ後
      expect(users.instance_variable_get(:@loaded)).to eq(true)
      expect(users.instance_variable_get(:@records).size).to eq(1)
      expect(users.instance_variable_get(:@records).first.name).to eq("Taro")
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

   describe "#join" do
    it "joins with posts table" do
      builder = ORM::QueryBuilder.new(User)
      res = builder.join(:posts).to_sql
      expect(res).to eq("SELECT * FROM users INNER JOIN posts ON users.id = posts.user_id")

      user = User.create(name: "Alice", age: 15)
      Post.create(user_id: user.id, title: "Hello", detail: "nice to meet you")
      res = User.join(:posts).execute

      expect(res[:user].id).to eq(1)
      expect(res[:user].age).to eq(15)
      expect(res[:user].email).to eq(nil)
      expect(res[:user].name).to eq("Alice")
      expect(res[:post].id).to eq(1)
      expect(res[:post].user_id).to eq(1)
      expect(res[:post].title).to eq("Hello")
      expect(res[:post].detail).to eq("nice to meet you")
    end

    it "joins with where condition" do
      user1 = User.create(name: "Alice", age: 25)
      user2 = User.create(name: "Bob", age: 30)
      
      Post.create(user_id: user1.id, title: "Alice's Post", detail: "First post")
      Post.create(user_id: user2.id, title: "Bob's Post", detail: "Second post")

      res = User.where(name: "Alice").join(:posts).execute

      expect(res[:user].name).to eq("Alice")
      expect(res[:post].title).to eq("Alice's Post")
    end

    it "joins with order and limit" do
      user1 = User.create(name: "Alice", age: 25)
      user2 = User.create(name: "Bob", age: 30)
      user3 = User.create(name: "Charlie", age: 35)
      
      Post.create(user_id: user1.id, title: "Post A", detail: "Detail A")
      Post.create(user_id: user2.id, title: "Post B", detail: "Detail B")
      Post.create(user_id: user3.id, title: "Post C", detail: "Detail C")

      sql = User.join(:posts).order(:age).limit(2).to_sql
      expect(sql).to eq("SELECT * FROM users INNER JOIN posts ON users.id = posts.user_id ORDER BY age LIMIT 2")
    end

    it "returns correct instance types" do
      user = User.create(name: "Alice", age: 25)
      Post.create(user_id: user.id, title: "Test Post", detail: "Test Detail")

      res = User.join(:posts).execute

      expect(res[:user]).to be_instance_of(User)
      expect(res[:post]).to be_instance_of(Post)
      expect(res[:user]).to respond_to(:name)
      expect(res[:post]).to respond_to(:title)
    end

    it "handles join with select" do
      user = User.create(name: "Alice", age: 25, email: "alice@example.com")
      Post.create(user_id: user.id, title: "Selected Post", detail: "Selected Detail")

      sql = User.select(:name, :age).join(:posts).to_sql
      expect(sql).to eq("SELECT name, age FROM users INNER JOIN posts ON users.id = posts.user_id")
    end

    it "handles multiple users with posts correctly" do
      user1 = User.create(name: "Alice", age: 25)
      user2 = User.create(name: "Bob", age: 30)
      
      Post.create(user_id: user1.id, title: "Alice Post 1", detail: "Detail 1")
      Post.create(user_id: user1.id, title: "Alice Post 2", detail: "Detail 2")
      Post.create(user_id: user2.id, title: "Bob Post 1", detail: "Detail 3")

      # 最初のマッチした組み合わせを返す
      res = User.join(:posts).execute
      
      expect(res[:user]).to be_instance_of(User)
      expect(res[:post]).to be_instance_of(Post)
      expect(res[:user].id).to eq(1)  # Alice
      expect(res[:post].user_id).to eq(1)
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
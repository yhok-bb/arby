require 'pry'
require_relative '../../lib/orm/base'
require_relative '../../app/models/user'
require_relative '../../app/models/post'
require_relative '../../app/models/comment'

RSpec.describe ORM::Base do
  describe "definition ORM::Base" do
    it { expect(defined?(ORM::Base)).to eq("constant") }
  end

  describe ".establish_connection" do
    it "establishes database connection" do
      config = { database: ":memory:"}

      ORM::Base.establish_connection(config)

      expect(ORM::Base.connection).to be_a(SQLite3::Database)
    end
  end
  
  describe ".table_name" do
    it "returns correct table name for Users" do
      expect(User.table_name).to eq("users")
    end

    it "returns correct table name for Post" do
      expect(Post.table_name).to eq("posts")
    end

    it "returns correct table name for Comment" do
      expect(Comment.table_name).to eq("comments")
    end
  end

  describe ".create_table" do
    it "creates table in database" do
      ORM::Base.establish_connection(database: ":memory:")
      User.create_table

      result = ORM::Base.connection.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='users'"
      )
      expect(result).not_to be_empty
    end
  end

  describe ".column_names" do
    it "select column names" do
      ORM::Base.establish_connection(database: ":memory:")
      User.create_table
      expect(User.column_names).to eq(["id", "name", "email"])
    end
  end

  describe ".generate_attributes_accessors" do
    it "generate attr_accessor" do
      ORM::Base.establish_connection(database: ":memory:")
      User.create_table
      expect(User.instance_methods).to include(:name, :name=, :email, :email=)
    end

    it "allows setting and getting attribute values" do
      ORM::Base.establish_connection(database: ":memory:")
      User.create_table
      user = User.new
      user.name = "Taro"
      user.email = "taro@example.com"

      expect(user.name).to eq("Taro")
      expect(user.email).to eq("taro@example.com")
    end
  end

  describe "Class.new with arributes" do
    it "creates user instance with attribute hash" do
      ORM::Base.establish_connection(database: ":memory:")
      User.create_table

      user = User.new(name: "Alice", email: "alice@example.com")

      expect(user.name).to eq("Alice")
      expect(user.email).to eq("alice@example.com")
    end

    it "creates post instance with attribute hash" do
      ORM::Base.establish_connection(database: ":memory:")
      Post.create_table

      post = Post.new(title: "greet", detail: "I'm Alice, working at Google. Nice to meet you.")

      expect(post.title).to eq("greet")
      expect(post.detail).to eq("I'm Alice, working at Google. Nice to meet you.")
    end
  end

  describe "save instance" do
    it "save user instance" do
      ORM::Base.establish_connection(database: ":memory:")
      User.create_table

      user = User.new(name: "Taro", email: "taro@example.com")
      res = user.save

      expect(res).to be_truthy

      # DBの中身を直接確認
      result = ORM::Base.connection.execute(
                 "SELECT id, name, email FROM users WHERE id = ?", [user.id]
               )
      row = result[0]
      expect(row[0]).to eq(1)
      expect(row[1]).to eq("Taro")
      expect(row[2]).to eq("taro@example.com")
    end
  end

  describe "create instance" do
    it "create user instance" do
      ORM::Base.establish_connection(database: ":memory:")
      User.create_table

      user = User.create(name: "Yoshida", email: "yoshida@example.com")

      expect(user).to be_a(User)
      expect(user.id).not_to be_nil
      # DBの中身を直接確認
      result = ORM::Base.connection.execute(
                 "SELECT id, name, email FROM users WHERE id = ?", [user.id]
               )
      row = result[0]
      expect(row[0]).to eq(1)
      expect(row[1]).to eq("Yoshida")
      expect(row[2]).to eq("yoshida@example.com")
    end
  end
end
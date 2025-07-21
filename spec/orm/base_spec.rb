require 'pry'

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
      user_class = Class.new(ORM::Base)
      stub_const("User", user_class)
      expect(User.table_name).to eq("users")
    end

    it "returns correct table name for Post" do
      post_class = Class.new(ORM::Base)
      stub_const("Post", post_class)
      expect(Post.table_name).to eq("posts")
    end

    it "returns correct table name for Comment" do
      comment_class = Class.new(ORM::Base)
      stub_const("Comment", comment_class)
      expect(Comment.table_name).to eq("comments")
    end
  end

  describe ".create_table" do
    it "creates table in database" do
      ORM::Base.establish_connection(database: ":memory:")
      user_class = Class.new(ORM::Base)
      stub_const("User", user_class)

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
      user_class = Class.new(ORM::Base)
      stub_const("User", user_class)

      User.create_table
      expect(User.column_names).to eq(["id", "name", "email"])
    end
  end

  describe ".generate_attributes_accessors" do
    it "generate attr_accessor" do
      ORM::Base.establish_connection(database: ":memory:")
      user_class = Class.new(ORM::Base)
      stub_const("User", user_class)

      User.create_table
      expect(User.instance_methods).to include(:name, :name=, :email, :email=)
    end

    it "allows setting and getting attribute values" do
      ORM::Base.establish_connection(database: ":memory:")
      user_class = Class.new(ORM::Base)
      stub_const("User", user_class)

      User.create_table
      user = User.new
      user.name = "Taro"
      user.email = "taro@example.com"

      expect(user.name).to eq("Taro")
      expect(user.email).to eq("taro@example.com")
    end
  end
end
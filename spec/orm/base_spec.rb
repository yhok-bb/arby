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
end
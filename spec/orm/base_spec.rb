require 'pry'
require_relative '../../lib/orm/base'
require_relative '../../app/models/user'
require_relative '../../app/models/post'
require_relative '../../app/models/comment'
require_relative '../../app/models/profile'
require_relative '../../lib/orm/query_builder'

RSpec.describe ORM::Base do
  before(:each) do
    ORM::Base.establish_connection(database: ":memory:")
    User.create_table
    Post.create_table
    Profile.create_table
  end
  
  describe "definition ORM::Base" do
    it { expect(defined?(ORM::Base)).to eq("constant") }
  end

  describe ".establish_connection" do
    it "establishes database connection" do
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
      result = ORM::Base.connection.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='users'"
      )
      expect(result).not_to be_empty
    end
  end

  describe ".column_names" do
    it "select column names" do
      expect(User.column_names).to eq(["id", "name", "email", "age", "active"])
    end
  end

  describe ".generate_attributes_accessors" do
    it "generate attr_accessor" do
      expect(User.instance_methods).to include(:name, :name=, :email, :email=)
    end

    it "allows setting and getting attribute values" do
      user = User.new
      user.name = "Taro"
      user.email = "taro@example.com"

      expect(user.name).to eq("Taro")
      expect(user.email).to eq("taro@example.com")
    end
  end

  describe "Class.new with arributes" do
    it "creates user instance with attribute hash" do
      user = User.new(name: "Alice", email: "alice@example.com")

      expect(user.name).to eq("Alice")
      expect(user.email).to eq("alice@example.com")
    end

    it "creates post instance with attribute hash" do
      post = Post.new(title: "greet", detail: "I'm Alice, working at Google. Nice to meet you.")

      expect(post.title).to eq("greet")
      expect(post.detail).to eq("I'm Alice, working at Google. Nice to meet you.")
    end
  end

  describe "save instance" do
    it "save user instance" do
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

    it "updates existing record when save is called" do
      user = User.create(name: "Alice", email: "alice@example.com")

      user.name = "Bob"
      user.save

      updated_user = User.find(user.id)
      expect(updated_user.name).to eq("Bob")
      expect(updated_user.email).to eq("alice@example.com")
    end
  end

  describe "create instance" do
    it "create user instance" do
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

  describe "update instance" do
    it "updates existing record when save is called" do
      user = User.create(name: "Alice", email: "alice@example.com")
      user.update(name: "Bob")

      updated_user = User.find(user.id)
      expect(updated_user.name).to eq("Bob")
      expect(updated_user.email).to eq("alice@example.com")
    end
  end

  describe "delete instance" do
    it "deletes record from database" do
      user = User.create(name: "Alice")

      user.destroy
      expect(user.id).to be_nil
    end

    it "returns nil when record not found" do
      user = User.find(999)
      expect(user).to be_nil
    end
  end

  describe "find instance" do
    it "finds user by id" do
      user = User.create(name: "Yoshida", email: "yoshida@example.com")

      find_user = User.find(user.id)
      expect(find_user.name).to eq("Yoshida")
      expect(find_user.email).to eq("yoshida@example.com")
    end

    it "returns nil when record not found" do
      user = User.find(999)
      expect(user).to be_nil
    end

    it "returns ArgumentError when record nil" do
      expect { User.find(nil) }.to raise_error(ArgumentError, "ID cannot be nil")
    end
  end

  describe ".where" do
    it "returns QueryBuilder instance" do
      result = User.where(name: "Alice")
      expect(result).to be_instance_of(ORM::QueryBuilder)
    end
  end

  # association
  
  describe ".belongs_to" do
    it ".belongs_to" do
      expect(Post.belongs_to(:user)).to eq(:user)
    end

    it "returns user when user is associated with the post" do
      user = User.create(name: "test", email: "test@example.com")
      post = Post.new(user_id: user.id)
      expect(post.user.id).to eq(user.id)
      expect(post.user.name).to eq(user.name)
      expect(post.user.email).to eq(user.email)
    end

    it "returns user when overriding the user associated with the post" do
      user = User.create(name: "test", email: "test@example.com")
      post = Post.new(user_id: user.id)
      expect(post.user.id).to eq(user.id)

      user2 = User.create(name: "test2", email: "test2@example.com")
      post.user_id = user2.id
      expect(post.user.id).to eq(user2.id)
      expect(post.user.name).to eq(user2.name)
      expect(post.user.email).to eq(user2.email)
    end

    it "returns nil when no user is associated with the post" do
      post = Post.new
      expect(post.respond_to?(:user)).to eq(true)
      expect(post.user).to eq(nil)
    end

    it "returns record not found when no user is found associated with the post" do
      post = Post.new(user_id: 1)
      expect {
        post.user
      }.to raise_error(ORM::Base::RecordNotFound, "user is not found")
    end
  end

  describe ".has_one" do
    it ".has_one" do
      expect(User.has_one(:profile)).to eq(:profile)
    end

    it "returns profile when profile is associated with the user" do
      user = User.create(name: "test", email: "test@example.com")
      profile = Profile.create(user_id: user.id, nickname: "yhok", bio: "I'm yhok, Nice to meet you")

      expect(user.profile.user_id).to eq(profile.user_id)
      expect(user.profile.nickname).to eq(profile.nickname)
      expect(user.profile.bio).to eq(profile.bio)
    end

    # TODO: Identity Map パターンが必要
    # 異なるオブジェクトインスタンスが返されるため、外部でオブジェクトを更新しても
    # アソシエーション経由では古いキャッシュが返される問題
    xit "returns update profile when profile is associated with the user" do
      user = User.create(name: "test", email: "test@example.com")
      profile = Profile.create(user_id: user.id, nickname: "yhok", bio: "I'm yhok, Nice to meet you")
      expect(user.profile.user_id).to eq(profile.user_id)
      expect(user.profile.nickname).to eq(profile.nickname)
      expect(user.profile.bio).to eq(profile.bio)

      update_bio = "I'm yhok2, update profile recently"
      profile.bio = update_bio
      profile.save

      expect(user.profile.bio).to eq(update_bio)
    end

    it "returns profile when overriding the profile is associated with the user" do
      user = User.create(name: "test", email: "test@example.com")
      profile = Profile.create(user_id: user.id, nickname: "yhok", bio: "I'm yhok, Nice to meet you")
      expect(user.profile.user_id).to eq(profile.user_id)

      profile2 = Profile.create(user_id: user.id, nickname: "yhok2", bio: "I'm yhok2, update profile recently")
      user.profile = profile2

      expect(user.profile.user_id).to eq(profile2.user_id)
      expect(user.profile.nickname).to eq(profile2.nickname)
      expect(user.profile.bio).to eq(profile2.bio)
    end

    it "returns nil when user has no id" do
      user = User.new(name: "test")
      expect(user.id).to be_nil
      expect(user.profile).to eq(nil)
    end

    it "returns nil when no profile is associated with the user" do
      user = User.new
      expect(user.respond_to?(:profile)).to eq(true)
      expect(user.profile).to eq(nil)
    end
  end

  describe ".has_many" do
    it ".has_many" do
      expect(User.has_many(:posts)).to eq(:posts)
    end

    it "returns multiple posts when a user has multiple posts" do
      user = User.create(name: "test", email: "test@example.com")
      expect(user.posts.to_a).to eq([])

      post1 = Post.create(user_id: user.id, title: "posts1")
      post2 = Post.create(user_id: user.id, title: "posts2")
      post3 = Post.create(user_id: user.id, title: "posts3")

      posts = user.posts.to_a

      expect(posts.count).to eq(3)
      expect(posts[0].title).to eq(post1.title)
      expect(posts[1].title).to eq(post2.title)
      expect(posts[2].title).to eq(post3.title)
    end

    it "returns empty array when user has no id" do
      user = User.new(name: "test")
      expect(user.id).to be_nil
      expect(user.posts).to eq([])
    end
  end

  describe ".scope" do
    it ".scope" do
      expect(User.respond_to?(:active)).to eq(true)
      expect(User.active).to be_a(ORM::QueryBuilder)
    end

    it "returns active user" do
      User.create(name: "Alice", active: 1, age: 10)
      User.create(name: "Blice", active: 0, age: 12)
      User.create(name: "Clice", active: 1, age: 15)
      User.create(name: "Dlice", active: 0, age: 20)
      User.create(name: "Elice", active: 1, age: 23)
      User.create(name: "Flice", active: 1, age: 25)

      expect(User.active.to_a.size).to eq(4)
      expect(User.active.first.name).to eq("Alice")
      expect(User.active.last.name).to eq("Flice")
    end

    it "returns just_adult and active user" do
      User.create(name: "Alice", active: 1, age: 10)
      User.create(name: "Blice", active: 0, age: 12)
      User.create(name: "Clice", active: 1, age: 15)
      User.create(name: "Dlice", active: 0, age: 20)
      User.create(name: "Elice", active: 1, age: 20)
      User.create(name: "Flice", active: 1, age: 25)

      expect(User.just_adult.active.to_a.size).to eq(1)
      expect(User.just_adult.active.first.name).to eq("Elice")
    end
  end
end

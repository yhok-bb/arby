require_relative '../../../lib/orm/base'
require_relative '../../../lib/orm/query_builder'
require_relative '../../../app/models/user'
require_relative '../../../app/models/post'

RSpec.describe Post do
  before(:each) do
    ORM::Base.establish_connection(database: ":memory:")
    User.create_table
    Post.create_table
  end

  describe "post" do
    it ".columns_definition" do
      expect(Post.columns_definition).to eq({:user_id=>"INTEGER", :title=>"TEXT", :detail=>"TEXT"})
    end
  end
end
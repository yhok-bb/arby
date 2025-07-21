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
end
require 'pry'
require 'sqlite3'

module ORM
  class Base
    @@connection = nil

    def self.establish_connection(config)
      @@connection = SQLite3::Database.new(config[:database])
    end

    def self.connection
      @@connection
    end
  end
end
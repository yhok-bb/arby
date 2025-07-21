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
    
    def self.table_name
      klass = self.to_s.downcase
      klass + "s"
    end
  end
end
require 'pry'
require 'sqlite3'

module ORM
  class Base
    @@connection = nil

    def initialize(attributes = {})
      attributes.each do |key, value|
        if respond_to?("#{key}=")
          send("#{key}=", value)
        end
      end
    end

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

    def self.create_table
      columns_sql = columns_definition.map { |col, type| "#{col} #{type}" }.join(", ")
      sql = "CREATE TABLE #{self.table_name} (
        id INTEGER PRIMARY KEY autoincrement,
        #{columns_sql}
      )"
      connection.execute(sql)

      generate_attributes_accessors
    end

    def self.column_names
      sql = "PRAGMA table_info(#{self.table_name});"
      table_info = connection.execute(sql)
      table_info.map { |ti| ti[1] }
    end

    def self.columns_definition
      {}
    end

    private

    def self.generate_attributes_accessors
      column_names.each do |cn|
        attr_accessor cn.to_sym unless cn == "id"
      end
    end
  end
end
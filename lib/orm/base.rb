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

    # class methods

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

    def self.create(attributes = {})
      instance = new(attributes)
      if instance.save
        instance
      else
        nil
      end
    end

    def self.find(id)
      raise "please specify the id as an argument" unless id

      sql = "SELECT *
             FROM #{table_name}
             WHERE #{table_name}.id = ?"
      record = self.connection.execute(sql, id)
      record = record[0]
      
      return nil if record.nil?
      
      attributes = Hash[column_names.zip(record)]
      new(attributes)
    end

    # instance methods

    def save
      begin
        columns = self.class.columns_definition.keys
        values = columns.map { |col| send(col) }

        columns_sql = columns.join(', ')
        placeholders = (['?'] * columns.size).join(', ')
        sql = "INSERT INTO #{self.class.table_name} (#{columns_sql})
              VALUES(#{placeholders});"
        self.class.connection.execute(sql, values)
        self.id = self.class.connection.last_insert_row_id
        true # 成功
      rescue => e
        puts "--------error: #{e}-----------"
        false # 失敗
      end
    end

    private

    def self.generate_attributes_accessors
      column_names.each do |cn|
        attr_accessor cn.to_sym
      end
    end
  end
end
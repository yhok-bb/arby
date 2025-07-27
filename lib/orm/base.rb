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
      @associations ||= {}
    end

    class RecordNotFound < StandardError; end

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
      raise ArgumentError, "ID cannot be nil" unless id

      sql = "SELECT *
             FROM #{table_name}
             WHERE #{table_name}.id = ?"
      record = self.connection.execute(sql, id)
      record = record[0]
      
      return nil if record.nil?

      attributes = Hash[column_names.zip(record)]
      new(attributes)
    end

    def self.all
      QueryBuilder.new(self).all
    end

    def self.first
      QueryBuilder.new(self).first
    end

    def self.last
      QueryBuilder.new(self).last
    end

    def self.count
      QueryBuilder.new(self).count
    end

    def self.where(conditions)
      QueryBuilder.new(self).where(conditions)
    end

    def self.join(association)
      QueryBuilder.new(self).join(association)
    end

    def self.select(*attributes)
      QueryBuilder.new(self).select(*attributes)
    end

    def self.order(*attributes)
      QueryBuilder.new(self).order(*attributes)
    end

    def self.limit(num)
      QueryBuilder.new(self).limit(num)
    end

    def self.offset(num)
      QueryBuilder.new(self).offset(num)
    end

    # association methods
    
    def self.belongs_to(association_name, options = {})
      foreign_key = options[:foreign_key] || "#{association_name}_id"

      attr_reader foreign_key.to_sym
      
      define_method("#{foreign_key}=") do |value|
        @associations ||= {}
        @associations.delete(association_name)
        instance_variable_set("@#{foreign_key}", value)
      end

      define_method(association_name) do
        return @associations[association_name] if @associations[association_name]

        foreign_key_value = send(foreign_key)
        return nil unless foreign_key_value

        association_class_name = association_name.to_s.capitalize
        association_class = Object.const_get(association_class_name)
        record = association_class.find(foreign_key_value)
        
        raise ORM::Base::RecordNotFound, "#{association_name} is not found" unless record
        
        @associations[association_name] = record
      end
    end

    def self.has_one(association_name, options = {})
      foreign_key = options[:foreign_key] || "#{self.name.downcase}_id"

      define_method("#{association_name}=") do |value|
        @associations ||= {}
        @associations[association_name] = value
      end

      define_method(association_name) do
        @associations ||= {}

        return @associations[association_name] if @associations[association_name]

        return nil unless id

        association_class_name = association_name.to_s.capitalize
        association_class = Object.const_get(association_class_name)
        record = association_class.where(foreign_key => id).first

        @associations[association_name] = record
      end
    end

    def self.has_many(association_name, options = {})
      foreign_key = options[:foreign_key] || "#{self.name.downcase}_id"

      define_method("#{association_name}=") do |value|
        @associations ||= {}
        @associations[association_name] = value
      end

      define_method(association_name) do
        @associations ||= {}

        return @associations[association_name] if @associations[association_name]
        
        return [] unless id

        association_class_name = association_name.to_s.delete_suffix("s").capitalize
        association_class = Object.const_get(association_class_name)
        records = association_class.where(foreign_key => id)
        @associations[association_name] = records
      end
    end

    # instance methods

    def save
      begin
        if id.nil? # INSERT
          insert_record
        else # UPDATE
          update_record
        end
        true # 成功
      rescue
        false # 失敗
      end
    end

    def update(attributes = {})
      attributes.each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end
      save
    end

    def destroy
      return false if id.nil?
      sql = "DELETE FROM #{self.class.table_name}
             WHERE id = ?"
      self.class.connection.execute(sql, id)
      self.id = nil
      true
    end

    private

    def self.generate_attributes_accessors
      column_names.each do |cn|
        unless method_defined?("#{cn}=")
          attr_accessor cn.to_sym
        end
      end
    end

    def insert_record
      columns, values = build_columns_and_values
      columns_sql = columns.join(', ')
      placeholders = (['?'] * columns.size).join(', ')
      sql = "INSERT INTO #{self.class.table_name} (#{columns_sql}) VALUES(#{placeholders});"
      self.class.connection.execute(sql, values)
      self.id = self.class.connection.last_insert_row_id
    end

    def update_record
      columns, values = build_columns_and_values
      set_clause = columns.map { |col| "#{col} = ?" }.join(', ')
      sql = "UPDATE #{self.class.table_name} SET #{set_clause} WHERE id = ?"
      self.class.connection.execute(sql, values + [id])
    end

    def build_columns_and_values
      columns = self.class.columns_definition.keys
      values = columns.map { |col| send(col) }
      [columns, values]
    end
  end
end

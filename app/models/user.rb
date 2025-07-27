require_relative '../../lib/orm/base'

class User < ORM::Base
  has_one :profile
  has_many :posts
  
  def self.columns_definition
    { name: 'TEXT', email: 'TEXT', age: 'INTEGER' }
  end
end

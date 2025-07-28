require_relative '../../lib/orm/base'

class User < ORM::Base
  has_one :profile
  has_many :posts

  scope :active,     -> { where(active: 1) }
  scope :just_adult, -> { where(age: 20) }
  
  def self.columns_definition
    { name: 'TEXT', email: 'TEXT', age: 'INTEGER', active: 'INTEGER' }
  end
end

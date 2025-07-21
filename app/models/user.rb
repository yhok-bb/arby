require_relative '../../lib/orm/base'

class User < ORM::Base
  def self.columns_definition
    { name: 'TEXT', email: 'TEXT' }
  end
end
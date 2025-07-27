require_relative '../../lib/orm/base'

class Profile < ORM::Base
  belongs_to :user
  
  def self.columns_definition
    { user_id: 'INTEGER', nickname: 'TEXT', bio: 'TEXT' }
  end
end

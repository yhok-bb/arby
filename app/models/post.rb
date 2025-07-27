require_relative '../../lib/orm/base'

class Post < ORM::Base
  belongs_to :user
  
  def self.columns_definition
    { user_id: 'INTEGER', title: 'TEXT', detail: 'TEXT' }
  end
end
require_relative '../../lib/orm/base'

class Post < ORM::Base
  def self.columns_definition
    { user_id: 'INTEGER', title: 'TEXT', detail: 'TEXT' }
  end
end
require_relative '../../lib/orm/base'

class Post < ORM::Base
  def self.columns_definition
    { title: 'TEXT', detail: 'TEXT' }
  end
end
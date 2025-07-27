# Ruby ORM Framework

A custom Object-Relational Mapping (ORM) framework built from scratch in Ruby, inspired by Active Record. This educational project demonstrates advanced Ruby programming concepts including metaprogramming, design patterns, and database integration.

## Features

### Core ORM Functionality
- **Active Record Pattern**: Model classes inherit from `ORM::Base`
- **Database Connection**: SQLite integration with connection management
- **CRUD Operations**: Create, Read, Update, Delete with intuitive API
- **Dynamic Attributes**: Automatic getter/setter generation from table schema

### Advanced Query Builder
- **Method Chaining**: `User.where(name: "Alice").order(:created_at).limit(10)`
- **Complex Queries**: Support for WHERE, ORDER BY, LIMIT, OFFSET, JOIN
- **Lazy Evaluation**: Queries execute only when results are accessed

### Associations (Relationships)
- **belongs_to**: `post.user` - Many-to-one relationships
- **has_one**: `user.profile` - One-to-one relationships  
- **has_many**: `user.posts` - One-to-many relationships
- **Lazy Loading**: Associated objects loaded on-demand with caching
- **Query Chaining**: `user.posts.where(published: true).order(:created_at)`

## Usage

### Basic Model Definition

```ruby
class User < ORM::Base
  has_many :posts
  has_one :profile
  
  def self.columns_definition
    { name: 'TEXT', email: 'TEXT', age: 'INTEGER' }
  end
end

class Post < ORM::Base
  belongs_to :user
  
  def self.columns_definition
    { user_id: 'INTEGER', title: 'TEXT', detail: 'TEXT' }
  end
end
```

### Database Setup

```ruby
# Establish connection
ORM::Base.establish_connection(database: ":memory:")

# Create tables
User.create_table
Post.create_table
```

### CRUD Operations

```ruby
# Create
user = User.create(name: "Alice", email: "alice@example.com")
user = User.new(name: "Bob")
user.save

# Read
user = User.find(1)
users = User.where(name: "Alice").to_a
first_user = User.first

# Update
user.update(name: "Alice Smith")
user.name = "Alice Johnson"
user.save

# Delete
user.destroy
```

### Query Builder

```ruby
# Method chaining
User.where(age: 25)
    .order(:name)
    .limit(10)
    .offset(20)
    .to_a

# Complex conditions
User.where(name: "Alice", age: 25)
Post.where(user_id: 1).order(:created_at)

# Joins
User.join(:posts).where(posts: { published: true })
```

### Associations

```ruby
# belongs_to
post = Post.find(1)
user = post.user  # Lazy loaded with caching

# has_one
user = User.find(1)
profile = user.profile  # One-to-one relationship

# has_many
user = User.find(1)
posts = user.posts.to_a  # Returns QueryBuilder for chaining

# Association chaining
user.posts.where(published: true)
          .order(:created_at)
          .limit(5)
          .each { |post| puts post.title }
```

## Development Setup

### Prerequisites
- Docker
- Docker Compose

### Getting Started

```bash
# Clone the repository
git clone <repository-url>
cd or-mapper

# Start containers
docker-compose up -d

# Run tests
docker-compose exec app bundle exec rspec

# Interactive console
docker-compose exec app irb
require_relative 'lib/orm/base'
```

## Testing

```bash
# Run all tests
docker-compose exec app bundle exec rspec

# Run specific test files
docker-compose exec app bundle exec rspec spec/orm/base_spec.rb

# Run with coverage
docker-compose exec app bundle exec rspec --format documentation
```

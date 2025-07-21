# Phase 1: 基礎ORマッパー実装 ✅

**目標**: ActiveRecord風の基本的なORMを実装し、CRUD操作を完全に理解する

## 概要

ActiveRecordの基本的な機能を一から実装することで、ORMの内部動作を深く理解する。

## 実装済み機能 ✅

### ☑️ Phase 1.1: table_nameメソッドの実装とテスト
- クラス名からテーブル名への自動変換機能
- `User` → `users`, `Post` → `posts`
- テンプレートメソッドパターンの理解

### ☑️ Phase 1.2: クラス名からテーブル名への自動変換機能  
- 複数のクラスでの動作確認
- User, Post, Comment クラスでのテスト

### ☑️ Phase 1.3: SQLite3データベース接続の基本実装
- コネクション管理とクラス変数の活用
- メモリ上のテストDB（`:memory:`）の活用

### ☑️ Phase 1.4: テーブル作成機能（テスト用）
- 動的なCREATE TABLE文の生成
- `columns_definition`メソッドによる拡張可能設計

### ☑️ Phase 1.5: カラム情報取得機能の実装
- SQLiteのPRAGMA文を使用した動的カラム取得
- `column_names`メソッドの実装

### ☑️ Phase 1.6: 属性アクセサの自動生成機能
- メタプログラミングによる`attr_accessor`の動的生成
- テーブル作成と連動した属性メソッドの生成

### ☑️ Phase 1.7: newメソッドの実装（インスタンス作成）
- ハッシュ形式での属性一括設定
- セーフガード付きの属性設定

### ☑️ Phase 1.8: saveメソッドの実装（INSERT文実行）
- パラメータバインディングによるSQLインジェクション対策
- 自動採番IDの取得と設定
- 新規作成と更新の自動判定

### ☑️ Phase 1.9: createメソッドの実装（new + save）
- クラスメソッドとしての実装
- エラーハンドリング（失敗時はnil返却）

### ☑️ Phase 1.10: findメソッドの実装（SELECT文実行）
- 動的な属性マッピング
- 存在しないレコードの適切な処理
- ArgumentErrorによる引数チェック

### ☑️ Phase 1.11: updateメソッドの実装（UPDATE文実行）
- saveメソッドの拡張による自動判定
- updateメソッドによる属性一括更新

### ☑️ Phase 1.12: deleteメソッドの実装（DELETE文実行）
- レコード削除後のid状態管理（nil設定）
- オブジェクト状態の一貫性保持

### ☑️ Phase 1.13: リファクタリング
- saveメソッドの責務分離
- `insert_record`, `update_record`, `build_columns_and_values`への分割

## 技術的な学習成果

### 1. メタプログラミング
- `attr_accessor`の動的生成
- `send`メソッドによる動的メソッド呼び出し
- `respond_to?`による安全なメソッド確認

### 2. セキュリティ対策
- SQLインジェクション対策（パラメータバインディング）
- 入力値の検証とサニタイゼーション

### 3. 設計パターン
- **テンプレートメソッドパターン**: `columns_definition`
- **ファクトリーパターン**: 動的インスタンス生成
- **単一責任原則**: メソッドの適切な分割

### 4. TDD（テスト駆動開発）
- RED-GREEN-REFACTORサイクルの実践
- エッジケースを含む包括的テスト
- DB内容の直接確認によるテストの信頼性向上

## 実装したファイル構造

```
or-mapper/
├── lib/
│   └── orm/
│       └── base.rb          # 核となるORMライブラリ
├── app/
│   └── models/
│       ├── user.rb          # サンプルモデル
│       ├── post.rb          # サンプルモデル
│       └── comment.rb       # サンプルモデル
├── spec/
│   └── orm/
│       └── base_spec.rb     # 包括的テストスイート
├── docker-compose.yml       # 開発環境
└── Gemfile                  # 依存関係
```

## 主要実装内容

### ORM::Base クラス
```ruby
module ORM
  class Base
    # クラスメソッド
    def self.establish_connection(config)
    def self.table_name
    def self.create_table
    def self.column_names
    def self.columns_definition  # テンプレートメソッド
    def self.create(attributes = {})
    def self.find(id)
    
    # インスタンスメソッド
    def initialize(attributes = {})
    def save
    def update(attributes = {})
    def destroy
    
    private
    def insert_record
    def update_record
    def build_columns_and_values
  end
end
```

### サンプルモデル実装例
```ruby
class User < ORM::Base
  def self.columns_definition
    { name: 'TEXT', email: 'TEXT' }
  end
end

class Post < ORM::Base  
  def self.columns_definition
    { title: 'TEXT', detail: 'TEXT' }
  end
end
```

## 使用例

```ruby
# データベース接続
ORM::Base.establish_connection(database: "development.sqlite3")

# テーブル作成
User.create_table

# 基本的なCRUD操作
user = User.create(name: "Alice", email: "alice@example.com")
found_user = User.find(user.id)
found_user.update(name: "Bob")
found_user.destroy
```
# Phase 4: アソシエーション実装 🔗

**目標**: テーブル間の関係を表現するアソシエーション機能を実装する

## 概要

リレーショナルデータベースの真価を発揮するアソシエーション機能を実装。has_many、belongs_to、has_one等の関係性を通じて、オブジェクト指向設計とデータベース設計の融合を学ぶ。

## 実装予定機能

### Phase 4.1: belongs_to関係の実装
- [ ] 外部キーの自動解決機能
- [ ] 関連オブジェクトの遅延読み込み
- [ ] belongs_to アソシエーションプロキシ

### Phase 4.2: has_one関係の実装  
- [ ] 1対1関係の表現
- [ ] 逆方向の関連設定
- [ ] has_one アソシエーションプロキシ

### Phase 4.3: has_many関係の実装
- [ ] 1対多関係の表現
- [ ] コレクションプロキシの実装
- [ ] 関連レコードの追加・削除

### Phase 4.4: 外部キーの自動解決
- [ ] 命名規則による外部キー推測
- [ ] カスタム外部キーの指定
- [ ] 複合外部キーの対応

### Phase 4.5: アソシエーションプロキシの実装
- [ ] 遅延読み込みの実装
- [ ] メソッド委譲の仕組み
- [ ] プロキシパターンの実践

### Phase 4.6: through オプションの実装
- [ ] 多対多関係の表現
- [ ] 中間テーブルの活用
- [ ] has_many :through の実装

### Phase 4.7: ポリモーフィック関連の実装
- [ ] 複数のモデルとの関連
- [ ] type/id パターンの実装
- [ ] 動的な関連先の解決

### Phase 4.8: アソシエーション拡張
- [ ] カスタムメソッドの定義
- [ ] スコープ付きアソシエーション
- [ ] 条件付き関連の実装

## 学習ポイント

### 1. プロキシパターンの実装
- 実際のオブジェクトへの代理アクセス
- 遅延読み込みの実現方法
- メソッド委譲の仕組み

### 2. 外部キー制約とデータ整合性
- 参照整合性の維持方法
- 外部キー制約の活用
- カスケード削除の考慮

### 3. ActiveRecord アソシエーション内部構造
- Association クラスの役割
- リフレクション機能の活用
- メタプログラミングによる動的定義

## 期待される成果物

```ruby
class User < ORM::Base
  has_many :posts
  has_one :profile
  has_many :comments
  has_many :commented_posts, through: :comments, source: :post
end

class Post < ORM::Base
  belongs_to :user
  has_many :comments
end

class Comment < ORM::Base
  belongs_to :user
  belongs_to :post
end

class Profile < ORM::Base
  belongs_to :user
end

# 使用例
user = User.find(1)

# belongs_to - 1回のクエリで取得
user.posts.each { |post| puts post.title }

# has_one - 遅延読み込み
puts user.profile.bio

# through関係 - 複雑な関連の簡単な表現
user.commented_posts.each { |post| puts post.title }

# アソシエーションチェーン + 遅延評価
user.posts
    .where(published: true)
    .order(:created_at)
    .limit(5)
    .each { |post| puts post.title }
```

## 技術的挑戦

### 1. N+1問題の回避
- 遅延読み込み vs 即座読み込み
- includes機能の設計
- クエリの最適化戦略

### 2. 循環参照の処理
- 双方向関連での無限ループ回避
- オブジェクトのライフサイクル管理
- メモリリークの防止

### 3. 複雑な関連の表現
- 多対多関係の適切な実装
- 条件付き関連の処理
- 動的な関連先の解決

## 実装の核心部分

```ruby
module ORM
  module Associations
    def has_many(association_name, options = {})
      foreign_key = options[:foreign_key] || "#{self.name.downcase}_id"
      
      define_method(association_name) do
        # HasManyAssociationプロキシを返す
        HasManyAssociation.new(self, association_name, foreign_key)
      end
    end
    
    def belongs_to(association_name, options = {})
      foreign_key = options[:foreign_key] || "#{association_name}_id"
      
      define_method(association_name) do
        # 外部キーから関連オブジェクトを取得
        foreign_key_value = send(foreign_key)
        return nil if foreign_key_value.nil?
        
        association_class = Object.const_get(association_name.to_s.classify)
        association_class.find(foreign_key_value)
      end
    end
  end
  
  class HasManyAssociation
    def initialize(owner, association_name, foreign_key)
      @owner = owner
      @association_name = association_name
      @foreign_key = foreign_key
      @loaded = false
      @records = []
    end
    
    def each
      load_records unless @loaded
      @records.each { |record| yield(record) }
    end
    
    def where(conditions)
      # 新しいRelationオブジェクトを返す
      association_class.where(@foreign_key => @owner.id).where(conditions)
    end
    
    private
    
    def load_records
      association_class = Object.const_get(@association_name.to_s.classify)
      @records = association_class.where(@foreign_key => @owner.id).to_a
      @loaded = true
    end
  end
end
```

## 次のステップへの準備

Phase 4の完了により、本格的なWebアプリケーションレベルのORM機能が整います：

- 複雑なデータ関係の表現能力
- N+1問題への意識
- プロキシパターンの実践的理解

→ **Phase 5**: スコープ、バリデーション、コールバックで実用性を向上
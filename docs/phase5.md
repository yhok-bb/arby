# Phase 5: 高度な機能実装 🚀

**目標**: 実用的なORMに必要な高度な機能を実装する

## 概要

基本的なCRUD操作とアソシエーションが完成した後、実際のWebアプリケーションで必要となる高度な機能を実装。バリデーション、コールバック、スコープ等を通じて、プロダクション品質のORMを目指す。

## 実装予定機能

### Phase 5.1: スコープ機能
- [ ] 名前付きスコープの定義
- [ ] スコープの組み合わせ
- [ ] デフォルトスコープの実装
- [ ] 動的スコープの作成

### Phase 5.2: バリデーション機能
- [ ] presence バリデーション
- [ ] uniqueness バリデーション  
- [ ] length バリデーション
- [ ] format バリデーション
- [ ] custom バリデーション
- [ ] バリデーションエラーの管理

### Phase 5.3: コールバック（ライフサイクル）
- [ ] before_save コールバック
- [ ] after_save コールバック
- [ ] before_create コールバック
- [ ] after_create コールバック
- [ ] before_update コールバック
- [ ] after_update コールバック
- [ ] before_destroy コールバック
- [ ] after_destroy コールバック

### Phase 5.4: トランザクション管理
- [ ] 基本的なトランザクション制御
- [ ] ネストしたトランザクション
- [ ] セーブポイントの活用
- [ ] ロールバック処理

### Phase 5.5: マイグレーション機能
- [ ] テーブル作成マイグレーション
- [ ] カラム追加マイグレーション
- [ ] インデックス作成マイグレーション
- [ ] マイグレーションの実行・ロールバック

### Phase 5.6: インデックス管理
- [ ] 単一カラムインデックス
- [ ] 複合インデックス
- [ ] ユニークインデックス
- [ ] インデックス戦略の最適化

### Phase 5.7: シリアライゼーション
- [ ] JSON形式でのデータ出力
- [ ] XML形式でのデータ出力
- [ ] カスタムシリアライザー
- [ ] 関連データの含有制御

### Phase 5.8: エラーハンドリングとログ
- [ ] 詳細なエラー情報の提供
- [ ] SQLクエリのログ出力
- [ ] パフォーマンス計測
- [ ] デバッグ情報の充実

## 学習ポイント

### 1. Observer パターンの実装
- イベント駆動の仕組み
- コールバックチェーンの管理
- 処理の順序制御

### 2. データベーストランザクションの管理
- ACID特性の理解
- 分離レベルの考慮
- デッドロック回避策

### 3. ActiveRecord コールバックチェーン
- フィルターチェーンの実装
- 条件付きコールバック
- コールバックの中断処理

## 期待される成果物

```ruby
class User < ORM::Base
  # バリデーション
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :age, numericality: { greater_than: 0, less_than: 120 }
  
  # コールバック
  before_save :normalize_email
  after_create :send_welcome_email
  before_destroy :cleanup_associations
  
  # スコープ
  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :adults, -> { where('age >= ?', 18) }
  scope :by_name, ->(name) { where(name: name) }
  
  private
  
  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
  
  def send_welcome_email
    # メール送信ロジック
  end
  
  def cleanup_associations
    posts.destroy_all
    comments.destroy_all
  end
end

# 使用例
# バリデーション
user = User.new(email: "invalid-email")
unless user.valid?
  puts user.errors.full_messages
end

# スコープの組み合わせ
active_adults = User.active.adults.recent.limit(10)

# トランザクション
User.transaction do
  user = User.create!(name: "Alice", email: "alice@example.com")
  Profile.create!(user: user, bio: "Developer")
  # エラーが発生した場合、両方ロールバック
end

# コールバックの実行
user = User.create(email: "BOB@EXAMPLE.COM")
puts user.email  # => "bob@example.com" (正規化済み)
```

## 技術的挑戦

### 1. バリデーションシステムの設計
- 複数のバリデーションルールの組み合わせ
- カスタムバリデーターの作成
- エラーメッセージの国際化対応

### 2. コールバックチェーンの実装
- 実行順序の保証
- エラー時の処理中断
- 条件付き実行の仕組み

### 3. スコープの合成可能性
- 複数スコープの組み合わせ
- 引数付きスコープの処理
- SQLクエリの最適化

## 実装の核心部分

```ruby
module ORM
  module Validations
    def validates(attribute, options = {})
      @validations ||= []
      
      if options[:presence]
        @validations << PresenceValidator.new(attribute)
      end
      
      if options[:uniqueness]
        @validations << UniquenessValidator.new(attribute)
      end
      
      if options[:length]
        @validations << LengthValidator.new(attribute, options[:length])
      end
    end
    
    def valid?
      @errors = Errors.new
      
      (@validations || []).each do |validator|
        validator.validate(self, @errors)
      end
      
      @errors.empty?
    end
  end
  
  module Callbacks
    def before_save(method_name)
      (@before_save_callbacks ||= []) << method_name
    end
    
    def after_create(method_name)
      (@after_create_callbacks ||= []) << method_name
    end
    
    private
    
    def run_callbacks(event)
      callbacks = instance_variable_get("@#{event}_callbacks")
      return unless callbacks
      
      callbacks.each do |callback|
        result = send(callback)
        return false if result == false  # 処理中断
      end
      true
    end
  end
  
  module Scopes
    def scope(name, lambda_proc)
      define_singleton_method(name) do |*args|
        instance_exec(*args, &lambda_proc)
      end
    end
  end
end
```

## 次のステップへの準備

Phase 5の完了により、実用的なWebアプリケーションで使用可能なORMが完成します：

- データの整合性保証（バリデーション）
- ビジネスロジックの組み込み（コールバック）
- 柔軟なクエリ構築（スコープ）
- 堅牢な処理制御（トランザクション）

→ **Phase 6**: パフォーマンス最適化でプロダクション品質を目指す
# Phase 3: 遅延評価システム実装 ⚡

**目標**: **最重要フェーズ** - 遅延評価の仕組みを実装し、ActiveRecordの核心を理解する

## 概要

ActiveRecordの最も重要な機能である遅延評価（Lazy Evaluation）を実装。「クエリをいつ実行するか」を制御し、パフォーマンス最適化の基盤を作る。

## 実装予定機能

### Phase 3.1: Relationクラスの設計と実装
- [ ] `ActiveRecord::Relation`相当のクラス設計
- [ ] クエリ条件の保持機能
- [ ] Enumerableインターフェースの実装

### Phase 3.2: 遅延評価（Lazy Evaluation）システム
- [ ] クエリ構築と実行の分離
- [ ] 遅延実行のトリガー設計
- [ ] メモリ効率的なクエリ管理

### Phase 3.3: クエリ実行タイミングの制御
- [ ] 実行タイミングの識別
- [ ] 必要時のみの実行（on-demand execution）
- [ ] 重複実行の回避

### Phase 3.4: 実行トリガーメソッドの実装
- [ ] `each` - イテレーション開始時に実行
- [ ] `to_a` - 配列変換時に実行  
- [ ] `first` - 最初の要素取得時に実行
- [ ] `last` - 最後の要素取得時に実行
- [ ] `count` - 件数取得時に実行

### Phase 3.5: クエリキャッシュ機能
- [ ] 一度実行した結果の保持
- [ ] 同じクエリの重複実行防止
- [ ] キャッシュ無効化のタイミング

### Phase 3.6: スコープチェーンの管理
- [ ] メソッドチェーンの状態管理
- [ ] 新しいRelationオブジェクトの生成
- [ ] 不変性の保持

### Phase 3.7: クエリ最適化のタイミング
- [ ] 実行直前のクエリ最適化
- [ ] 不要な条件の除去
- [ ] インデックス利用の考慮

### Phase 3.8: デバッグ機能
- [ ] 生成されるSQLの確認機能
- [ ] クエリ実行のログ出力
- [ ] パフォーマンス計測

## 学習ポイント

### 1. 遅延評価のメリット・デメリット
**メリット**:
- 不要なクエリの実行回避
- メソッドチェーンの柔軟な組み合わせ
- メモリ使用量の最適化

**デメリット**:
- 実行タイミングの予測困難
- デバッグの複雑化
- 意図しないクエリ実行

### 2. ActiveRecord::Relation の役割と実装
- クエリ条件の保持方法
- 新しいRelationの生成ルール
- Enumerableインターフェースとの連携

### 3. クエリ最適化のタイミング
- 構築時 vs 実行時の最適化
- 条件の統合と重複除去
- インデックス戦略の考慮

## 期待される成果物

```ruby
# この時点ではクエリは実行されない
relation = User.where(active: true)
              .where(age: 20..30)
              .order(:name)
              .limit(10)

puts relation.class  # => ORM::Relation

# ここで初めてクエリが実行される
relation.each { |user| puts user.name }

# 同じクエリは再実行されない（キャッシュ）
relation.to_a  # キャッシュから取得

# 新しい条件を追加（新しいRelationオブジェクト）
active_users = relation.where(last_login: 1.week.ago..)
puts relation.object_id != active_users.object_id  # => true

# デバッグ機能
puts relation.to_sql
# => "SELECT * FROM users WHERE active = ? AND age BETWEEN ? AND ? ORDER BY name LIMIT ?"
```

## 技術的挑戦

### 1. 状態管理の複雑さ
- 複数の条件を適切に保持
- 新しいRelationオブジェクトの生成
- 元のオブジェクトの不変性保持

### 2. 実行タイミングの制御
- どのメソッドで実行するか
- 部分的な実行（first, last等）の処理
- エラー時の適切なハンドリング

### 3. パフォーマンス最適化
- 重複クエリの排除
- 効率的なSQL生成
- メモリ使用量の最小化

## 実装の核心部分

```ruby
module ORM
  class Relation
    include Enumerable
    
    def initialize(klass)
      @klass = klass
      @conditions = []
      @orders = []
      @limit_value = nil
      @loaded = false
      @records = []
    end
    
    def where(conditions)
      # 新しいRelationオブジェクトを返す（不変性）
      new_relation = clone
      new_relation.add_condition(conditions)
      new_relation
    end
    
    def each
      # 必要時に実行
      load_records unless @loaded
      @records.each { |record| yield(record) }
    end
    
    private
    
    def load_records
      sql = build_sql
      results = @klass.connection.execute(sql)
      @records = results.map { |row| @klass.new(row) }
      @loaded = true
    end
  end
end
```

## 次のステップへの準備

Phase 3の完了により、ActiveRecordの核心機能が理解できます：

- 遅延評価システムの完全理解
- パフォーマンス最適化の基礎知識
- 大規模アプリケーションでの注意点

→ **Phase 4**: アソシエーションで複数テーブルの関係を管理
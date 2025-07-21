# Phase 6: パフォーマンス最適化 ⚡

**目標**: **リードエンジニア必須スキル** - N+1問題を理解し、クエリ最適化を実装する

## 概要

大規模アプリケーションで最も重要な要素であるパフォーマンス最適化を実装。N+1問題、Eager Loading、インデックス戦略等を通じて、実践的なパフォーマンスチューニング能力を身につける。

## 実装予定機能

### Phase 6.1: N+1問題の検出機能
- [ ] N+1問題の自動検出システム
- [ ] クエリ実行回数の監視
- [ ] 警告メッセージの出力
- [ ] パフォーマンス計測ツール

### Phase 6.2: includes（Eager Loading）の実装
- [ ] 関連データの先行読み込み
- [ ] LEFT JOINによる一括取得
- [ ] ネストした関連の処理
- [ ] includes の自動最適化

### Phase 6.3: preload の実装
- [ ] 個別クエリによる先行読み込み
- [ ] メモリ効率の最適化
- [ ] 大量データの処理対応

### Phase 6.4: eager_load の実装
- [ ] 強制的なJOIN実行
- [ ] 複雑な条件での最適化
- [ ] サブクエリの活用

### Phase 6.5: クエリ分析とログ機能
- [ ] 実行されるSQLの詳細ログ
- [ ] クエリ実行時間の計測
- [ ] スロークエリの検出
- [ ] クエリプランの表示

### Phase 6.6: インデックスヒントの実装
- [ ] 最適なインデックスの提案
- [ ] インデックス使用状況の分析
- [ ] 複合インデックスの最適化
- [ ] カーディナリティの考慮

### Phase 6.7: バッチ処理機能
- [ ] find_in_batches の実装
- [ ] メモリ効率的な大量データ処理
- [ ] バッチサイズの最適化
- [ ] 処理進捗の表示

### Phase 6.8: キャッシュ機能
- [ ] クエリ結果のキャッシュ
- [ ] 関連データのキャッシュ
- [ ] キャッシュ無効化戦略
- [ ] 分散キャッシュ対応

## 学習ポイント

### 1. N+1問題の原因と対策
**問題の理解**:
```ruby
# N+1問題の例（悪い例）
users = User.all
users.each { |user| puts user.posts.count }  # N回のクエリが実行される
```

**解決策**:
```ruby
# Eager Loadingで解決（良い例）
users = User.includes(:posts)
users.each { |user| puts user.posts.count }  # 2回のクエリのみ
```

### 2. Eager Loading vs Lazy Loading
- **Eager Loading**: 事前にデータを読み込み
- **Lazy Loading**: 必要時にデータを読み込み
- 使い分けの判断基準

### 3. クエリプランの読み方
- EXPLAIN文の解釈
- インデックスの効果測定
- ボトルネックの特定方法

### 4. 大規模データでのパフォーマンス考慮
- メモリ使用量の最適化
- バッチ処理による負荷分散
- データベース負荷の分散

## 期待される成果物

```ruby
# N+1問題の検出
User.detect_n_plus_one_queries do
  users = User.all
  users.each { |user| puts user.posts.title }
end
# Warning: N+1 query detected. Consider using includes(:posts)

# Eager Loadingによる最適化
users = User.includes(:posts, :profile)
            .where(active: true)
            .limit(100)

users.each do |user|
  puts "#{user.name}: #{user.posts.count} posts"
  puts "Bio: #{user.profile.bio}"
end
# SELECT * FROM users WHERE active = true LIMIT 100
# SELECT * FROM posts WHERE user_id IN (1,2,3,...)
# SELECT * FROM profiles WHERE user_id IN (1,2,3,...)

# バッチ処理でメモリ効率を向上
User.find_in_batches(batch_size: 1000) do |batch|
  batch.each do |user|
    user.update_statistics
  end
  puts "Processed batch of #{batch.size} users"
end

# クエリ分析
User.with_query_analysis do
  expensive_query = User.joins(:posts)
                       .where(posts: { published: true })
                       .group('users.id')
                       .having('COUNT(posts.id) > ?', 10)
  
  expensive_query.each { |user| process_user(user) }
end
# Query took 2.3s, used index: users_posts_idx
# Suggestion: Consider adding index on posts(user_id, published)

# インデックスヒント
User.with_index_hint('users_age_idx')
    .where(age: 25..35)
    .limit(100)
```

## 技術的挑戦

### 1. メモリ使用量とパフォーマンスのトレードオフ
- Eager Loading時のメモリ消費
- 適切なバッチサイズの決定
- キャッシュサイズの最適化

### 2. 複雑な関連での最適化
- ネストした関連のEager Loading
- 条件付き関連の処理
- ポリモーフィック関連の最適化

### 3. 動的な最適化判断
- クエリパターンの分析
- 自動的な最適化提案
- 実行時の動的最適化

## 実装の核心部分

```ruby
module ORM
  module Performance
    class NPlusOneDetector
      def self.detect(&block)
        @query_count = 0
        @query_log = []
        
        # クエリ実行をフック
        original_execute = Connection.instance_method(:execute)
        Connection.define_method(:execute) do |sql, *args|
          @query_count += 1
          @query_log << sql
          original_execute.bind(self).call(sql, *args)
        end
        
        yield
        
        # N+1パターンを検出
        detect_n_plus_one_pattern(@query_log)
      ensure
        # 元のメソッドを復元
        Connection.define_method(:execute, original_execute)
      end
      
      private
      
      def self.detect_n_plus_one_pattern(queries)
        # 類似クエリの検出ロジック
        similar_queries = queries.group_by { |q| normalize_query(q) }
        
        similar_queries.each do |pattern, queries|
          if queries.size > 5  # 閾値
            warn "N+1 query detected: #{pattern} (#{queries.size} times)"
          end
        end
      end
    end
    
    module EagerLoading
      def includes(*associations)
        relation = clone
        relation.includes_values = associations
        relation
      end
      
      private
      
      def load_with_includes
        if includes_values.present?
          load_records_with_eager_loading
        else
          load_records_normally
        end
      end
      
      def load_records_with_eager_loading
        # メインクエリを実行
        main_records = execute_main_query
        
        # 関連データをEager Loading
        includes_values.each do |association|
          load_association_data(main_records, association)
        end
        
        main_records
      end
    end
  end
end
```

## パフォーマンス指標

### 1. クエリ実行回数の削減
- Before: N+1問題で100+回のクエリ
- After: Eager Loadingで2-3回のクエリ

### 2. メモリ使用量の最適化
- バッチ処理による一定のメモリ使用量
- 不要なデータの読み込み回避

### 3. レスポンス時間の改善
- インデックス活用によるクエリ高速化
- 並行処理による処理時間短縮

## 次のステップへの準備

Phase 6の完了により、プロダクション環境で求められるパフォーマンス意識が身につきます：

- N+1問題の完全理解と対策
- 大規模データでの処理戦略
- パフォーマンス監視とボトルネック特定

→ **Phase 7**: ActiveRecordとの比較分析でさらなる改善点を発見
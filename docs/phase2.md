# Phase 2: クエリビルダー実装 🔄

**目標**: SQLを生成するクエリビルダーを実装し、メソッドチェーンの仕組みを理解する

## 概要

ActiveRecordの核心機能の一つであるクエリビルダーを実装。メソッドチェーンでSQL文を動的に構築する仕組みを理解し、Builder パターンの実践的な使用法を習得する。

## 実装予定機能

### Phase 2.1: QueryBuilderクラスの設計
- [ ] Builder パターンの実装
- [ ] メソッドチェーンの基盤設計
- [ ] SQL文の動的構築システム

### Phase 2.2: whereメソッドの実装
- [ ] 基本的な条件指定（`where(name: 'Alice')`）
- [ ] 範囲指定（`where(age: 20..30)`）
- [ ] 複数条件の組み合わせ
- [ ] WHERE句のSQL生成

### Phase 2.3: selectメソッドの実装
- [ ] カラム選択機能（`select(:name, :email)`）
- [ ] SELECT句のSQL生成
- [ ] 集約関数対応（COUNT, SUM等）

### Phase 2.4: orderメソッドの実装
- [ ] ソート機能（`order(:created_at)`）
- [ ] 昇順・降順指定（`order(name: :desc)`）
- [ ] ORDER BY句のSQL生成

### Phase 2.5: limit/offsetメソッドの実装
- [ ] 件数制限（`limit(10)`）
- [ ] オフセット指定（`offset(20)`）
- [ ] LIMIT/OFFSET句のSQL生成

### Phase 2.6: joinメソッドの実装
- [ ] 内部結合（`join(:posts)`）
- [ ] 外部結合（`left_join(:posts)`）
- [ ] JOIN句のSQL生成

### Phase 2.7: SQL生成エンジンの実装
- [ ] 各句の統合
- [ ] パラメータバインディング
- [ ] SQLインジェクション対策

### Phase 2.8: クエリ実行機能
- [ ] SQLの実行
- [ ] 結果のインスタンス化
- [ ] エラーハンドリング

## 学習ポイント

### 1. Builder パターン
- オブジェクトの段階的な構築
- メソッドチェーンの実現方法
- 不変性の保持

### 2. SQL動的生成
- 各SQL句の組み立て方
- 条件文の適切な処理
- パフォーマンスを考慮した生成

### 3. ActiveRecordクエリメソッドの内部動作
- `where`, `select`, `order`等の仕組み
- メソッドチェーンがどう機能するか
- SQLへの変換プロセス

## 期待される成果物

```ruby
# 基本的なクエリ
users = User.where(age: 20..30)
           .select(:name, :email)
           .order(:created_at)
           .limit(10)

# 複雑なクエリ
posts = Post.where(published: true)
           .where(created_at: 1.week.ago..)
           .joins(:user)
           .order(created_at: :desc)
           .limit(5)

# 生成されるSQL（例）
# SELECT name, email FROM users 
# WHERE age BETWEEN ? AND ? 
# ORDER BY created_at 
# LIMIT ?
```

## 技術的挑戦

1. **メソッドチェーンの設計**: 各メソッドが適切にチェーン可能
2. **SQL生成の最適化**: 不要な句を含まない効率的なSQL
3. **型安全性**: 不正な条件値の検出
4. **拡張性**: 新しいメソッドの追加が容易

## 次のステップへの準備

Phase 2の完了により、Phase 3の遅延評価システムの基盤が整います：

- SQL構築システムの完成
- メソッドチェーンの仕組み理解
- クエリオブジェクトの管理方法

→ **Phase 3**: 遅延評価システムで「いつ実行するか」を制御
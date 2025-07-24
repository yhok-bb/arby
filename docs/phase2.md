# Phase 2: クエリビルダー実装 🔄

**目標**: SQLを生成するクエリビルダーを実装し、メソッドチェーンの仕組みを理解する

## 概要

ActiveRecordの核心機能の一つであるクエリビルダーを実装。メソッドチェーンでSQL文を動的に構築する仕組みを理解し、Builder パターンの実践的な使用法を習得する。

## 学び
- クエリビルダーをするとき、メソッドチェーンできるようにクエリビルダーオブジェクトを返す必要がある
- この時、前の状態を引き継いだselfを返すか、新しいクエリビルダーオブジェクト(self.class.new(@klass))を返すかの問題があるが、これは後者が正解。なぜなら、前の状態のクエリをどこかで使っていた場合、引き継ぐとその状態も変わってしまうため

```ruby
builder = User.where(active: true)
admin_users = builder.where(admin: true)
regular_users = builder.where(admin: false)
```


## 実装予定機能

### Phase 2.1: QueryBuilderクラスの設計 ✅
- [x] Builder パターンの実装
- [x] メソッドチェーンの基盤設計
- [x] SQL文の動的構築システム

### Phase 2.2: whereメソッドの実装 ✅
- [x] 基本的な条件指定（`where(name: 'Alice')`）
- [x] 範囲指定（`where(age: 20..30)`）
- [x] 複数条件の組み合わせ
- [x] WHERE句のSQL生成
- [x] SQLの実行
- [x] 結果のインスタンス化
- [x] エラーハンドリング

### Phase 2.3: selectメソッドの実装 ✅
- [x] カラム選択機能（`select(:name, :email)`）
- [x] SELECT句のSQL生成
- [x] 集約関数対応（COUNT, SUM, AVG等）

### Phase 2.4: orderメソッドの実装 ✅
- [x] ソート機能（`order(:created_at)`）
- [x] 昇順・降順指定（`order(name: :desc)`）
- [x] 複数カラムソート（`order(age: :desc, name: :asc)`）
- [x] ORDER BY句のSQL生成

### Phase 2.5: limit/offsetメソッドの実装 ✅
- [x] 件数制限（`limit(10)`）
- [x] オフセット指定（`offset(20)`）
- [x] LIMIT/OFFSET句のSQL生成
- [x] SQLiteの制約対応（OFFSET単体では使用不可）

### Phase 2.6: joinメソッドの実装 ✅
- [x] 内部結合（`join(:posts)`）
- [x] 動的モデルクラス取得（`:posts` → `Post`クラス）
- [x] 外部キー自動推測（`user_id`）
- [x] JOIN句のSQL生成
- [x] 結果のインスタンス化とモデル紐付け
- [x] カラム分離とオブジェクト生成
- [x] 包括的テストカバレッジ
- [ ] 外部結合（`left_join(:posts)`）※実装見送り

### Phase 2.7: SQL生成エンジンの実装 ✅
- [x] 各句の統合（modular design）
- [x] 正しいSQL句順序（SELECT, FROM, JOIN, WHERE, ORDER BY, LIMIT, OFFSET）
- [x] パラメータバインディング（`?`プレースホルダー）
- [x] SQLインジェクション対策
- [x] Range型のパラメータ展開
- [x] 入力値のエスケープ処理
- [x] SQLインジェクション攻撃のテストケース


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

## 実装完了した成果物

```ruby
# 基本的なクエリ ✅
users = User.where(age: 20..30)
           .select(:name, :email)
           .order(:created_at)
           .limit(10)

# 複雑なクエリ ✅
posts = User.where(age: 25..35)
           .join(:posts)
           .order(age: :desc, name: :asc)
           .limit(5)

# JOIN結果の構造化 ✅
result = User.join(:posts).execute
# => { user: User(id: 1, name: "Alice"), post: Post(id: 1, title: "Hello") }

# 集約関数対応 ✅
User.select("COUNT(*)").execute  # => 5
User.select("AVG(age)").execute  # => 25.5

# 生成されるSQL（実装済み）
# 基本クエリ: SELECT name, email FROM users WHERE age BETWEEN ? AND ? ORDER BY created_at LIMIT ?
# JOIN: SELECT * FROM users INNER JOIN posts ON users.id = posts.user_id WHERE age BETWEEN ? AND ? ORDER BY age DESC, name ASC LIMIT ?
```

## 技術的挑戦と解決策

1. **メソッドチェーンの設計** ✅
   - 解決策: 新しいインスタンスを返すことで不変性を保持
   - 実装: `self.class.new(@klass, new_query_state)`

2. **SQL生成の最適化** ✅
   - 解決策: モジュラー設計で各句を独立して生成
   - 実装: `build_select_clause`, `build_where_clause` 等の分離

3. **型安全性とセキュリティ** ✅
   - 解決策: パラメータバインディングによるSQLインジェクション対策
   - 実装: `?` プレースホルダーと `bind_values` 配列

4. **拡張性** ✅
   - 解決策: Hash型の `query_state` で状態管理
   - 実装: 新機能追加時はstateに項目追加するだけ

5. **JOIN結果の処理** ✅
   - 解決策: カラム数による分離とオブジェクト生成
   - 実装: `convert_to_instances` での条件分岐

6. **データベース固有の制約** ✅
   - 解決策: SQLiteのOFFSET制約に対応
   - 実装: LIMITが必要な場合のみOFFSET出力

## Phase 2 完全制覇達成！ 🏆

**Phase 2で習得した技術：**
- ✅ Builder パターンの実装
- ✅ メソッドチェーンによる流暢なAPI設計
- ✅ SQL動的生成とセキュリティ対策
- ✅ Hash型状態管理による拡張性確保
- ✅ JOIN結果のオブジェクト化
- ✅ 包括的テストカバレッジ

**実装完了機能一覧：**
```ruby
# 全機能が完全動作
User.where(age: 20..30)
    .select(:name, :email)
    .order(age: :desc, name: :asc)
    .limit(10)
    .offset(5)
    .join(:posts)
    .execute

# 集約関数
User.select("COUNT(*)", "AVG(age)", "SUM(age)").execute

# セキュリティ対策
User.where(name: "' OR 1=1 --").execute  # SQLインジェクション防止済み
```

## 次のステップへの準備

Phase 2の完了により、以下の基盤が完璧に整いました：

- ✅ **SQL構築システム**: 完全なクエリビルダー
- ✅ **メソッドチェーン**: ActiveRecord風API
- ✅ **オブジェクト管理**: JOIN結果の構造化
- ✅ **セキュリティ**: SQLインジェクション対策

**Phase 3への準備完了！** 遅延評価システム実装の土台が完成しました。

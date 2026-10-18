# codepipeline-s3: CodePipeline で GitHub から S3 静的ウェブサイトへ自動デプロイする（2026-10-18 作成）

## 概要

GitHub → CodePipeline → S3 静的ウェブサイトの構成です。GitHub に push するとパイプラインが自動実行され、S3 のウェブサイトの表示が更新されることを確認します。

| 構成要素 | 役割 |
|---|---|
| GitHub | ソースの保管。push がパイプラインのトリガー |
| CodePipeline | Source → （Build）→ Deploy を実行 |
| CodeBuild（任意） | ビルドステージ。ここでは何もせずファイルを次へ渡す |
| S3（静的ウェブサイトホスティング） | デプロイ先。ウェブサイトとして公開 |

## ファイル

| ファイル | 役割 |
|---|---|
| `index.html` | デプロイするページ（`This is first deployment`）。編集して push し、更新を確認する |
| `buildspec.yml` | CodeBuild の定義。`echo` のみ実行し、`artifacts` で全ファイル（`**/*`）を次のステージへ渡す |
| `bucket-policy.json` | 公開読み取り用のバケットポリシー（`s3:GetObject` を `*` に許可）。`YOUR_BUCKET_NAME` を置換して使う |

## 事前準備

| 項目 | 内容 |
|---|---|
| GitHub リポジトリ | `index.html`（と `buildspec.yml`）を `main` ブランチに置く |
| S3 バケット | 名前は小文字のみ、全世界で一意（以降 `YOUR_BUCKET_NAME` と表記） |
| ブロックパブリックアクセス | オフ |
| 静的ウェブサイトホスティング | 有効、インデックスドキュメントは `index.html` |
| バケットポリシー | `bucket-policy.json` の `YOUR_BUCKET_NAME` を置換して設定 |

## 手順

1. CodePipeline でパイプラインを作成する（カスタム作成）

   | 項目 | 値 |
   |---|---|
   | ソースプロバイダー | GitHub（GitHub アプリ経由） |
   | 接続 | 新規に作成し、GitHub App をインストール（対象リポジトリを許可） |
   | ブランチ | `main` |
   | トリガー | Webhook イベントで開始（変更検出）を有効 |
   | ビルド | CodeBuild（`buildspec.yml` と同じ内容。`artifacts` を含める）またはスキップ |
   | テスト | スキップ |
   | デプロイ | Amazon S3、`YOUR_BUCKET_NAME` を指定、「デプロイ前にファイルを抽出する」をオン |

2. レビュー画面で Deploy ステージがあることを確認して作成する
3. パイプラインが成功したら、S3 のウェブサイトエンドポイントにアクセスし、`This is first deployment` を確認する
4. `index.html` の文言を編集（例: `This is second deployment`）して push する
5. パイプラインが自動実行され、ウェブサイトの表示が更新されることを確認する

## つまずきポイント

| # | 症状・原因 | 対処 |
|---|---|---|
| 1 | ソースステージに `Not Found` の警告が出る。GitHub App のインストールで対象リポジトリが許可されていない | GitHub の Installed GitHub Apps で対象リポジトリを許可する（接続を作り直して新規インストールでも可） |
| 2 | Deploy ステージが無いパイプラインができる | レビュー画面で Deploy があるか確認する。抜けていれば戻って追加する |
| 3 | ビルドの出力が空になる | `buildspec.yml` に `artifacts` の記述が必要 |
| 4 | Build ステージを外すと、Deploy の入力に古い Build のアーティファクトが残り、保存できない | Deploy アクションを作り直し、入力アーティファクトは `SourceArtifact` のみにする |
| 5 | ウェブサイトにアクセスできない | ウェブサイトエンドポイントは HTTP のみ（HTTPS は使えない） |
| 6 | 403 になる | バケットポリシーが未設定、またはブロックパブリックアクセスがオン |
| 7 | 404（NoSuchKey）になる | ポリシーは有効だが `index.html` がバケットに無い（デプロイ未完了など） |

## 学習ポイント（DVA-C02）

- パイプラインのステージ / アクション / アーティファクトの流れ
- S3 静的ウェブサイト: ブロックパブリックアクセス、バケットポリシー、インデックスドキュメント、403 と 404 の違い
- CodePipeline V2 とトリガー
- GitHub 接続は GitHub App（CodeConnections）
- CodeBuild の `buildspec.yml` の `artifacts` を次ステージへ渡す
- S3 デプロイの「ファイルを抽出する」
- ステージを編集するときはアーティファクトの依存に注意

## クリーンアップ（課金防止）

1. パイプラインを削除
2. CodeBuild プロジェクトを削除（作成した場合）
3. S3 バケットを空にして削除
4. IAM ロール（パイプライン、CodeBuild のサービスロール）を削除
5. GitHub の AWS Connector for GitHub のインストールを取り消す（必要に応じて検証用リポジトリも削除）

## 注意

認証情報（アクセスキー、トークン等）はこのリポジトリに置かないでください。

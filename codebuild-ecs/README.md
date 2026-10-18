# codebuild-ecs: CodeBuild で ECS(Fargate) を更新する（2026-10-18 作成）

## 概要

GitHub への push をきっかけに、CodeBuild が Docker ビルドを行い、ECR に push し、ECS(Fargate) のサービスを更新する CI/CD のハンズオンです。

| 構成要素 | 役割 |
|---|---|
| GitHub | ソース管理。push が Webhook で CodeBuild を起動 |
| CodeBuild | Docker イメージのビルド、ECR への push、タスク定義の登録、ECS サービス更新 |
| ECR | ビルドしたイメージの保管 |
| ECS on Fargate | コンテナの実行（nginx で index.html を配信） |

## ファイル

| ファイル | 役割 |
|---|---|
| `buildspec.yml` | CodeBuild のビルド定義。ECR ログイン、イメージのビルドと push、タスク定義の登録、サービス更新 |
| `Dockerfile` | `public.ecr.aws/nginx/nginx:alpine` をベースに `index.html` を配置 |
| `taskdef.json` | Fargate 用タスク定義。イメージは `<IMAGE_URI_PLACEHOLDER>` で、ビルド時に `sed` で置換される |
| `index.html` | 配信するページ。編集して push するとデプロイされる |

## 事前準備と置換箇所

| プレースホルダー | 置換するファイル | 値の例 |
|---|---|---|
| `YOUR_AWS_ACCOUNT_ID` | `buildspec.yml`、`taskdef.json` | 自分の AWS アカウントID |
| `YOUR_AWS_REGION` | `buildspec.yml` | `ap-northeast-1` |

アカウントIDを書き込んだ状態でコミットや公開をしないよう注意してください。

## リソース名（`buildspec.yml` 等に決め打ち。揃える必要あり）

| 種類 | 名前 |
|---|---|
| ECR リポジトリ | `my-webapp-repo-github` |
| ECS クラスター | `my-cluster` |
| ECS サービス | `my-webapp-service` |
| タスク定義ファミリー | `my-webapp-task` |
| コンテナ名 | `my-webapp-container` |
| タスク実行ロール | `ECSTaskExecutionRole`（`AmazonECSTaskExecutionRolePolicy` をアタッチ） |

CodeBuild プロジェクトのサービスロールには次のポリシーを付与しました。

- `AmazonEC2ContainerRegistryPowerUser`
- `AmazonECS_FullAccess`
- `IAMFullAccess`

これは学習用の便宜的な設定です。本番では最小権限にしてください。

## 実施した手順の要点

1. IAM ロールを2つ作成（ECS タスク実行ロール、CodeBuild サービスロール）
2. ECR リポジトリを作成
3. ECS クラスターを作成（Fargate のみ）
4. タスク定義を作成（ダミーイメージ `public.ecr.aws/nginx/nginx:latest`、ポート 80）
5. ECS サービスを作成（タスク数 1、パブリック IP オン、新規セキュリティグループで HTTP 80 を許可）
6. CodeBuild プロジェクトを作成（ソース GitHub、Webhook のイベントフィルタは PUSH、特権付与オン、既存のサービスロールを指定）
7. 手動でビルドを実行
8. `index.html` を編集して push し、自動デプロイされることを確認

## サブフォルダ配置時の注意

CodeBuild は既定でソースのルートにある `buildspec.yml` を探し、`docker build .` もルートで実行します。このフォルダだけをリポジトリのサブフォルダとして使う場合は、次の対応が必要です。

- CodeBuild の「Buildspec 名」に `codebuild-ecs/buildspec.yml` を指定する
- `buildspec.yml` 内で `cd codebuild-ecs` を実行する
- Webhook の `FILE_PATH` フィルタで、このフォルダの変更だけをトリガーにできる

## つまずきポイント

| # | 症状・原因 | 対処 |
|---|---|---|
| 1 | 配布版 buildspec の `echo "New task definition revision: $NEW_REVISION"` は、`: ` を YAML がキー:値と解釈し `YAML_FILE_ERROR` になる | この版では行全体をシングルクォートで囲んで修正済み |
| 2 | セキュリティグループが default だと HTTP が通らない | HTTP 80 を許可する新規セキュリティグループを使う |
| 3 | 特権付与をオンにしないと `docker build` が失敗する | CodeBuild プロジェクトで特権付与をオンにする |
| 4 | GitHub 認証で Secrets Manager と既存シークレットを選ぶと選択肢が空になる | 手軽には「CodeBuild マネージドトークン」を選ぶ（Secrets Manager は課金あり、本番向け） |
| 5 | Docker Hub の pull 制限 | Dockerfile のベースイメージを `public.ecr.aws/nginx/nginx:alpine` にした |

## 学習ポイント（DVA-C02）

- 信頼ポリシーと許可ポリシーの違い
- タスク実行ロールとタスクロールの違い
- `buildspec.yml` のフェーズ（`pre_build`、`build`、`post_build`）
- `env` の `parameter-store` と `secrets-manager`（認証情報を平文で書かない）
- ECS コンソールからのサービス作成では、裏で CloudFormation スタックが作られる
- タスクが入れ替わるとパブリック IP が変わる（固定したい場合は ALB）
- ビルドごとにタスク定義のリビジョンが増える

## クリーンアップ（課金防止。この順序で実施）

1. ECS サービスを削除（Fargate の課金停止）
2. CodeBuild プロジェクトを削除（Webhook も消える）
3. ECS クラスターを削除
4. ECR のイメージとリポジトリを削除
5. タスク定義の全リビジョンを登録解除
6. セキュリティグループを削除
7. IAM ロール2つを削除
8. CloudWatch Logs を削除
9. GitHub の OAuth 連携を解除

## 注意

認証情報（アクセスキー、トークン等）はこのリポジトリに置かないでください。

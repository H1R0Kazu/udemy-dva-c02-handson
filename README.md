# udemy-dva-c02-handson（2026-10-18 作成）

Udemy「AWS認定Developer Associate（DVA-C02）試験 対策トレーニング」の学習で作ったハンズオンのコードを、フォルダごとに整理して残す個人の学習用リポジトリです。

## フォルダ一覧

| フォルダ | 内容 |
|---|---|
| [`codebuild-ecs/`](./codebuild-ecs/) | AWS CodeBuild を使用した ECS の起動 |
| [`codedeploy-s3/`](./codedeploy-s3/) | CodeDeploy で EC2 へ In-place デプロイ（S3 の ZIP） |
| [`codepipeline-s3/`](./codepipeline-s3/) | CodePipeline で GitHub から S3 静的ウェブサイトへ自動デプロイ |

今後、ハンズオンごとにサブフォルダを追加していきます。

## 運用ルール

- ハンズオンごとにサブフォルダを作り、それぞれに README を置く
- AWS アカウントIDはプレースホルダー（`YOUR_AWS_ACCOUNT_ID`）で記載する
- 認証情報（アクセスキー、トークン等）は置かない
- `.gitignore` で `configs_*`、`screenshots_*`、`logs/` を除外している
- 学習完了後にアーカイブする予定

## 注意

- 試験対策の学習目的のリポジトリです
- AWS リソースは作成すると課金されます。ハンズオン終了後は必ずクリーンアップしてください（手順は各サブフォルダの README を参照）

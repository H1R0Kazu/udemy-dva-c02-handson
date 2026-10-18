# codedeploy-s3: CodeDeploy で EC2 に In-place デプロイする（2026-10-18 作成）

## 概要

CodeDeploy で EC2 上の Apache に Web ページを In-place デプロイするハンズオンです。S3 に置いた ZIP（v1、続いて v2）を手動でデプロイし、表示が更新されることを確認します。

| 構成要素 | 役割 |
|---|---|
| S3 | デプロイするリビジョン（ZIP）の保管 |
| CodeDeploy | アプリケーション `my-web-app`、デプロイグループ `WebApp-DG` で EC2 にデプロイ |
| EC2（Amazon Linux 2023） | Apache（httpd）と CodeDeploy エージェントを実行 |

## ファイル

| ファイル | 役割 |
|---|---|
| `user-data.sh` | EC2 のユーザーデータ。httpd と CodeDeploy エージェントを導入して起動 |
| `app-v1/` | v1 のリビジョン。`appspec.yml`、`index.html`（Version 1）、`scripts/start_server.sh`（httpd 再起動） |
| `app-v2/` | v2 のリビジョン。構成は v1 と同じで、`index.html` が Version 2 - Updated! |

## 事前準備

| 項目 | 内容 |
|---|---|
| IAM ロール（CodeDeploy 用） | `AWSCodeDeployServiceRole`（ポリシー `AWSCodeDeployRole`） |
| IAM ロール（EC2 用） | `EC2InstanceProfileForCodeDeploy`（ポリシー `AmazonS3ReadOnlyAccess`）。インスタンスプロファイルとして EC2 に付与 |
| EC2 | Amazon Linux 2023、セキュリティグループで HTTP 80 を許可、タグ `DeployTarget=WebApp`、ユーザーデータに `user-data.sh` |
| リージョン置換 | `user-data.sh` の CodeDeploy エージェントの URL（`us-east-1`）を、使うリージョンに置換 |
| S3 バケット | 名前は小文字のみ、全世界で一意（以降 `YOUR_BUCKET_NAME` と表記） |

## 手順

1. ZIP を作成する（フォルダの中で実行し、ZIP のルートに `appspec.yml` を置く）

   ```bash
   cd app-v1 && zip -r ../codedeploy-app-v1.zip . && cd ..
   cd app-v2 && zip -r ../codedeploy-app-v2.zip . && cd ..
   unzip -l codedeploy-app-v1.zip   # appspec.yml がルートにあることを確認
   ```

2. S3 にアップロードする

   ```bash
   aws s3 cp codedeploy-app-v1.zip s3://YOUR_BUCKET_NAME/
   aws s3 cp codedeploy-app-v2.zip s3://YOUR_BUCKET_NAME/
   ```

3. CodeDeploy のアプリケーションを作成する

   | 項目 | 値 |
   |---|---|
   | 名前 | `my-web-app` |
   | コンピューティングプラットフォーム | EC2/オンプレミス |

4. デプロイグループを作成する

   | 項目 | 値 |
   |---|---|
   | 名前 | `WebApp-DG` |
   | サービスロール | `AWSCodeDeployServiceRole` |
   | デプロイタイプ | In-place |
   | 環境 | Amazon EC2 インスタンス、タグ `DeployTarget=WebApp` |
   | デプロイ設定 | `CodeDeployDefault.AllAtOnce` |
   | ロードバランサー | なし |

5. v1 をデプロイする。リビジョンの場所は `s3://YOUR_BUCKET_NAME/codedeploy-app-v1.zip`（リビジョンタイプは S3、ファイルタイプは zip）
6. EC2 のパブリック IP に `http://` でアクセスし、Version 1 を確認する
7. v2 をデプロイする（`s3://YOUR_BUCKET_NAME/codedeploy-app-v2.zip`）
8. 再度アクセスし、Version 2 - Updated! に変わることを確認する

## つまずきポイント

| # | 症状・原因 | 対処 |
|---|---|---|
| 1 | `AppSpec file not found` で失敗する。フォルダごと ZIP にすると `appspec.yml` がルートに来ない | フォルダの中で `zip -r ../xxx.zip .` を実行し、`unzip -l` で確認する |
| 2 | S3 バケットが作成できない | バケット名は小文字のみにする |
| 3 | 「リビジョンフォーマットが無効です」になる | リビジョンの場所は `s3://` で始める（`sd3://` などの誤入力に注意） |
| 4 | ブラウザで表示できない | URL は `http://`（HTTPS は設定していない）。セキュリティグループで HTTP 80 を許可しているか確認 |

## 学習ポイント（DVA-C02）

- In-place と Blue/Green の違い
- `appspec.yml` のフック（ApplicationStop、BeforeInstall、AfterInstall、ApplicationStart、ValidateService）と実行順
- CodeDeploy エージェントと EC2 の IAM ロール（S3 読み取り）、サービスロールの役割の違い
- デプロイ設定（AllAtOnce、HalfAtATime、OneAtATime）
- タグでデプロイ対象を指定する
- リビジョンの保管先は S3 または GitHub
- ZIP のルートに `appspec.yml` を置く

## クリーンアップ（課金防止）

1. EC2 インスタンスを終了
2. S3 バケットを空にして削除
3. CodeDeploy アプリケーションを削除（デプロイグループも消える）
4. IAM ロール 2 つを削除
5. 必要に応じてセキュリティグループを削除

## 注意

認証情報（アクセスキー、トークン等）はこのリポジトリに置かないでください。

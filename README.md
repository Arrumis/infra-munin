# infra-munin

Munin の監視 UI を Docker 化した独立 repo です。旧 installer の `inst/munin` と `munin.sh` を分離し、環境依存の置換処理を `init-layout.sh` に集約しています。

## 起動

```bash
cp .env.example .env.local
./scripts/init-layout.sh
docker compose --env-file .env.local up -d
docker compose exec munin /setup_docker_plugins.sh
```

初回は reverse proxy と同じ external network が必要です。

```bash
docker network create proxy-network
```

## 管理対象

- Munin Web UI コンテナ
- Docker 監視用 `docker_` プラグイン

ホスト側の `munin-node` 設定はコンテナの外にあるので、この repo では補助スクリプトだけ用意しています。

## 初期化

```bash
./scripts/init-layout.sh
```

このスクリプトは以下を行います。

- `data/config/` を作成
- `templates/config/` から実運用用設定を生成
- `MUNIN_NODE_ADDRESS` などの環境変数を設定へ反映

## 補足

- `apache2_munin.conf` は内部ネットワークからのアクセスだけ許可します
- 認証は proxy 側で行う前提なので、Munin コンテナ内部の basic 認証は有効化していません
- ホストに `munin-node` を入れる場合は `scripts/setup-host-munin-node.sh` を土台にできます

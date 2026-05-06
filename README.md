# infra-munin

Munin の監視画面を Docker で動かすためのリポジトリです。
Docker コンテナとホスト側の munin-node を監視します。

## 使い方

```bash
cp .env.example .env.local
./scripts/init-layout.sh
docker compose --env-file .env.local up -d
docker compose exec munin /setup_docker_plugins.sh
```

初回はリバースプロキシと同じ Docker ネットワークが必要です。

```bash
docker network create proxy-network
```

## 変更する値

`.env.example` は公開用の見本です。実際の値は `.env.local` に書きます。

- `PROXY_NETWORK_NAME`: リバースプロキシと同じ Docker ネットワーク名です。
- `MUNIN_HTTP_PORT`: Munin 画面のローカル公開ポートです。
- `MUNIN_NODE_NAME`: グラフ上に出る監視ノード名です。
- `MUNIN_NODE_ADDRESS`: munin-node の接続先です。通常は既定値のままで構いません。
- `INFRA_MUNIN__...`: 親リポジトリからまとめて設定するときに使います。

## 管理対象

- Munin 画面コンテナ
- Docker 監視用 `docker_` プラグイン
- ホスト側 munin-node の接続許可設定

ホスト側の munin-node はコンテナの外にあります。
親リポジトリから一括導入する場合は `scripts/setup-host-munin-node.sh` が実行されます。

## データ

GitHub に上げるもの:

- `compose.yaml`
- `.env.example`
- `scripts/`
- `templates/`
- `README.md`

GitHub に上げないもの:

- `.env.local`
- `data/config/`

## 補足

- 認証はリバースプロキシ側で行う前提です。
- Apache 側では、Docker 内部やホスト内からの接続だけを許可します。

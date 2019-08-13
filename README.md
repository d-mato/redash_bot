# RedashBot

## Usage

```
$ docker-compose up --build
```

### Configuration

```
$ cp config.yml.example config.yml
```

Set your api key and etc.

```yaml
slack:
  token: xoxb-abc-1232
redash:
  base_url: https://example.redash.jp
  api_key: secret

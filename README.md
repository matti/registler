# registler

docker registry that just works

## cloudflared tunnel

```console
cloudflared tunnel create --secret [[BASE64]] registler
cloudflared tunnel route dns registler registler.example.com
```

`.env`

```.env
CLOUDFLARED_ACCOUNT_TAG=
CLOUDFLARED_TUNNEL_ID=
CLOUDFLARED_TUNNEL_SECRET=
```

## TODO

- redis cache with max memory both localhost and shared variants

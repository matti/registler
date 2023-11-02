# registler

docker registry that just works

```.env
REGISTLER_KEEP=32
```

## s3

```.env
STORAGE=s3
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=
AWS_S3_BUCKET=
```

## gcs

```.env
STORAGE=gcs
GCS_BUCKET=
```

and  `/keyfile.json`

## cloudflared tunnel

```console
cloudflared tunnel create --secret [[BASE64]] registler
cloudflared tunnel route dns registler registler.example.com
```

```.env
CLOUDFLARED_ACCOUNT_TAG=
CLOUDFLARED_TUNNEL_ID=
CLOUDFLARED_TUNNEL_SECRET=
```

## TODO

- redis cache with max memory both localhost and shared variants

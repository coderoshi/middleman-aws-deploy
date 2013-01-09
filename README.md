# Middleman AWS Deploy

Deploys build files to S3 at the end of the Middleman build toolchain, and/or invalidates Cloudfront.

In your `config.rb` file, add.

```
configure :build do
  # ...
  if ENV.include?('DEPLOY')
    activate :s3_deploy do |s3|
      s3.access_key_id = ENV['AWS_ACCESS_KEY_ID']
      s3.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
      s3.bucket = ENV['AWS_S3_BUCKET']
    end
    activate :invalidate_cloudfront do |cf|
      cf.access_key_id = ENV['AWS_ACCESS_KEY_ID']
      cf.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
      cf.distribution_id = ENV['AWS_CLOUDFRONT_DIST_ID']
    end
  end
end
```

With valid AWS creds, an s3 bucket, and cloudfront distribution id, you can deploy
with the env var DEPLOY as a trigger (you can use whichever kind of trigger you like):

```
DEPLOY=true middleman build
```

### S3 Deployment Note

The S3 deployer will check local file's md5 hash against the remote s3 etag. If
they are the same, it will not upload the identical file. However, if
you have `:cachebuster` set to active the hashes will always end up different
on every build, triggering an upload. There's little such danger however for
assets (css, images, etc).

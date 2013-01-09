require "middleman-core"
require "middleman-aws-deploy/s3deploy"
require "middleman-aws-deploy/cloudfront-invalidate"

::Middleman::Extensions.register(:s3_deploy, Middleman::AWSDeploy::S3Deploy)
::Middleman::Extensions.register(:invalidate_cloudfront, Middleman::AWSDeploy::InvalidateCloudfront)

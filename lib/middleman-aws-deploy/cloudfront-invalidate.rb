require 'rubygems'
require 'uri'
require 'hmac'
require 'hmac-sha1'
require 'net/https'
require 'base64'

CF_BATCH_SIZE = 1000

module Middleman
  module AWSDeploy
    module InvalidateCloudfront
      Opts = Struct.new(:access_key_id, :secret_access_key, :distribution_id)

      class << self
        module Options
          def aws_cfi_opts
            ::Middleman::AWSDeploy::InvalidateCloudfront.options
          end
        end

        def options
          @@options
        end

        def registered(app, opts_data = {}, &block)
          @@options = Opts.new(opts_data)
          yield @@options if block_given?

          app.send :include, Options
          app.after_build do
            puts "== Invalidating CloudFront"
            
            # you can only invalidate in batches of 1000
            def invalidate(files, pos=0)
              paths, count = "", 0

              escaped_files = []
              files[pos...(pos+CF_BATCH_SIZE)].each do |key|
                count += 1
                escaped_files << (escaped_file = URI.escape(key.to_s))
                paths += "<Path>#{escaped_file}</Path>"
              end

              return if count < 1

              paths = "<Paths><Quantity>#{count}</Quantity><Items>#{paths}</Items></Paths>"

              digest = HMAC::SHA1.new(aws_cfi_opts.secret_access_key)
              digest << date = Time.now.utc.strftime("%a, %d %b %Y %H:%M:%S %Z")

              uri = URI.parse("https://cloudfront.amazonaws.com/2012-07-01/distribution/#{aws_cfi_opts.distribution_id}/invalidation")
              header = {
                'x-amz-date' => date,
                'Content-Type' => 'text/xml',
                'Authorization' => "AWS %s:%s" %
                  [aws_cfi_opts.access_key_id, Base64.encode64(digest.digest)]
              }
              req = Net::HTTP::Post.new(uri.path)
              req.initialize_http_header(header)
              body = "<InvalidationBatch xmlns=\"http://cloudfront.amazonaws.com/doc/2012-07-01/\">#{paths}<CallerReference>ref_#{Time.now.utc.to_i}</CallerReference></InvalidationBatch>"
              req.body = body

              http = Net::HTTP.new(uri.host, uri.port)
              http.use_ssl = true
              http.verify_mode = OpenSSL::SSL::VERIFY_NONE
              res = http.request(req)
              if res.code == '201'
                puts "CloudFront reloading #{count} paths"
              else
                $stderr.puts "CloudFront Invalidate failed with error #{res.code}"
                $stderr.puts res.body
                $stderr.puts escaped_files.join("\n")
              end
              return if res.code == 400

              if count == CF_BATCH_SIZE
                invalidate(files, pos+count)
              end
            end

            def cf_files
              files = Dir["./build/**/.*", "./build/**/*"]
                .reject{|f| File.directory?(f) }.map{|f| f.sub(/^(?:\.\/)?build\//, '/') }
              # if :directory_indexes is active, we must invalidate both files and dirs
              # doing this 100% of the time, it would be nice if we could find of
              files += files.map{|f| f.gsub(/\/index\.html$/, '/') }
              files.uniq!
            end

            invalidate(cf_files)
          end
        end
        alias :included :registered
      end
    end
  end
end

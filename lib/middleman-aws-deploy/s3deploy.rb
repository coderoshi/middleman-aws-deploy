require 'rubygems'
require 'fog'
require 'parallel'
require 'progressbar'
require 'digest/md5'

module Middleman
  module AWSDeploy
    module S3Deploy
      Opts = Struct.new(:access_key_id, :secret_access_key, :threads, :bucket, :region)

      class << self
        module Options
          def aws_s3_opts
            ::Middleman::AWSDeploy::S3Deploy.options
          end
        end

        def options
          @@options
        end

        def registered(app, opts_data = {}, &block)
          @@options = Opts.new(opts_data)
          yield @@options if block_given?

          @@options.threads ||= 8
          app.send :include, Options
          app.after_build do
            puts "== Uploading to S3"

            def storage
              @storage ||= Fog::Storage.new({
                :provider => 'AWS',
                :aws_access_key_id => aws_s3_opts.access_key_id,
                :aws_secret_access_key => aws_s3_opts.secret_access_key,
                :region => aws_s3_opts.region
              })
            end

            def remote_files
              @directory ||= storage.directories.get(aws_s3_opts.bucket)
              @remote_files ||= @directory.files
            end

            def etag(key)
              object = remote_files.head(key)
              object && object.etag
            end

            def upload(key)
              begin
                remote_files.new({
                  :key => key,
                  :body => File.open("./build/#{key}"),
                  :public => true,
                  :acl => 'public-read'
                }).save
              rescue
                $stderr.puts "Failed to upload #{key}"
              end
            end

            def files
              @files ||= Dir["./build/**/.*", "./build/**/*"]
                .reject{|f| File.directory?(f) }.map{|f| f.sub(/^(\.\/)?build\//, '') }
            end

            # no need to upload an exact copy of an existing remote file
            replace = []
            progress = ProgressBar.new('Hash check', files.count)
            Parallel.each(files,
              :in_threads => aws_s3_opts.threads,
              :finish => lambda {|i, item| progress.inc }) do |f|
              md5 = Digest::MD5.hexdigest(File.read("./build/#{f}"))
              replace << f if md5 != etag(f)
            end
            progress.finish

            if replace.empty?
              puts "Nothing to upload"
            else
              # upload necessary files
              progress = ProgressBar.new('Uploading', replace.count)
              Parallel.each(replace,
                :in_threads => aws_s3_opts.threads,
                :finish => lambda {|i, item| progress.inc }) do |f|
                upload(f)
              end
              progress.finish
            end
          end
        end
        alias :included :registered
      end
    end
  end
end

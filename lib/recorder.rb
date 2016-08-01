# Author::    Robert Dormer (mailto:rdormer@gmail.com)
# Copyright:: Copyright (c) 2016 Robert Dormer
# License::   MIT

#==============================================
# Class for saving visited URIs as YAML-ized files with response codes and headers.
# Takes the network request code as a block, hashes the URI to get a file name, and
# then creates it and saves it if it's not present, or reads and returns the contents
# if it is.  Since the data returned from the file is an exact copy of what the block
# returned for that URI, it's a constant, deterministic recording that is highly useful
# for integration tests and the like.  Yes, you can use VCR if that's your thing, but
# I found it difficult to integrate with real-world crawlers.  This is a lightweight
# wrapper to give you 90% of the same thing.
#==============================================
require 'digest'
require 'base64'
require 'yaml'

module Spider
  class VisitRecorder
    @@directory = ''
    @@active = false
    @@recording = false

    class << self
    def activate!
      @@active = true
    end

    def record!
      @@recording = true
    end

    def deactivate!
      @@active = false
    end

    def pause!
      @@recording = false
    end

    def config(dir)
      @@directory = dir
    end

    def recall(*args)
      if @@active
        url = args.first.to_s
        data = ''

        store = locate_file(url)

        if(store.size == 0)
          raise "Unexpected request: #{url}" unless @@recording
          data = yield *args if block_given?

          begin
            store.write(package(url, data))
          rescue StandardError => e
            puts e.message
            puts "On file #{store.path}"
          end

        else
          data = unpackage(store, url)
        end

        return data

      elsif block_given?
        yield *args
      end
    end

      private

    def locate_file(url)
      key = Digest::MD5.hexdigest(url)
      path = File.expand_path(key, @@directory)
      fsize = File.size?(path)
      (fsize.nil? || fsize.zero? ? File.open(path, 'w') : File.open(path, 'r'))
    end

    def package(url, data)
      payload = {}
      payload[:url] = url.encode('UTF-8')
      payload[:data] = Base64.encode64(data)

      unless data.http_status.nil?
        payload[:response] = data.http_status
      end

      unless data.http_headers.nil?
        payload[:headers] = Base64.encode64(data.http_headers)
      end

      payload.to_yaml
    end

    def unpackage(store, url)
      raw = YAML.load(store.read)
      raise 'URL mismatch in recording' unless raw[:url] == url
      data = Base64.decode64(raw[:data])
      data.http_headers = Base64.decode64(raw[:headers])
      data.http_status = raw[:response]
      data
    end
  end
  end
end

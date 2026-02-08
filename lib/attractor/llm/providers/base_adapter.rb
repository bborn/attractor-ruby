# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module Attractor
  module LLM
    module Providers
      module BaseAdapter
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def provider_name
            raise NotImplementedError
          end
        end

        attr_reader :api_key, :base_url

        def complete(request)
          raise NotImplementedError, "#{self.class}#complete not implemented"
        end

        def stream(request, &)
          raise NotImplementedError, "#{self.class}#stream not implemented"
        end

        private

        def http_post(url, headers:, body:, &chunk_handler)
          uri = URI(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == 'https'
          http.read_timeout = 300
          http.open_timeout = 30

          req = Net::HTTP::Post.new(uri.request_uri)
          headers.each { |k, v| req[k] = v }
          req.body = JSON.generate(body)

          if chunk_handler
            http.request(req) do |response|
              handle_http_error(response) unless response.is_a?(Net::HTTPSuccess)
              response.read_body(&chunk_handler)
            end
          else
            response = http.request(req)
            handle_http_error(response) unless response.is_a?(Net::HTTPSuccess)
            JSON.parse(response.body, symbolize_names: false)
          end
        rescue Net::OpenTimeout, Net::ReadTimeout => e
          raise TimeoutError.new(e.message, provider: self.class.provider_name)
        rescue Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError => e
          raise ConnectionError.new(e.message, provider: self.class.provider_name)
        end

        def handle_http_error(response)
          status = response.code.to_i
          body = response.body
          provider = self.class.provider_name

          case status
          when 401
            raise AuthenticationError.new('Authentication failed', status_code: status, provider: provider,
                                                                   raw_body: body)
          when 429
            retry_after = response['retry-after']&.to_f
            raise RateLimitError.new('Rate limited', status_code: status, provider: provider, raw_body: body,
                                                     retry_after: retry_after)
          when 404
            raise ModelNotFoundError.new('Model not found', status_code: status, provider: provider, raw_body: body)
          when 400
            raise InvalidRequestError.new("Bad request: #{body}", status_code: status, provider: provider,
                                                                  raw_body: body)
          else
            raise APIError.new("HTTP #{status}: #{body}", status_code: status, provider: provider, raw_body: body)
          end
        end

        def default_headers
          { 'Content-Type' => 'application/json' }
        end
      end
    end
  end
end

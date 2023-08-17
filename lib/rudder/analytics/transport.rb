# frozen_string_literal: true

require 'rudder/analytics/defaults'
require 'rudder/analytics/utils'
require 'rudder/analytics/response'
require 'rudder/analytics/logging'
require 'rudder/analytics/backoff_policy'
require 'net/http'
require 'net/https'
require 'json'
require 'uri'
require 'zlib'

module Rudder
  class Analytics
    class Transport
      include Rudder::Analytics::Defaults::Request
      include Rudder::Analytics::Utils
      include Rudder::Analytics::Logging

      attr_reader :stub

      def initialize(config)
        @stub = config.stub || false
        @path = PATH
        @retries = config.retries || RETRIES
        @backoff_policy = config.backoff_policy || Rudder::Analytics::BackoffPolicy.new

        uri = URI(config.data_plane_url)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = config.ssl.nil? ? true : config.ssl
        http.read_timeout = 8
        http.open_timeout = 4

        @http = http
        @gzip = config.gzip.nil? ? true : config.gzip
      end

      # Sends a batch of messages to the API
      #
      # @return [Response] API response
      def send(write_key, batch)
        logger.debug("Sending request for #{batch.length} items")

        last_response, exception = retry_with_backoff(@retries) do
          status_code, body = send_request(write_key, batch)
          error = body
          # rudder server now return 'OK'
          # begin
          #     error = JSON.parse(body)['error']
          # rescue StandardError
          #   error = JSON.parse(body.to_json)
          #       end

          # puts error
          should_retry = should_retry_request?(status_code, body)
          logger.debug("Response status code: #{status_code}")
          logger.debug("Response error: #{error}") if error

          [Response.new(status_code, error), should_retry]
        end

        if exception
          logger.error(exception.message)
          exception.backtrace.each { |line| logger.error(line) }
          Response.new(-1, exception.to_s)
        else
          last_response
        end
      end

      # Closes a persistent connection if it exists
      def shutdown
        @http.finish if @http.started?
      end

      private

      def should_retry_request?(status_code, body)
        if status_code >= 500
          true # Server error
        elsif status_code == 429
          true # Rate limited
        elsif status_code >= 400
          logger.error(body)
          false # Client error. Do not retry, but log
        else
          false
        end
      end

      # Takes a block that returns [result, should_retry].
      #
      # Retries upto `retries_remaining` times, if `should_retry` is false or
      # an exception is raised. `@backoff_policy` is used to determine the
      # duration to sleep between attempts
      #
      # Returns [last_result, raised_exception]
      def retry_with_backoff(retries_remaining, &block)
        result, caught_exception = nil
        should_retry = false

        begin
          result, should_retry = yield
          return [result, nil] unless should_retry
        rescue StandardError => e
          should_retry = true
          caught_exception = e
        end

        if should_retry && (retries_remaining > 1)
          logger.debug("Retrying request, #{retries_remaining} retries left")
          sleep(@backoff_policy.next_interval.to_f / 1000)
          retry_with_backoff(retries_remaining - 1, &block)
        else
          [result, caught_exception]
        end
      end

      # Sends a request for the batch, returns [status_code, body]
      def send_request(write_key, batch)
        payload = {
          :batch => batch.messages
        }
        if stub
          logger.debug "stubbed request to #{@path}: " \
            "write key = #{write_key}, batch = #{JSON.generate(payload)}"

          [200, '{}']
        else

          headers = HEADERS

          if @gzip
            gzip = Zlib::GzipWriter.new(StringIO.new)
            gzip << payload.to_json
            payload = gzip.close.string
          else
            headers.delete('Content-Encoding')
            payload = JSON.generate(payload)
          end

          request = Net::HTTP::Post.new(@path, headers)
          request.basic_auth(write_key, nil)
          @http.start unless @http.started? # Maintain a persistent connection
          response = @http.request(request, payload)
          [response.code.to_i, response.body]
        end
      end
    end
  end
end

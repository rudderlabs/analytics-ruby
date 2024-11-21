# frozen_string_literal: true

require 'rudder/analytics/utils'

module Rudder
  class Analytics
    class Configuration
      include Rudder::Analytics::Utils

      attr_reader :write_key, :data_plane_url, :on_error, :on_error_with_messages, :stub, :gzip, :ssl, :batch_size, :test, :max_queue_size, :backoff_policy, :retries

      def initialize(settings = {})
        symbolized_settings = symbolize_keys(settings)

        @test = symbolized_settings[:test]
        @write_key = symbolized_settings[:write_key]
        @data_plane_url = symbolized_settings[:data_plane_url]
        @max_queue_size = symbolized_settings[:max_queue_size] || Defaults::Queue::MAX_SIZE
        @ssl = symbolized_settings[:ssl]
        @on_error = symbolized_settings[:on_error] || proc { |status, error| }
        @on_error_with_messages = symbolized_settings[:on_error_with_messages] || proc { |status, error, messages| }
        @stub = symbolized_settings[:stub]
        @batch_size = symbolized_settings[:batch_size] || Defaults::MessageBatch::MAX_SIZE
        @gzip = symbolized_settings[:gzip]
        @backoff_policy = symbolized_settings[:backoff_policy]
        @retries = symbolized_settings[:retries]
        raise ArgumentError, 'Missing required option :write_key' \
          unless @write_key
        raise ArgumentError, 'Data plane url must be initialized' \
          unless @data_plane_url
      end
    end
  end
end

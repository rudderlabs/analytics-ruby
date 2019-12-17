require 'Rudder/analytics/version'
require 'Rudder/analytics/defaults'
require 'Rudder/analytics/utils'
require 'Rudder/analytics/field_parser'
require 'Rudder/analytics/client'
require 'Rudder/analytics/worker'
require 'Rudder/analytics/request'
require 'Rudder/analytics/response'
require 'Rudder/analytics/logging'

module Rudder
  class Analytics
    # Initializes a new instance of {Rudder::Analytics::Client}, to which all
    # method calls are proxied.
    #
    # @param options includes options that are passed down to
    #   {Rudder::Analytics::Client#initialize}
    # @option options [Boolean] :stub (false) If true, requests don't hit the
    #   server and are stubbed to be successful.
    def initialize(options = {})
      Request.stub = options[:stub] if options.has_key?(:stub)
      @client = Rudder::Analytics::Client.new options
    end

    def method_missing(message, *args, &block)
      if @client.respond_to? message
        @client.send message, *args, &block
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @client.respond_to?(method_name) || super
    end

    include Logging
  end
end

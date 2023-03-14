# frozen_string_literal: true

require 'rudder/analytics/version'
require 'rudder/analytics/defaults'
require 'rudder/analytics/utils'
require 'rudder/analytics/field_parser'
require 'rudder/analytics/client'
require 'rudder/analytics/worker'
require 'rudder/analytics/transport'
require 'rudder/analytics/response'
require 'rudder/analytics/logging'

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

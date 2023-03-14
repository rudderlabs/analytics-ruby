# frozen_string_literal: true

# !/usr/bin/env ruby

require 'rudder/analytics'
require 'rubygems'
require 'commander/import'
require 'time'
require 'json'
require 'yaml'

program :name, 'simulator.rb'
program :version, '0.0.1'
program :description, 'scripting simulator'

def json_hash(str)
  return JSON.parse(str) if str
end

# Run in dev with ruby -ilib bin/analytics_rudder.rb --writeKey=<write_key> --dataPlaneUrl=<data_plane_url>
# --type=track --userId=123456 --event=Test --properties={\"key_1\" => \"value_1\"} --trace

default_command :send

command :send do |c|
  c.description = 'send a Rudder message'

  c.option '--writeKey=<writeKey>', String, 'the Rudder writeKey'
  c.option '--dataPlaneUrl=<dataPlaneUrl>', String, 'the Rudder data plane URL'
  c.option '--type=<type>', String, 'The Rudder message type'

  c.option '--userId=<userId>', String, 'the user id to send the event as'
  c.option '--anonymousId=<anonymousId>', String, 'the anonymous user id to send the event as'
  c.option '--context=<context>', 'additional context for the event (JSON-encoded)'
  c.option '--integrations=<integrations>', 'additional integrations for the event (JSON-encoded)'

  c.option '--event=<event>', String, 'the event name to send with the event'
  c.option '--properties=<properties>', 'the event properties to send (JSON-encoded)'

  c.option '--name=<name>', 'name of the screen or page to send with the message'

  c.option '--traits=<traits>', 'the identify/group traits to send (JSON-encoded)'

  c.option '--groupId=<groupId>', String, 'the group id'
  c.option '--previousId=<previousId>', String, 'the previous id'

  c.action do |_, options|
    Analytics = Rudder::Analytics.new({
      :write_key => options.writeKey,
      :data_plane_url => options.dataPlaneUrl,
      :on_error => proc { |_status, msg| print msg }
    })

    case options.type
    when 'track'
      Analytics.track({
        :user_id => options.userId,
        :event => options.event,
        :anonymous_id => options.anonymousId,
        :properties => json_hash(options.properties),
        :context => json_hash(options.context),
        :integrations => json_hash(options.integrations)
      })
    when 'page'
      Analytics.page({
        :user_id => options.userId,
        :anonymous_id => options.anonymousId,
        :name => options.name,
        :properties => json_hash(options.properties),
        :context => json_hash(options.context),
        :integrations => json_hash(options.integrations)
      })
    when 'screen'
      Analytics.screen({
        :user_id => options.userId,
        :anonymous_id => options.anonymousId,
        :name => options.name,
        :properties => json_hash(options.properties),
        :context => json_hash(options.context),
        :integrations => json_hash(options.integrations)
      })
    when 'identify'
      Analytics.identify({
        :user_id => options.userId,
        :anonymous_id => options.anonymousId,
        :traits => json_hash(options.traits),
        :context => json_hash(options.context),
        :integrations => json_hash(options.integrations)
      })
    when 'group'
      Analytics.group({
        :user_id => options.userId,
        :anonymous_id => options.anonymousId,
        :group_id => options.groupId,
        :traits => json_hash(options.traits),
        :context => json_hash(options.context),
        :integrations => json_hash(options.integrations)
      })
    when 'alias'
      Analytics.alias({
        :previous_id => options.previousId,
        :user_id => options.userId,
        :anonymous_id => options.anonymousId,
        :context => json_hash(options.context),
        :integrations => json_hash(options.integrations)
      })
    else
      raise "Invalid Message Type #{options.type}"
    end
    Analytics.flush
  end
end

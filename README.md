# RudderStack Ruby SDK

## What is RudderStack?

**Short answer:** 
RudderStack is an open-source Segment alternative written in Go, built for the enterprise.

**Long answer:** 
RudderStack is a platform for collecting, storing and routing customer event data to dozens of tools. It is open-source, can run in your cloud environment (AWS, GCP, Azure or even your data-centre) and provides a powerful transformation framework to process your event data on the fly.

This repository contains the assets for `analytics-ruby-rudder`, a Ruby client for [RudderStack](https://rudderstack.com/)

## Installation

Into Gemfile from rubygems.org:

```ruby
gem 'rudder-sdk-ruby'
```

Into environment gems from rubygems.org:

```
gem install 'rudder-sdk-ruby'
```

## Usage

Create an instance of the Analytics object:

```ruby
analytics = Rudder::Analytics.new({write_key: 'WRITE_KEY', data_plane_url: 'DATA_PLANE_URL', ssl: <true/false depending on url>})
```

Identify the user for the people section, see more [here](https://segment.com/docs/libraries/ruby/#identify).

```ruby
require 'rudder-sdk-ruby'

analytics.identify(user_id: 42,
                   traits: {
                     email: 'name@example.com',
                     first_name: 'Foo',
                     last_name: 'Bar'
                   })
```

Alias an user, see more [here](https://segment.com/docs/libraries/ruby/#alias).

```ruby
analytics.alias(user_id: 41)
```

Track a user event, see more [here](https://segment.com/docs/libraries/ruby/#track).

```ruby
analytics.track(user_id: 42, event: 'Created Account')
```

There are a few calls available, please check the documentation section.

## Documentation

For detailed information on how to set up and use this SDK, please refer to our [documentation](https://docs.rudderstack.com/rudderstack-sdk-integration-guides/rudderstack-ruby-sdk)

### Test Queue

You can use the `stub` option to `Rudder::Analytics.new` to cause all requests to be stubbed, making it easier to test with this library.

## Contact Us
If you come across any issues while configuring or using RudderStack, please feel free to [contact us](https://rudderstack.com/contact/) or start a conversation on our [Slack](https://resources.rudderstack.com/join-rudderstack-slack) channel. We will be happy to help you.

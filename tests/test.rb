require 'analytics-ruby-rudder'
require 'pry'
require 'thread'

#similar to test script under bin/  
# ruby -Ilib tests/test.rb

analytics = Rudder::Analytics.new({
  write_key: '1TxsTCJuieAGskMK7fMLbuUuMYA',
  data_plane_url: 'http://localhost:8080',
  on_error: Proc.new { |status, msg| print msg }
})

#binding.pry

t = Thread.new{analytics.identify(
  user_id: '019mr8mf4r',
  traits: { email: 'sumanth', friends: 872 },
  context: {ip: '8.8.8.8'}
)
analytics.track(
  user_id: 'f4ca124298',
  event: 'Article Bookmarked',
  properties: {
    title: 'Snow Fall',
    subtitle: 'The Avalance at Tunnel Creek',
    author: 'John Branch'
  })
analytics.page(
    user_id: 'user_id',
    category: 'Docs',
    name: 'Ruby library',
    properties: { url: 'https://test_page.in' })
sleep 10000
}

t.join
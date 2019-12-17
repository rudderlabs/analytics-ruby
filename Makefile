
# Install any tools required to build this library, e.g. Ruby, Bundler etc.
bootstrap:
	brew install ruby
	gem install bundler

# Install any library dependencies.
dependencies:
	bundle install --verbose

# Run all tests and checks (including linters).
check: install  # Installation required for testing binary
	bundle exec rake
	sh .buildscript/e2e.sh

# Compile the code and produce any binaries where applicable.
build:
	rm -f rudderanalytics-ruby-*.gem
	gem build ./rudderanalytics-ruby.gemspec

install: build
	gem install rudderanalytics-ruby-*.gem

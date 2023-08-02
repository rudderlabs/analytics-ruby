# frozen_string_literal: true

require 'spec_helper'

module Rudder
  class Analytics
    describe Transport do
      subject {
        described_class.new(
          Configuration.new({ :write_key => 'write_key', :data_plane_url => 'data_plane_url' })
        )
      }
      before do
        # Try and keep debug statements out of tests
        allow(subject.logger).to receive(:error)
        allow(subject.logger).to receive(:debug)
      end

      describe '#initialize' do
        let!(:net_http) { Net::HTTP.new(anything, anything) }
        let!(:config) do
          Configuration.new({
            :write_key => 'write_key',
            :data_plane_url => 'data_plane_url',
            :ssl => false
          })
        end

        before do
          allow(Net::HTTP).to receive(:new) { net_http }
        end

        it 'sets an initalized Net::HTTP read_timeout' do
          expect(net_http).to receive(:use_ssl=)
          described_class.new(config)
        end

        it 'sets an initalized Net::HTTP read_timeout' do
          expect(net_http).to receive(:read_timeout=)
          described_class.new(config)
        end

        it 'sets an initalized Net::HTTP open_timeout' do
          expect(net_http).to receive(:open_timeout=)
          described_class.new(config)
        end

        it 'sets the http client' do
          expect(subject.instance_variable_get(:@http)).to_not be_nil
        end

        context 'no options are set' do
          it 'sets a default path' do
            path = subject.instance_variable_get(:@path)
            expect(path).to eq(described_class::PATH)
          end

          it 'sets a default retries' do
            retries = subject.instance_variable_get(:@retries)
            expect(retries).to eq(described_class::RETRIES)
          end

          it 'sets a default backoff policy' do
            backoff_policy = subject.instance_variable_get(:@backoff_policy)
            expect(backoff_policy).to be_a(Rudder::Analytics::BackoffPolicy)
          end
        end

        context 'options are given' do
          let(:path) { '/v1/batch' }
          let(:retries) { 10 }
          let(:backoff_policy) { FakeBackoffPolicy.new([1, 2, 3]) }
          let(:config) do
            Configuration.new({
              :backoff_policy => backoff_policy,
              :data_plane_url => 'http://localhost:8080/v1/batch',
              :write_key => 'write_key',
              :ssl => false,
              :gzip => false
            })
            end

          subject { described_class.new(config) }

          it 'sets passed in path' do
            expect(subject.instance_variable_get(:@path)).to eq(path)
          end

          it 'sets passed in retries' do
            expect(subject.instance_variable_get(:@retries)).to eq(retries)
          end

          it 'sets false in ssl' do
            expect(net_http).to receive(:use_ssl=).with(false)
            described_class.new(config)
          end

          it 'sets false in gzip' do
            expect(subject.instance_variable_get(:@gzip)).to eq(false)
          end

          it 'sets passed in backoff backoff policy' do
            expect(subject.instance_variable_get(:@backoff_policy))
              .to eq(backoff_policy)
          end
        end
      end

      describe '#send' do
        let(:response) {
          Net::HTTPResponse.new(http_version, status_code, response_body)
        }
        let(:http_version) { 1.1 }
        let(:status_code) { 200 }
        let(:response_body) { {}.to_json }
        let(:write_key) { 'abcdefg' }
        let(:batch) { MessageBatch.new({}) }

        before do
          http = subject.instance_variable_get(:@http)
          allow(http).to receive(:start)
          allow(http).to receive(:request) { response }
          allow(response).to receive(:body) { response_body }
        end

        it 'initalizes a new Net::HTTP::Post with path and default headers' do
          path = subject.instance_variable_get(:@path)
          default_headers = {
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
            'Content-Encoding' => 'gzip'
          }
          expect(Net::HTTP::Post).to receive(:new).with(
            path, default_headers
          ).and_call_original

          subject.send(write_key, batch)
        end

        it 'adds basic auth to the Net::HTTP::Post' do
          expect_any_instance_of(Net::HTTP::Post).to receive(:basic_auth)
            .with(write_key, nil)

          subject.send(write_key, batch)
        end

        # context 'with a stub' do
        #   before do
        #     allow(described_class).to receive(:stub) { true }
        #   end

        #   it 'returns a 200 response' do
        #     expect(subject.send(write_key, batch).status).to eq(200)
        #   end

        #   it 'has a nil error' do
        #     expect(subject.send(write_key, batch).error).to be_nil
        #   end

        #   it 'logs a debug statement' do
        #     expect(subject.logger).to receive(:debug).with(/stubbed request to/)
        #     subject.send(write_key, batch)
        #   end
        # end

        context 'a real request' do
          RSpec.shared_examples('retried request') do |status_code, body|
            let(:status_code) { status_code }
            let(:body) { body }
            let(:retries) { 4 }
            let(:backoff_policy) { FakeBackoffPolicy.new([1000, 1000, 1000]) }
            let(:config) {
              Configuration.new({
                :backoff_policy => backoff_policy,
                :data_plane_url => 'http://localhost:8080/v1/batch',
                :write_key => 'write_key',
                :retries => retries
              })
            }
            subject {
              described_class.new(config)
            }

            it 'retries the request' do
              expect(subject)
                .to receive(:sleep)
                .exactly(retries - 1).times
                .with(1)
                .and_return(nil)
              subject.send(write_key, batch)
            end
          end

          RSpec.shared_examples('non-retried request') do |status_code, body|
            let(:status_code) { status_code }
            let(:body) { body }
            let(:retries) { 4 }
            let(:backoff) { 1 }
            let(:config) {
              Configuration.new({
                :data_plane_url => 'http://localhost:8080/v1/batch',
                :write_key => 'write_key',
                :retries => retries,
                :backoff => backoff
              })
            }
            subject { described_class.new(config) }

            it 'does not retry the request' do
              expect(subject)
                .to receive(:sleep)
                .never
              subject.send(write_key, batch)
            end
          end

          context 'request is successful' do
            let(:status_code) { 201 }
            let(:error) { {}.to_json }
            it 'returns a response code' do
              expect(subject.send(write_key, batch).status).to eq(status_code)
            end

            it 'returns a nil error' do
              expect(subject.send(write_key, batch).error).to eq(error)
            end
          end

          context 'request results in errorful response' do
            let(:error) { 'this is an error' }
            let(:response_body) { { error: error }.to_json }

            it 'returns the parsed error' do
              expect(subject.send(write_key, batch).error).to eq(response_body)
            end
          end

          context 'a request returns a failure status code' do
            # Server errors must be retried
            it_behaves_like('retried request', 500, '{}')
            it_behaves_like('retried request', 503, '{}')

            # All 4xx errors other than 429 (rate limited) must be retried
            it_behaves_like('retried request', 429, '{}')
            it_behaves_like('non-retried request', 404, '{}')
            it_behaves_like('non-retried request', 400, '{}')
          end
        end
      end
    end
  end
end

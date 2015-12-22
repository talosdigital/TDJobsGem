require 'spec_helper'

describe TD::Jobs do
  it 'has a version number' do
    expect(TD::Jobs::VERSION).not_to be nil
  end

  describe '.configure' do
    it 'sets base_url from within a block' do
      base_url = 'http://an.url.com'
      TD::Jobs.configure do |config|
        config.base_url = base_url
      end
      expect(TD::Jobs.configuration.base_url).to eq base_url
    end

    it 'sets application_secret from within a block' do
      application_secret = 'v3ry_53cr37'
      TD::Jobs.configure do |config|
        config.application_secret = application_secret
      end
      expect(TD::Jobs.configuration.application_secret).to eq application_secret
    end

    it 'calls all registered on_configure listeners' do
      was_called = false
      TD::Jobs.on_configure do
        was_called = true
      end
      TD::Jobs.configure do |config|
        # Many configs.
      end
      expect(was_called).to be true
    end
  end

  describe '#'
end

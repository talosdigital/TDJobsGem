require 'singleton'

module TD
  module Jobs
    # For a block { |config| ... }
    # @yield [config] passes the Configuration object.
    # @yieldparam config the Configuration object to be configured.
    # @see Configuration
    # @example Configure Task Flex
    #   TaskFlex.configure do |config|
    #     config.autoinvite = false
    #     config.auto_close_jobs = false
    #   end
    def self.configure
      yield Configuration.instance if block_given?
      Configuration.instance.listeners.each { |listener| listener.call }
    end

    # @return the current Configuration.
    def self.configuration
      Configuration.instance
    end

    def self.on_configure(&block)
      Configuration.instance.add_listener block
    end

    # Contains all configuration options and accessors.
    class Configuration
      include Singleton

      # The configuration options array. It's used to generate all the writers.
      CONFIG_OPTIONS = [:base_url, :application_secret]

      # @!attribute base_url
      # @return [String] sets the requests base url.

      # @!attribute application_secret
      # @return [String] sets the application secret.

      attr_writer(*CONFIG_OPTIONS)

      def initialize
        @listeners = []
      end

      def add_listener(listener_lambda)
        @listeners << listener_lambda
      end

      def listeners
        @listeners
      end

      # Defaults to false
      # @return [Boolean] whether auto_send_invitation is active or not.
      def base_url
        @base_url
      end

      # Defaults to nil
      # @return [String] the application secret which allows other applications to make requests.
      def application_secret
        @application_secret
      end
    end
  end
end

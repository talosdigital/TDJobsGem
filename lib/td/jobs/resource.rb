require 'httparty'

module TD
  module Jobs
    class Resource
      include HTTParty
      TD::Jobs.on_configure do
      	headers 'Application-Secret' => TD::Jobs::configuration.application_secret
      end

      def self.valid_id?(id)
        begin
          return Integer(id)
        rescue ArgumentError
          return false
        end
      end
    end
  end
end

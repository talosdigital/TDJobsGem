require 'active_support/core_ext/hash'

module TD
  module Jobs
    class Invitation < TD::Jobs::Resource
      include TD::Core::Helpers::Object

      TD::Jobs.on_configure do
        base_uri "#{TD::Jobs::configuration.base_url}/invitations"
      end

      ACCESSIBLE_ATTRS = [:id, :provider_id, :job, :job_id, :description]
      PROTECTED_ATTRS = [:status, :created_at]
      ATTRS = ACCESSIBLE_ATTRS + PROTECTED_ATTRS
      attr_accessor(*ACCESSIBLE_ATTRS)
      attr_reader(*PROTECTED_ATTRS)

      def initialize(attrs = {})
        return unless attrs.is_a?(Hash)
        inv_attrs = attrs.symbolize_keys
        ATTRS.each do |attr|
          value = inv_attrs[attr]
          value = Job.new(inv_attrs[:job]) if attr == :job
          instance_variable_set("@#{attr}", value)
        end
      end

      # Creates a new invitation with the given attributes.
      # @param attrs [Hash] the properties to create an invitation with.
      # @option attrs [String] :provider_id The id of the provider. (required)
      # @option attrs [Integer] :job_id The id of the job the invitation is created for. (required)
      # @option attrs [String] :description The description for the invitation.
      # @return [Invitation] the created invitation.
      # @raise [TD::Jobs::WrongAttributes] if the TDJobs server responds with a 400.
      # @raise [TD::Jobs::EntityNotFound] if the TDJobs server responds with a 404.
      def self.create(attrs)
        response_obj = post('', body: attrs)
        parsed_response = response_obj.parsed_response
        raise WrongAttributes, parsed_response['error'] if response_obj.code == 400
        raise EntityNotFound, parsed_response['error'] if response_obj.code == 404
        return Invitation.new(parsed_response)
      end

      # Finds an invitation given its id.
      # @param id [Integer] the id of the invitation to find.
      # @return [Invitation] the invitation found with the given id.
      # @raise [TD::Jobs::EntityNotFound] if the TDJobs server responds with a 404.
      def self.find(id)
        response_obj = get("/#{id}")
        parsed_response = response_obj.parsed_response
        raise EntityNotFound, parsed_response['error'] if response_obj.code == 404
        return Invitation.new(parsed_response)
      end

      # Finds all invitations matching the parameters.
      # @param params [Hash] the parameters to search the invitations with.
      # @option params [String] :provider_id The id of the provider.
      # @option params [Integer] :job_id The id of the job the invitation is for.
      # @option params [String] :status The status of the invitation, can be a single String or an
      #   Array of Strings.
      # @option params [String] :created_at_from The lower limit for the creation date of the
      #   invitation.
      # @option params [String] :created_at_to The upper limit for the creation date of the
      #   invitation.
      # @return [Array<Invitation>] all matching invitations.
      def self.search(query)
        response_obj = get('', query: query)
        parsed_response = response_obj.parsed_response
        return parsed_response.map { |invitation_attrs| Invitation.new invitation_attrs }
      end

      # Finds all invitations matching the parameters and arranges the results according to the
      #   given pagination parameters.
      # @param query [Hash] the parameters to search the invitation with.
      # @option query [String] :provider_id The id of the provider.
      # @option query [Integer] :job_id The id of the job the offer is for.
      # @option query [String] :status The status of the offer, can be a single String or an Array
      #   of Strings.
      # @option query [String] :created_at_from The lower limit for the creation date of the offer.
      # @option query [String] :created_at_to The upper limit for the creation date of the offer.
      # @option query [String] :job_filter The filters each offer job should meet.
      # @param page [Integer] page of results to be shown.
      # @param per_page [Integer] items per page to be shown.
      # @return [Array<Invitation>] all matching invitations.
      def self.paginated_search(query, page = nil, per_page = nil)
        params = query
        params[:page] = page if page
        params[:per_page] = per_page if per_page
        response_obj = get("/pagination", query: params)
        parsed_response = response_obj.parsed_response
        raise WrongAttributes, parsed_response['error'] if response_obj.response.code == '400'
        parsed_response['invitations'].map! { |offer_attrs| Invitation.new offer_attrs }
        parsed_response
      end

      # Sends the given invitation.
      # @param id [Integer] the id of the invitation to be sent.
      # @return [Invitation] the sent invitation.
      # @raise [TD::Jobs::EntityNotFound] if the given id doesn't correspond to any invitation.
      # @raise [TD::Jobs::InvalidStatus] if the given invitation can't be sent.
      def self.send(id)
        make_status_request(id, :send)
      end

      # Withdraws the given invitation.
      # @param id [Integer] the id of the invitation to be withdrawn.
      # @return [Invitation] the withdrawn invitation.
      # @raise [TD::Jobs::EntityNotFound] if the given id doesn't correspond to any invitation.
      # @raise [TD::Jobs::InvalidStatus] if the given invitation can't be withdrawn.
      def self.withdraw(id)
        make_status_request(id, :withdraw)
      end

      # Accepts the given invitation.
      # @param id [Integer] the id of the invitation to be accepted.
      # @return [Invitation] the accepted invitation.
      # @raise [TD::Jobs::EntityNotFound] if the given id doesn't correspond to any invitation.
      # @raise [TD::Jobs::InvalidStatus] if the given invitation can't be accepted.
      def self.accept(id)
        make_status_request(id, :accept)
      end

      # Rejects the given invitation.
      # @param id [Integer] the id of the invitation to be rejected.
      # @return [Invitation] the rejected invitation.
      # @raise [TD::Jobs::EntityNotFound] if the given id doesn't correspond to any invitation.
      # @raise [TD::Jobs::InvalidStatus] if the given invitation can't be rejected.
      def self.reject(id)
        make_status_request(id, :reject)
      end

      # Makes a put status request to the given URL
      # @param id [Integer] the id of the invitation to be updated
      # @param action [String] the request target action.
      # @return [Invitation] an instance of Invitation with the response properties.
      # @raise [TD::Jobs::EntityNotFound] if server returns 404.
      # @raise [TD::Jobs::InvalidStatus] if server returns 400.
      def self.make_status_request(id, action)
        raise WrongAttributes, 'id has to be an integer.' unless valid_id? id
        response_obj = put("/#{id}/#{action.to_s}")
        parsed_response = response_obj.parsed_response
        case response_obj.code
        when 400 then raise InvalidStatus, parsed_response['error']
        when 404 then raise EntityNotFound, parsed_response['error']
        end
        return Invitation.new(parsed_response)
      end

      private_class_method :make_status_request

      # Takes the current instance attributes values and send them to create an Invitation.
      # @return [Boolean] true if the invitation was successfully created.
      # @raise [TD::Jobs::WrongAttributes] if the TDJobs server responds with a 400.
      # @raise [TD::Jobs::EntityNotFound] if the TDJobs server responds with a 404.
      def create
        copy self.class.create(to_hash_without_nils)
        true
      end

      # Sends the invitation with the current instance id.
      # @return [Boolean] true if the invitation was successfully sent.
      # @raise [TD::Jobs::EntityNotFound] if the given id doesn't correspond to any invitation.
      # @raise [TD::Jobs::InvalidStatus] if the given invitation can't be sent.
      def send
        copy self.class.send(@id)
        true
      end

      # Withdraws the invitation with the current instance id.
      # @return [Boolean] true if the invitation was successfully withdrawn.
      # @raise [TD::Jobs::EntityNotFound] if the given id doesn't correspond to any invitation.
      # @raise [TD::Jobs::InvalidStatus] if the given invitation can't be withdrawn.
      def withdraw
        copy self.class.withdraw(@id)
        true
      end

      # Accepts the invitation with the current instance id.
      # @return [Boolean] true if the invitation was successfully accepted.
      # @raise [TD::Jobs::WrongAttributes] if the TDJobs server responds with a 400.
      # @raise [TD::Jobs::EntityNotFound] if the TDJobs server responds with a 404.
      def accept
        copy self.class.accept(@id)
        true
      end

      # Rejects the invitation with the current instance id.
      # @return [Boolean] true if the invitation was successfully rejected.
      # @raise [TD::Jobs::WrongAttributes] if the TDJobs server responds with a 400.
      # @raise [TD::Jobs::EntityNotFound] if the TDJobs server responds with a 404.
      def reject
        copy self.class.reject(@id)
        true
      end
    end
  end
end

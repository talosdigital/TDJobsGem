module TD
  module Jobs

  # Contains all the wrapper methods for the Jobs resource.
    class Offer < TD::Jobs::Resource
      include TD::Core::Helpers::Object

      TD::Jobs.on_configure do
        base_uri "#{TD::Jobs::configuration.base_url}/offers"
      end

      ATTRS = [:id, :status, :job, :provider_id, :invitation_id, :invitation, :description,
               :metadata, :records]
      attr_accessor *ATTRS

      def initialize(attrs = {})
        return unless attrs.is_a?(Hash)
        offer_attrs = attrs.symbolize_keys
        ATTRS.each do |attr|
          value = offer_attrs[attr]
          if(value.instance_of? Hash)
            case attr
            when :job
              value = Job.new(offer_attrs[:job])
            when :invitation
              value = Invitation.new(offer_attrs[:invitation])
              instance_variable_set("@invitation_id", value.id)
            end
          end
          instance_variable_set("@#{attr}", value)
        end
      end

      # Creates an Offer.
      # @param attrs [Hash] the Offer's attributes.
      # @option attrs [Fixnum] :job_id the id of the Job the Offer references.
      # @option attrs [Fixnum] :invitation_id the id of the Invitation the Offer references.
      # @option attrs [String] :provider_id the id of the external provider the Offer belongs to.
      # @option attrs [String] :description the Offer's description.
      # @option attrs [JSON] :metadata the Offer's metadata.
      # @raise [WrongAttributes] if any of the attrs is not valid.
      # @return [Offer] the created Offer.
      def self.create(attrs)
        body = attrs.except(:job)
        body[:job_id] = attrs[:job].id if attrs[:job]
        response_obj = post('', body: body)
        parsed_response = response_obj.parsed_response.symbolize_keys
        raise WrongAttributes, parsed_response[:error] if response_obj.response.code == '400'
        raise EntityNotFound, parsed_response[:error] if response_obj.response.code == '404'
        offer = Offer.new(parsed_response.except(:job))
        offer_job = TD::Jobs::Job.new(parsed_response[:job])
        offer.job = offer_job
        return offer
      end

      # Finds an Offer.
      # @param [Integer] id the Offer's id.
      # @return [Offer] the found Offer.
      # @raise [EntityNotFound] when the id is not valid.
      def self.find(id)
        raise WrongAttributes, 'id has to be an integer.' unless valid_id? id
        response_obj = get("/#{id}")
        parsed_response = response_obj.parsed_response.symbolize_keys
        raise EntityNotFound, parsed_response[:error] if response_obj.response.code == '404'
        return Offer.new(parsed_response)
      end

      # Finds all offers matching the parameters.
      # @param query [Hash] the parameters to search the offer with.
      # @option query [String] :provider_id The id of the provider.
      # @option query [Integer] :job_id The id of the job the offer is for.
      # @option query [String] :status The status of the offer, can be a single String or an Array of Strings.
      # @option query [String] :created_at_from The lower limit for the creation date of the offer.
      # @option query [String] :created_at_to The upper limit for the creation date of the offer.
      # @option query [String] :job_filter The filters each offer job should meet.
      # @return [Array<Offer>] all matching offers.
      def self.search(query)
        response_obj = get('', query: query)
        parsed_response = response_obj.parsed_response
        raise WrongAttributes, parsed_response[:error] if response_obj.response.code == '400'
        return parsed_response.map do |offer_attrs|
          Offer.new offer_attrs
        end
      end

      # Finds all offers matching the parameters and arranges the results according to the given
      #   pagination parameters.
      # @param query [Hash] the parameters to search the offer with.
      # @option query [String] :provider_id The id of the provider.
      # @option query [Integer] :job_id The id of the job the offer is for.
      # @option query [String] :status The status of the offer, can be a single String or an Array of Strings.
      # @option query [String] :created_at_from The lower limit for the creation date of the offer.
      # @option query [String] :created_at_to The upper limit for the creation date of the offer.
      # @option query [String] :job_filter The filters each offer job should meet.
      # @param page [Integer] page of results to be shown.
      # @param per_page [Integer] items per page to be shown.
      # @return [Array<Offer>] all matching offers.
      def self.paginated_search(query, page = nil, per_page = nil)
        params = query
        params[:page] = page if page
        params[:per_page] = per_page if per_page
        response_obj = get("/pagination", query: params)
        parsed_response = response_obj.parsed_response
        raise WrongAttributes, parsed_response['error'] if response_obj.response.code == '400'
        parsed_response['offers'].map! { |offer_attrs| Offer.new offer_attrs }
        parsed_response
      end

      # Sends the given Offer
      # @param [Fixnum] id the Offer to be sent.
      # @return [Offer] the sent Offer.
      # @raise [EntityNotFound] if the given id doesn't correspond to any offer.
      # @raise [InvalidStatus] if the given offer can't be sent.
      # @raise [WrongAttributes] if the given id is not an integer.
      def self.send(id)
        make_status_request(id, :send)
      end

      # Resends the given Offer
      # @param [Fixnum] id the Offer to be resent.
      # @param [Hash] attrs the parameters to resend the offer.
      # @option attrs [String] :reason The reason for resending the offer.
      # @option attrs [String] :metadata The new offer metadata for resending the offer.
      # @return [Offer] the resent Offer.
      # @raise [EntityNotFound] if the given id doesn't correspond to any offer.
      # @raise [InvalidStatus] if the given offer can't be resent.
      # @raise [WrongAttributes] if the given id is not an integer.
      def self.resend(id, attrs)
        make_status_request(id, :resend, { reason: attrs[:reason], metadata: attrs[:metadata] })
      end

      # Withdraws the given Offer
      # @param [Fixnum] id the Offer to be withdrawn.
      # @return [Offer] the withdrawn Offer.
      # @raise [EntityNotFound] if the given id doesn't correspond to any offer.
      # @raise [InvalidStatus] if the given offer can't be withdrawn.
      # @raise [WrongAttributes] if the given id is not an integer.
      def self.withdraw(id)
        make_status_request(id, :withdraw)
      end

      # Returns the given Offer
      # @param [Fixnum] id the Offer to be returned.
      # @param [Hash] attrs the parameters to return the offer.
      # @option attrs [String] :reason The reason for returning the offer.
      # @return [Offer] the returned Offer.
      # @raise [EntityNotFound] if the given id doesn't correspond to any offer.
      # @raise [InvalidStatus] if the given offer can't be returned.
      # @raise [WrongAttributes] if the given id is not an integer.
      def self.return(id, attrs)
        make_status_request(id, :return, reason: attrs[:reason])
      end

      # Accepts the given Offer
      # @param [Fixnum] id the Offer to be accepted.
      # @return [Offer] the accepted Offer.
      # @raise [EntityNotFound] if the given id doesn't correspond to any offer.
      # @raise [InvalidStatus] if the given offer can't be accepted.
      # @raise [WrongAttributes] if the given id is not an integer.
      def self.accept(id)
        make_status_request(id, :accept)
      end

      # Rejects the given Offer
      # @param [Fixnum] id the Offer to be rejected.
      # @return [Offer] the rejected Offer.
      # @raise [EntityNotFound] if the given id doesn't correspond to any offer.
      # @raise [InvalidStatus] if the given offer can't be rejected.
      # @raise [WrongAttributes] if the given id is not an integer.
      def self.reject(id)
        make_status_request(id, :reject)
      end

      # Makes a status change request for offer with the given id.
      # @param id [Integer] the id of the offer to be deactivated.
      # @param action [Integer] the endpoint to make the request.
      # @return [Offer] the offer whose status changed.
      # @raise [EntityNotFound] if the given id doesn't correspond to any offer.
      # @raise [InvalidStatus] if the given offer can't be deactivated.
      # @raise [WrongAttributes] if the given id is not an integer.
      def self.make_status_request(id, action, body = nil)
        raise WrongAttributes, 'id has to be an integer.' unless valid_id? id
        response_obj = put("/#{id}/#{action.to_s}", body: body)
        parsed_response = response_obj.parsed_response
        raise InvalidStatus, parsed_response['error'] if response_obj.response.code == '400'
        raise EntityNotFound, parsed_response['error'] if response_obj.response.code == '404'
        return Offer.new(parsed_response)
      end

      # Takes the current instance attributes values and send them to create an Offer.
      # @return [Boolean] true if the offer was successfully created.
      # @raise [TD::Jobs::WrongAttributes] if the TDJobs server responds with a 400.
      # @raise [TD::Jobs::EntityNotFound] if the TDJobs server responds with a 404.
      def create
        attrs = to_hash_without_nils
          .except(:job)
          .merge({ job_id: job.id })
        copy self.class.create(attrs)
        true
      end

      # Sends the offer with the current instance id.
      # @return [Boolean] true if the offer was sent.
      # @raise [TD::Jobs::EntityNotFound] if the given id doesn't correspond to any offer.
      # @raise [TD::Jobs::InvalidStatus] if the given offer can't be sent.
      def send
        copy self.class.send(@id)
        true
      end

      # Resends the offer with the current instance id.
      # @param reason [String] The reason for resending the offer.
      # @return [Boolean] true if the offer was resent.
      # @raise [TD::Jobs::EntityNotFound] if the given id doesn't correspond to any offer.
      # @raise [TD::Jobs::InvalidStatus] if the given offer can't be resent.
      def resend(reason = nil)
        copy self.class.resend(@id, { metadata: @metadata, reason: reason })
        true
      end

      # Withdraws the offer with the current instance id.
      # @return [Boolean] true if the offer was withdrawn.
      # @raise [TD::Jobs::EntityNotFound] if the given id doesn't correspond to any offer.
      # @raise [TD::Jobs::InvalidStatus] if the given offer can't be activated.
      def withdraw
        copy self.class.withdraw(@id)
        true
      end

      # Returns the offer with the current instance id.
      # @param reason [String] The reason for resending the offer.
      # @return [Boolean] true if the offer was returned.
      # @raise [TD::Jobs::EntityNotFound] if the given id doesn't correspond to any offer.
      # @raise [TD::Jobs::InvalidStatus] if the given offer can't be returned.
      def return(reason = nil)
        copy self.class.return(@id, reason: reason)
        true
      end

      # Accepts the offer with the current instance id.
      # @return [Boolean] true if the offer was accepted.
      # @raise [TD::Jobs::EntityNotFound] if the given id doesn't correspond to any offer.
      # @raise [TD::Jobs::InvalidStatus] if the given offer can't be accepted.
      def accept
        copy self.class.accept(@id)
        true
      end

      # Rejects the offer with the current instance id.
      # @return [Boolean] true if the offer was rejected.
      # @raise [TD::Jobs::EntityNotFound] if the given id doesn't correspond to any offer.
      # @raise [TD::Jobs::InvalidStatus] if the given offer can't be rejected.
      def reject
        copy self.class.reject(@id)
        true
      end
    end
  end
end

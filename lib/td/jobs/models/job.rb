require 'active_support/core_ext/hash'

module TD
  module Jobs

  # Contains all the wrapper methods for the Jobs resource.
    class Job < TD::Jobs::Resource
      include TD::Core::Helpers::Object

      TD::Jobs.on_configure do
        base_uri "#{TD::Jobs::configuration.base_url}/jobs"
      end

      ACCESSIBLE_ATTRS = [:id, :name, :description, :owner_id, :due_date, :invitation_only,
                          :metadata, :start_date, :finish_date]
      PROTECTED_ATTRS = [:status]
      ATTRS = ACCESSIBLE_ATTRS + PROTECTED_ATTRS
      attr_accessor(*ACCESSIBLE_ATTRS)
      attr_reader(*PROTECTED_ATTRS)

      def initialize(attrs = {})
        return unless attrs.is_a? Hash
        attrs.symbolize_keys!
        ATTRS.each do |attr|
          instance_variable_set("@#{attr}", attrs[attr])
        end
      end

      # Creates a new job with the given attributes.
      # @param attrs [Hash] the properties to create a job with.
      # @option attrs [String] :description The job's description. (required)
      # @option attrs [String] :name The job's name. (required)
      # @option attrs [String] :owner_id The id of the job's owner. (required)
      # @option attrs [Date] :due_date The job's due date. (optional)
      # @option attrs [Boolean] :invitation_only Whether the job receives offers only by
      #   invitations or not. (optional)
      # @option attrs [Hash] :metadata The job's metadata. (optional)
      # @option attrs [Date] :start_date The job's start date. (required)
      # @option attrs [Date] :finish_date The job's finish date. (required)
      # @return [Job] the created job.
      # @raise [WrongAttributes] if the given properties are invalid.
      def self.create(attrs)
        response_obj = post('', body: attrs)
        parsed_response = response_obj.parsed_response
        raise WrongAttributes, parsed_response['error'] if response_obj.response.code == '400'
        return Job.new(parsed_response)
      end

      # Finds a job given its id.
      # @param id [Integer] the id of the job to find.
      # @return [Job] the job found with the given id.
      # @raise [EntityNotFound] if no job was found with the given id.
      def self.find(id)
        raise WrongAttributes, 'id has to be an integer.' unless valid_id? id
        response_obj = get("/#{id}")
        parsed_response = response_obj.parsed_response
        raise EntityNotFound, parsed_response['error'] if response_obj.response.code == '404'
        return Job.new(parsed_response)
      end

      # Finds a job given a certain number of custom filters in a JSON.
      # @param query [String] string representation of the JSON containing the filters.
      # @return [Job::ActiveRecord_Relation] list of jobs that meet ALL the valid filters.
      # @raise [JSON::JSONError] if 'query' doesn't correspond to a valid JSON and can't be parsed.
      # @raise [TaskFlex::InvalidQuery] if no filters were given or any is invalid. Also, if an
      #   invalid modifier was used or the metadata field is not well-formed.
      # @example Allowed search modifiers.
      #   "gt"   => Greater than.
      #   "lt"   => Less than.
      #   "geq"  => Greater or equal than.
      #   "leq"  => Less or equal than.
      #   "like" => Containing the pattern.
      #   "in"   => Value in (Array)
      # @example Searching query.
      #   {
      #     "name": {
      #       "like": "a"
      #     },
      #     "owner_id": "abcdef",
      #     "status": {
      #       "in": [
      #         "CREATED",
      #         "ACTIVE"
      #       ]
      #     },
      #     "metadata": {
      #       "price": {
      #         "lt": 2.25,
      #         "geq": 2.20
      #       }
      #     }
      #   }
      #
      #   A valid result for this query filters would be:
      #   [
      #     {
      #       "id": 19,
      #       "name": "Plumber half time",
      #       "description": "I need a plumber to work in my company, only half time.",
      #       "owner_id": "heinzeabc",
      #       "due_date": null,
      #       "status": "CREATED",
      #       "created_at": "2015-07-31T19:53:36.014Z",
      #       "updated_at": "2015-08-04T18:50:11.599Z",
      #       "metadata": {
      #         "work_time": 4,
      #         "required_age": 18,
      #         "cities": [
      #           "New York",
      #           "Medellín",
      #           "Toronto"
      #         ],
      #         "price": 2.25
      #       },
      #       "invitation_only": true
      #     }
      #   ]
      def self.search(query)
        response_obj = get("/search", query: { query: query } )
        parsed_response = response_obj.parsed_response
        raise WrongAttributes, parsed_response['error'] if response_obj.response.code == '400'
        return parsed_response.map { |job_attrs| Job.new job_attrs }
      end

      # Finds jobs given a certain number of custom filters in a JSON and arranges the results
      #   according to the given pagination parameters.
      # @param query [String] string representation of the JSON containing the filters.
      # @param page [Integer] page of results to be shown.
      # @param per_page [Integer] items per page to be shown.
      # @raise (#see search)
      # @example (#see search)
      def self.paginated_search(query, page = nil, per_page = nil)
        params = { query: query }
        params[:page] = page if page
        params[:per_page] = per_page if per_page
        response_obj = get("/search/pagination", query: params)
        parsed_response = response_obj.parsed_response
        raise WrongAttributes, parsed_response['error'] if response_obj.response.code == '400'
        parsed_response['jobs'].map! { |job_attrs| Job.new job_attrs }
        parsed_response
      end

      # Updates a job with the given attributes.
      # @param id [Integer] the id of the job to be updated.
      # @param attrs [Hash] the properties to modify the job with.
      # @option attrs [String] :description The new job's description.
      # @option attrs [String] :name The new job's name.
      # @option attrs [Date] :due_date The new job's due date.
      # @option attrs [Hash] :metadata The new job's metadata.
      # @option attrs [Date] :start_date The new job's start date.
      # @option attrs [Date] :finish_date The new job's finish date.
      # @return [Job] the updated job.
      # @raise [EntityNotFound] if the given id doesn't correspond to any job.
      # @raise [WrongAttributes] if the given attributes are invalid.
      def self.update(id, attrs)
        response_obj = put("/#{id}", body: attrs)
        parsed_response = response_obj.parsed_response
        case response_obj.response.code
        when '400' then raise WrongAttributes, parsed_response['error']
        when '404' then raise EntityNotFound, parsed_response['error']
        end
        return Job.new(parsed_response)
      end

      # Activates the given job.
      # @param id [Integer] the id of the job to be activated.
      # @return [Job] the activated job.
      # @raise [EntityNotFound] if the given id doesn't correspond to any job.
      # @raise [InvalidStatus] if the given job can't be activated.
      # @raise [WrongAttributes] if the given id is not an integer.
      def self.activate(id)
        make_status_request(id, :activate)
      end

      # Deactivates the given job.
      # @param id [Integer] the id of the job to be deactivated.
      # @return [Job] the deactivated job.
      # @raise [EntityNotFound] if the given id doesn't correspond to any job.
      # @raise [InvalidStatus] if the given job can't be deactivated.
      # @raise [WrongAttributes] if the given id is not an integer.
      def self.deactivate(id)
        make_status_request(id, :deactivate)
      end

      # Closes the given job.
      # @param id [Integer] the id of the job to be closed.
      # @return [Job] the closed job.
      # @raise [EntityNotFound] if the given id doesn't correspond to any job.
      # @raise [InvalidStatus] if the given job can't be closed.
      # @raise [WrongAttributes] if the given id is not an integer.
      def self.close(id)
        make_status_request(id, :close)
      end

      # Starts the given job.
      # @param id [Integer] the id of the job to be started.
      # @return [Job] the started job.
      # @raise [EntityNotFound] if the given id doesn't correspond to any job.
      # @raise [InvalidStatus] if the given job can't be started.
      # @raise [WrongAttributes] if the given id is not an integer.
      def self.start(id)
        make_status_request(id, :start)
      end

      # Finishes the given job.
      # @param id [Integer] the id of the job to be finished.
      # @return [Job] the finished job.
      # @raise [EntityNotFound] if the given id doesn't correspond to any job.
      # @raise [InvalidStatus] if the given job can't be finished.
      # @raise [WrongAttributes] if the given id is not an integer.
      def self.finish(id)
        make_status_request(id, :finish)
      end

      # Makes a status change request for job with the given id.
      # @param id [Integer] the id of the job to be deactivated.
      # @param action [Integer] the endpoint to make the request.
      # @return [Job] the job whose status changed.
      # @raise [EntityNotFound] if the given id doesn't correspond to any job.
      # @raise [InvalidStatus] if the given job can't be deactivated.
      # @raise [WrongAttributes] if the given id is not an integer.
      def self.make_status_request(id, action)
        raise WrongAttributes, 'id has to be an integer.' unless valid_id? id
        response_obj = put("/#{id}/#{action.to_s}")
        parsed_response = response_obj.parsed_response
        raise InvalidStatus, parsed_response['error'] if response_obj.response.code == '400'
        raise EntityNotFound, parsed_response['error'] if response_obj.response.code == '404'
        return Job.new(parsed_response)
      end

      # Takes the current instance attributes values and send them to create a Job.
      # @return [Boolean] true if the job was successfully created.
      # @raise [TD::Jobs::WrongAttributes] if the TDJobs server responds with a 400.
      # @raise [TD::Jobs::EntityNotFound] if the TDJobs server responds with a 404.
      def create
        copy self.class.create(to_hash_without_nils)
        true
      end

      # Takes the current instance attributes values and send them to update the current job.
      # @return [Job] the updated job.
      # @raise [EntityNotFound] if the given id doesn't correspond to any job.
      # @raise [WrongAttributes] if the given attributes are invalid.
      def update
        copy self.class.update(@id, to_hash_without_nils)
        true
      end

      # Activates the job with the current instance id.
      # @return [Boolean] true if the job was activated.
      # @raise [TD::Jobs::EntityNotFound] if the given id doesn't correspond to any job.
      # @raise [TD::Jobs::InvalidStatus] if the given job can't be activated.
      def activate
        copy self.class.activate(@id)
        true
      end

      # Deactivates the job with the current instance id.
      # @return [Boolean] true if the job was deactivated.
      # @raise [TD::Jobs::EntityNotFound] if the given id doesn't correspond to any job.
      # @raise [TD::Jobs::InvalidStatus] if the given job can't be deactivated.
      def deactivate
        copy self.class.deactivate(@id)
        true
      end

      # Closes the job with the current instance id.
      # @return [Boolean] true if the job was closed.
      # @raise [TD::Jobs::EntityNotFound] if the given id doesn't correspond to any job.
      # @raise [TD::Jobs::InvalidStatus] if the given job can't be closed.
      def close
        copy self.class.close(@id)
        true
      end

      # Starts the job with the current instance id.
      # @return [Boolean] true if the job was started.
      # @raise [TD::Jobs::EntityNotFound] if the given id doesn't correspond to any job.
      # @raise [TD::Jobs::InvalidStatus] if the given job can't be started.
      def start
        copy self.class.start(@id)
        true
      end

      # Finishes the job with the current instance id.
      # @return [Boolean] true if the job was finished.
      # @raise [TD::Jobs::EntityNotFound] if the given id doesn't correspond to any job.
      # @raise [TD::Jobs::InvalidStatus] if the given job can't be finished.
      def finish
        copy self.class.finish(@id)
        true
      end
    end
  end
end

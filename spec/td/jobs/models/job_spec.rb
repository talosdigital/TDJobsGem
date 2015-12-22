require 'spec_helper'
require 'active_support/all'

describe TD::Jobs::Job do

  before :each do
    @job_attrs = {
      name: 'hello',
      description: 'hi',
      owner_id: Faker::Lorem.word,
      start_date: 20.days.from_now,
      finish_date: 40.days.from_now
    }
  end

  describe '.create' do
    context 'when everything is OK' do
      it 'sends a POST to /jobs and returns a Job instance' do

        new_attrs = { id: 2, status: 'CREATED' }

        response_code = double('Net::HTTPCreated')
        allow(response_code).to receive(:code).and_return('201')

        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response).and_return(@job_attrs.merge(new_attrs))

        expect(TD::Jobs::Job).to receive(:post).and_return(response_obj)
        job = TD::Jobs::Job.create(@job_attrs)
        expect(job).to be_an_instance_of(TD::Jobs::Job)
        expect(job.id).to eq new_attrs[:id]
        expect(job.status).to eq new_attrs[:status]
      end
    end

    context 'when attributes are missing' do
      it 'raises WrongAttributes' do
        response_code = double('Net::HTTPBadRequest')
        allow(response_code).to receive(:code).and_return('400')
        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response).and_return({ error: 'BOOM' })
        expect(TD::Jobs::Job).to receive(:post).and_return(response_obj)
        expect { TD::Jobs::Job.create name: 'name!' }.to raise_error TD::Jobs::WrongAttributes
      end
    end
  end

  describe '.find' do
    context 'when it\'s all just fine' do
      it 'sends a GET to /jobs/:id and returns the found job instance' do
        response_code = double('Net::HTTPOK')
        allow(response_code).to receive(:code).and_return('200')

        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response).and_return(@job_attrs)

        expect(TD::Jobs::Job).to receive(:get).and_return(response_obj)
        job = TD::Jobs::Job.find(1)
        expect(job).to be_an_instance_of(TD::Jobs::Job)
      end
    end

    context 'when the id doesn\'t exist' do
      it 'raises EntityNotFound' do
        response_code = double('Net::HTTPNotFound')
        allow(response_code).to receive(:code).and_return('404')
        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response).and_return({ error: 'BOOM' })
        expect(TD::Jobs::Job).to receive(:get).and_return(response_obj)
        expect do
          TD::Jobs::Job.find 32131
        end.to raise_error TD::Jobs::EntityNotFound
      end
    end

    context 'when the id is invalid' do
      it 'raises WrongAttributes' do
        expect do
          TD::Jobs::Job.find 'I don\'t know what an integer is'
        end.to raise_error TD::Jobs::WrongAttributes
      end
    end
  end

  describe '.search' do
    context 'when everything is ok' do
      it 'sends a GET to /jobs/search and returns the list of resulting jobs' do
        response_code = double('Net::HTTPOK')
        allow(response_code).to receive(:code).and_return('200')

        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response).and_return([@job_attrs])

        expect(TD::Jobs::Job).to receive(:get).and_return(response_obj)
        jobs = TD::Jobs::Job.search('{ "a": { "complex": { "query": true } }}')
        expect(jobs.first).to be_an_instance_of(TD::Jobs::Job)
      end
    end

    context 'when the server returns a 400' do
      it 'raises WrongAttributes' do
        response_code = double('Net::HTTPBadRequest')
        allow(response_code).to receive(:code).and_return('400')
        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response).and_return({ error: 'BOOM' })
        expect(TD::Jobs::Job).to receive(:put).and_return(response_obj)
        expect do
          TD::Jobs::Job.update(1, { due_date: 'A String, srsly?'})
        end.to raise_error TD::Jobs::WrongAttributes
      end
    end
  end

  describe '.paginated_search' do
    context 'when everything is ok' do
      it 'sends a GET to /jobs/search/pagination and returns the list of resulting jobs' do
        response_code = double('Net::HTTPOK')
        allow(response_code).to receive(:code).and_return('200')

        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response)
          .and_return({ current_page: 1, total_pages: 1, total_items: 1, jobs: [@job_attrs] }.stringify_keys)

        expect(TD::Jobs::Job).to receive(:get).and_return(response_obj)
        jobs = TD::Jobs::Job.paginated_search('{ "a": { "complex": { "query": true } }}', 1, 1)
        expect(jobs['jobs'].first).to be_an_instance_of(TD::Jobs::Job)
      end
    end

    context 'when the server returns a 400' do
      it 'raises WrongAttributes' do
        response_code = double('Net::HTTPBadRequest')
        allow(response_code).to receive(:code).and_return('400')
        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response).and_return({ error: 'BOOM' })
        expect(TD::Jobs::Job).to receive(:get).and_return(response_obj)
        expect do
          TD::Jobs::Job.paginated_search('{ "a": { "complex": { "query": true } }}', 1, 1)
        end.to raise_error TD::Jobs::WrongAttributes
      end
    end
  end

  describe '.update' do
    context 'when everything is OK' do
      it 'updates the job' do
        update_attrs = { name: 'new_name' }
        response_code = double('Net::HTTPOK')
        allow(response_code).to receive(:code).and_return('200')

        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response)
          .and_return(@job_attrs.merge(update_attrs))

        expect(TD::Jobs::Job).to receive(:put).and_return(response_obj)
        job = TD::Jobs::Job.update(1, update_attrs)
        expect(job).to be_an_instance_of(TD::Jobs::Job)
        expect(job.name).to eq update_attrs[:name]
      end
    end

    context 'when the server returns a 400' do
      it 'raises WrongAttributes' do
        response_code = double('Net::HTTPBadRequest')
        allow(response_code).to receive(:code).and_return('400')
        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response).and_return({ error: 'BOOM' })
        expect(TD::Jobs::Job).to receive(:get).and_return(response_obj)
        expect do
          TD::Jobs::Job.search('catiswalkingonthekeyboard')
        end.to raise_error TD::Jobs::WrongAttributes
      end
    end

    context 'when the server returns a 404' do
      it 'raises EntityNotFound' do
          response_code = double('Net::HTTPBadRequest')
          allow(response_code).to receive(:code).and_return('400')
          response_obj = double('Response')
          allow(response_obj).to receive(:response).and_return(response_code)
          allow(response_obj).to receive(:parsed_response).and_return({ error: 'BOOM' })
          expect(TD::Jobs::Job).to receive(:put).and_return(response_obj)
          expect do
            TD::Jobs::Job.update(1, { due_date: 'A String, srsly?' })
          end.to raise_error TD::Jobs::WrongAttributes
      end
    end
  end

  describe '.make_status_request' do
    context 'when the status can be changed' do
      it 'sends a PUT to /jobs/:id/:action and returns the updated job' do
        updated_attrs = { status: 'NEW_STATUS' }
        response_code = double('Net::HTTPOK')
        allow(response_code).to receive(:code).and_return('200')

        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response)
          .and_return(@job_attrs.merge(updated_attrs))

        expect(TD::Jobs::Job).to receive(:put).and_return(response_obj)
        job = TD::Jobs::Job.make_status_request(1, :action)
        expect(job).to be_an_instance_of(TD::Jobs::Job)
        expect(job.status).to eq updated_attrs[:status]
      end
    end

    context 'when the status can\'t be changed' do
      it 'raises InvalidStatus' do
        response_code = double('Net::HTTPBadRequest')
        allow(response_code).to receive(:code).and_return('400')
        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response).and_return({ error: 'BOOM' })
        expect(TD::Jobs::Job).to receive(:put).and_return(response_obj)
        expect do
          TD::Jobs::Job.make_status_request 1, :invalid_action
        end.to raise_error TD::Jobs::InvalidStatus
      end
    end

    context 'when the id is invalid' do
      it 'raises WrongAttributes' do
        expect do
          TD::Jobs::Job.make_status_request 'I don\'t know what an integer is', :srsly
        end.to raise_error TD::Jobs::WrongAttributes
      end
    end
  end


  describe '#create' do
    it 'sends a POST to /jobs and refreshes the instance\'s attributes' do
      new_attrs = { id: 2, status: 'CREATED' }
      created_job = TD::Jobs::Job.new(@job_attrs.merge new_attrs)
      expect(TD::Jobs::Job).to receive(:create).and_return(created_job)
      job = TD::Jobs::Job.new(@job_attrs)
      expect(job.create).to eq true
      expect(job.id).to eq new_attrs[:id]
      expect(job.status).to eq new_attrs[:status]
    end
  end

  describe '#update' do
    it 'sends a PUT to /jobs and refreshes the job\'s attributes' do
      updated_job = TD::Jobs::Job.new(@job_attrs)
      expect(TD::Jobs::Job).to receive(:update).and_return(updated_job)
      job = TD::Jobs::Job.new(@job_attrs)
      expect(job.update).to eq true
    end
  end

  describe '#activate' do
    it 'sends a PUT to /jobs/:id/deactivate and refreshes the job\'s attributes' do
      mock_job = TD::Jobs::Job.new(@job_attrs)
      expect(TD::Jobs::Job).to receive(:activate).and_return(mock_job)
      job = TD::Jobs::Job.new(@job_attrs)
      expect(job.activate).to eq true
    end
  end

  describe '#deactivate' do
    it 'sends a PUT to /jobs/:id/deactivate and refreshes the job\'s attributes' do
      mock_job = TD::Jobs::Job.new(@job_attrs)
      expect(TD::Jobs::Job).to receive(:deactivate).and_return(mock_job)
      job = TD::Jobs::Job.new(@job_attrs)
      expect(job.deactivate).to eq true
    end
  end

  describe '#close' do
    it 'sends a PUT to /jobs/:id/close and refreshes the job\'s attributes' do
      mock_job = TD::Jobs::Job.new(@job_attrs)
      expect(TD::Jobs::Job).to receive(:close).and_return(mock_job)
      job = TD::Jobs::Job.new(@job_attrs)
      expect(job.close).to eq true
    end
  end

  describe '#start' do
    it 'sends a PUT to /jobs/:id/start and refreshes the job\'s attributes' do
      mock_job = TD::Jobs::Job.new(@job_attrs)
      expect(TD::Jobs::Job).to receive(:start).and_return(mock_job)
      job = TD::Jobs::Job.new(@job_attrs)
      expect(job.start).to eq true
    end
  end

  describe '#finish' do
    it 'sends a PUT to /jobs/:id/finish and refreshes the job\'s attributes' do
      mock_job = TD::Jobs::Job.new(@job_attrs)
      expect(TD::Jobs::Job).to receive(:finish).and_return(mock_job)
      job = TD::Jobs::Job.new(@job_attrs)
      expect(job.finish).to eq true
    end
  end
end

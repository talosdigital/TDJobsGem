require 'spec_helper'

describe TD::Jobs::Offer do

  before :each do
    @offer_attrs = {
      provider_id: Faker::Lorem.word,
      job: TD::Jobs::Job.new(id: 1),
      description: 'Some desc',
      metadata: { yes: 'no' }
    }
  end

  describe '.create' do
    context 'when everything is OK' do
      it 'sends a POST to /offers and returns an Offer instance' do

        new_attrs = { id: 2, status: 'CREATED' }

        response_code = double('Net::HTTPCreated')
        allow(response_code).to receive(:code).and_return('201')

        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response)
          .and_return(
            @offer_attrs
              .merge(new_attrs)
              .merge({ job: @offer_attrs[:job].to_hash_without_nils })
          )
        expect(TD::Jobs::Offer).to receive(:post).and_return(response_obj)
        offer = TD::Jobs::Offer.create(@offer_attrs)
        expect(offer).to be_an_instance_of(TD::Jobs::Offer)
        expect(offer.id).to eq new_attrs[:id]
        expect(offer.status).to eq new_attrs[:status]
        expect(offer.job).to be_an_instance_of TD::Jobs::Job
      end
    end

    context 'when attributes are missing' do
      it 'raises WrongAttributes' do
        response_code = double('Net::HTTPBadRequest')
        allow(response_code).to receive(:code).and_return('400')
        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response).and_return({ error: 'BOOM' })
        expect(TD::Jobs::Offer).to receive(:post).and_return(response_obj)
        expect { TD::Jobs::Offer.create name: 'name!' }.to raise_error TD::Jobs::WrongAttributes
      end
    end
  end

  describe '.search' do
    context 'when query params are valid' do
      it 'returns the array of matching offers' do
        response_code = double('Net::HTTPOK')
        allow(response_code).to receive(:code).and_return('200')
        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response)
          .and_return([@offer_attrs.merge({ job: @offer_attrs[:job].to_hash_without_nils })])
        expect(TD::Jobs::Offer).to receive(:get).and_return(response_obj)
        result = TD::Jobs::Offer.search(provider_id: Faker::Lorem.word)
        expect(result.first).to be_an_instance_of TD::Jobs::Offer
      end
    end

    context 'when query params are invalid' do
      it 'raises WrongAttributes' do
        response_code = double('Net::HTTPBadRequest')
        allow(response_code).to receive(:code).and_return('400')
        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response).and_return({ error: 'BOOM' })
        expect(TD::Jobs::Offer).to receive(:get).and_return(response_obj)
        expect do
          TD::Jobs::Offer.search job_id: '*cat walks on keyboard*'
        end.to raise_error TD::Jobs::WrongAttributes
      end
    end
  end

  describe '.paginated_search' do
    context 'when everything is ok' do
      it 'sends a GET to /offers/pagination and returns the list of resulting offers' do
        response_code = double('Net::HTTPOK')
        allow(response_code).to receive(:code).and_return('200')

        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response)
          .and_return({ current_page: 1, total_pages: 1, total_items: 1,
                        offers: [@job_attrs] }.stringify_keys)
        expect(TD::Jobs::Offer).to receive(:get).and_return(response_obj)
        offers = TD::Jobs::Offer.paginated_search({ a: { complex: { query: true } } }, 1, 1)
        expect(offers['offers'].first).to be_an_instance_of(TD::Jobs::Offer)
      end
    end

    context 'when the server returns a 400' do
      it 'raises WrongAttributes' do
        response_code = double('Net::HTTPBadRequest')
        allow(response_code).to receive(:code).and_return('400')
        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response).and_return({ error: 'BOOM' })
        expect(TD::Jobs::Offer).to receive(:get).and_return(response_obj)
        expect do
          TD::Jobs::Offer.paginated_search({ a: { complex: { query: true } } }, 1, 1)
        end.to raise_error TD::Jobs::WrongAttributes
      end
    end
  end

  describe '.find' do
    context 'when the id exists' do
      it 'sends a GET to /:id and returns the Offer' do
        response_code = double('Net::HTTPOK')
        allow(response_code).to receive(:code).and_return('200')
        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response)
          .and_return(@offer_attrs.merge({ job: @offer_attrs[:job].to_hash_without_nils }))
        expect(TD::Jobs::Offer).to receive(:get).and_return(response_obj)
        result = TD::Jobs::Offer.find(1)
        expect(result).to be_an_instance_of TD::Jobs::Offer
      end
    end

    context 'when the id doesn\'t exist' do
      it 'raises EntityNotFound' do
        response_code = double('Net::HTTPNotFound')
        allow(response_code).to receive(:code).and_return('404')
        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response).and_return({ error: 'BOOM' })
        expect(TD::Jobs::Offer).to receive(:get).and_return(response_obj)
        expect do
          TD::Jobs::Offer.find 32131
        end.to raise_error TD::Jobs::EntityNotFound
      end
    end

    context 'when the id is invalid' do
      it 'raises WrongAttributes' do
        expect do
          TD::Jobs::Offer.find 'Jimmy? Jimbo?!'
        end.to raise_error TD::Jobs::WrongAttributes
      end
    end
  end



  describe '.make_status_request' do
    context 'when the status can be changed' do
      it 'sends a PUT to /offers/:id/:action and returns the updated offer' do
        updated_attrs = { status: 'NEW_STATUS' }
        response_code = double('Net::HTTPOK')
        allow(response_code).to receive(:code).and_return('200')

        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response)
          .and_return(
            @offer_attrs
              .merge({ job: @offer_attrs[:job].to_hash_without_nils })
              .merge(updated_attrs)
          )

        expect(TD::Jobs::Offer).to receive(:put).and_return(response_obj)
        job = TD::Jobs::Offer.make_status_request(1, :action)
        expect(job).to be_an_instance_of(TD::Jobs::Offer)
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
        expect(TD::Jobs::Offer).to receive(:put).and_return(response_obj)
        expect do
          TD::Jobs::Offer.make_status_request 1, :invalid_action
        end.to raise_error TD::Jobs::InvalidStatus
      end
    end

    context 'when the id is invalid' do
      it 'raises WrongAttributes' do
        expect do
          TD::Jobs::Offer.make_status_request 'I don\'t know what an integer is', :srsly
        end.to raise_error TD::Jobs::WrongAttributes
      end
    end
  end

  describe '#create' do
    it 'sends a POST to /offers and refreshes the instance\'s attributes' do
      new_attrs = { id: 2, status: 'CREATED' }
      created_offer = TD::Jobs::Offer.new(@offer_attrs.merge new_attrs)
      expect(TD::Jobs::Offer).to receive(:create).and_return(created_offer)
      offer = TD::Jobs::Offer.new(@offer_attrs)
      offer_job = TD::Jobs::Job.new(id: 1)
      expect(offer.create).to eq true
      expect(offer.id).to eq new_attrs[:id]
      expect(offer.status).to eq new_attrs[:status]
    end
  end

  describe '#send_offer' do
    it 'sends a PUT to /offers/:id/send and refreshes the offer\'s attributes' do
      mock_offer = TD::Jobs::Offer.new(id: 1)
      expect(TD::Jobs::Offer).to receive(:send).and_return(mock_offer)
      offer = TD::Jobs::Offer.new(@offer_attrs)
      offer.job = TD::Jobs::Job.new(id: 1)
      expect(offer.send).to eq true
    end
  end

  describe '#resend' do
    it 'sends a PUT to /offers/:id/send and refreshes the offer\'s attributes' do
      mock_offer = TD::Jobs::Offer.new(id: 1)
      expect(TD::Jobs::Offer).to receive(:resend).and_return(mock_offer)
      offer = TD::Jobs::Offer.new(@offer_attrs)
      offer.job = TD::Jobs::Job.new(id: 1)
      expect(offer.resend).to eq true
    end
  end

  describe '#withdraw' do
    it 'sends a PUT to /offers/:id/withdraw and refreshes the offer\'s attributes' do
      mock_offer = TD::Jobs::Offer.new(id: 1)
      expect(TD::Jobs::Offer).to receive(:withdraw).and_return(mock_offer)
      offer = TD::Jobs::Offer.new(@offer_attrs)
      offer.job = TD::Jobs::Job.new(id: 1)
      expect(offer.withdraw).to eq true
    end
  end

  describe '#return' do
    it 'sends a PUT to /offers/:id/return and refreshes the offer\'s attributes' do
      mock_offer = TD::Jobs::Offer.new(id: 1)
      expect(TD::Jobs::Offer).to receive(:return).and_return(mock_offer)
      offer = TD::Jobs::Offer.new(@offer_attrs)
      offer.job = TD::Jobs::Job.new(id: 1)
      expect(offer.return).to eq true
    end
  end

  describe '#accept' do
    it 'sends a PUT to /offers/:id/accept and refreshes the offer\'s attributes' do
      mock_offer = TD::Jobs::Offer.new(id: 1)
      expect(TD::Jobs::Offer).to receive(:accept).and_return(mock_offer)
      offer = TD::Jobs::Offer.new(@offer_attrs)
      offer.job = TD::Jobs::Job.new(id: 1)
      expect(offer.accept).to eq true
    end
  end

  describe '#reject' do
    it 'sends a PUT to /offers/:id/reject and refreshes the offer\'s attributes' do
      mock_offer = TD::Jobs::Offer.new(id: 1)
      expect(TD::Jobs::Offer).to receive(:reject).and_return(mock_offer)
      offer = TD::Jobs::Offer.new(@offer_attrs)
      offer.job = TD::Jobs::Job.new(id: 1)
      expect(offer.reject).to eq true
    end
  end
end

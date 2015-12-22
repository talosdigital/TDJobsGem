require 'spec_helper'
require 'active_support/all'
require 'faker'

describe TD::Jobs::Invitation do
  before :each do
    @id = Faker::Number.number(3).to_i
    @job = { id: @id, owner_id: Faker::Number.number(2).to_i, name: Faker::Lorem.word,
             status: 'ACTIVE', description: Faker::Lorem.sentence, due_date: nil,
             invitation_only: nil, metadata: {} }
    @invitation = { provider_id: Faker::Lorem.word, job_id: Faker::Number.number(3).to_i,
                    description: Faker::Lorem.sentence, status: 'CREATED', job: @job,
                    created_at: Date.today }
    @error = Faker::Lorem.sentence
    @inv_obj = TD::Jobs::Invitation.new(@invitation.merge(id: @id))
  end

  let(:response) { double('Response') }
  describe '.create' do
    context 'when everything is OK' do
      it 'sends a POST to /invitations and returns an Invitation instance' do
        allow(response).to receive(:code).and_return(201)
        allow(response).to receive(:parsed_response).and_return(@invitation.merge(id: @id))
        expect(TD::Jobs::Invitation).to receive(:post).and_return(response)
        invitation = TD::Jobs::Invitation.create(@invitation)
        expect(invitation).to be_an_instance_of(TD::Jobs::Invitation)
        expect(invitation.id).to eq @id
        expect(invitation.status).to eq @invitation[:status]
      end
    end

    context 'when server responds with a 400' do
      it 'raises a WrongAttributes exception' do
        allow(response).to receive(:code).and_return(400)
        allow(response).to receive(:parsed_response).and_return(error: @error)
        expect(TD::Jobs::Invitation).to receive(:post).and_return(response)
        expect { TD::Jobs::Invitation.create({}) }.to raise_error TD::Jobs::WrongAttributes
      end
    end
  end

  describe '.find' do
    context 'when server responds with a 200' do
      it 'sends a GET to /invitations/:id and returns the found invitation instance' do
        allow(response).to receive(:code).and_return(200)
        allow(response).to receive(:parsed_response).and_return(@invitation)
        expect(TD::Jobs::Invitation).to receive(:get).and_return(response)
        invitation = TD::Jobs::Invitation.find(1)
        expect(invitation).to be_an_instance_of(TD::Jobs::Invitation)
      end
    end

    context 'when server responds with a 404' do
      it 'raises an EntityNotFound exception' do
        allow(response).to receive(:code).and_return(404)
        allow(response).to receive(:parsed_response).and_return(error: @error)
        expect(TD::Jobs::Invitation).to receive(:get).and_return(response)
        expect { TD::Jobs::Invitation.find(1) }.to raise_error TD::Jobs::EntityNotFound
      end
    end
  end

  describe '.search' do
    context 'when server responds with 200 and matchings' do
      it 'returns the list of resulting invitations' do
        allow(response).to receive(:code).and_return(200)
        allow(response).to receive(:parsed_response).and_return([@invitation.merge(id: @id)])
        expect(TD::Jobs::Invitation).to receive(:get).and_return(response)
        invitations = TD::Jobs::Invitation.search(provider_id: Faker::Lorem.word, job_id: 5,
                                                  created_at_to: Date.today)
        expect(invitations.first).to be_an_instance_of(TD::Jobs::Invitation)
        expect(invitations.first.id).to eq @id
      end
    end

    context 'when server responds with 200 and no matchings' do
      it 'returns an empty array' do
        allow(response).to receive(:code).and_return(200)
        allow(response).to receive(:parsed_response).and_return([])
        expect(TD::Jobs::Invitation).to receive(:get).and_return(response)
        invitations = TD::Jobs::Invitation.search(provider_id: Faker::Lorem.word, job_id: 5,
                                                  created_at_to: Date.today)
        expect(invitations).to be_empty
      end
    end
  end

  describe '.paginated_search' do
    context 'when everything is ok' do
      it 'sends a GET to /invitations/pagination and returns the list of resulting invitations' do
        response_code = double('Net::HTTPOK')
        allow(response_code).to receive(:code).and_return('200')

        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response)
          .and_return({ current_page: 1, total_pages: 1, total_items: 1,
                        invitations: [@inv_obj] }.stringify_keys)
        expect(TD::Jobs::Invitation).to receive(:get).and_return(response_obj)
        invitations = TD::Jobs::Invitation.paginated_search({ a: { complex: { query: true } } }, 1, 1)
        expect(invitations['invitations'].first).to be_an_instance_of(TD::Jobs::Invitation)
      end
    end

    context 'when the server returns a 400' do
      it 'raises WrongAttributes' do
        response_code = double('Net::HTTPBadRequest')
        allow(response_code).to receive(:code).and_return('400')
        response_obj = double('Response')
        allow(response_obj).to receive(:response).and_return(response_code)
        allow(response_obj).to receive(:parsed_response).and_return({ error: 'BOOM' })
        expect(TD::Jobs::Invitation).to receive(:get).and_return(response_obj)
        expect do
          TD::Jobs::Invitation.paginated_search({ a: { complex: { query: true } } }, 1, 1)
        end.to raise_error TD::Jobs::WrongAttributes
      end
    end
  end

  describe '.send' do
    it 'calls .make_status_request' do
      expect(TD::Jobs::Invitation).to receive(:make_status_request).once.and_return(@inv_obj)
      TD::Jobs::Invitation.send(1)
    end
  end


  describe '.withdraw' do
    it 'calls .make_status_request' do
      expect(TD::Jobs::Invitation).to receive(:make_status_request).once.and_return(@inv_obj)
      TD::Jobs::Invitation.withdraw(1)
    end
  end


  describe '.accept' do
    it 'calls .make_status_request' do
      expect(TD::Jobs::Invitation).to receive(:make_status_request).once.and_return(@inv_obj)
      TD::Jobs::Invitation.accept(1)
    end
  end


  describe '.reject' do
    it 'calls .make_status_request' do
      expect(TD::Jobs::Invitation).to receive(:make_status_request).once.and_return(@inv_obj)
      TD::Jobs::Invitation.reject(1)
    end
  end

  describe '.make_status_request' do
    context 'when the status can be changed' do
      it 'sends a PUT to /invitations/:id/:action and returns the updated invitation' do
        allow(response).to receive(:code).and_return(200)
        allow(response).to receive(:parsed_response).and_return(@invitation.merge(id: @id))
        expect(TD::Jobs::Invitation).to receive(:put).and_return(response)
        invitation = TD::Jobs::Invitation.__send__(:make_status_request, 1, :action)
        expect(invitation).to be_an_instance_of(TD::Jobs::Invitation)
        expect(invitation.id).to eq @id
        expect(invitation.status).to eq @invitation[:status]
      end
    end

    context 'when the status can\'t be changed' do
      it 'raises an InvalidStatus exception' do
        allow(response).to receive(:code).and_return(400)
        allow(response).to receive(:parsed_response).and_return(error: @error)
        expect(TD::Jobs::Invitation).to receive(:put).and_return(response)
        expect do
          TD::Jobs::Invitation.__send__(:make_status_request, 1, :invalid_action)
        end.to raise_error TD::Jobs::InvalidStatus
      end
    end

    context 'when server responses with 404' do
      it 'raises an EntityNotFound exception' do
        allow(response).to receive(:code).and_return(404)
        allow(response).to receive(:parsed_response).and_return(error: @error)
        expect(TD::Jobs::Invitation).to receive(:put).and_return(response)
        expect do
          TD::Jobs::Invitation.__send__(:make_status_request, 1, :invalid_action)
        end.to raise_error TD::Jobs::EntityNotFound
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
    context 'when attributes are correct' do
      it 'creates the invitation and returns true' do
        expect(TD::Jobs::Invitation).to receive(:create).once.and_return(@inv_obj)
        invitation = TD::Jobs::Invitation.new(@invitation)
        expect(invitation.create).to eq true
        expect(invitation.id).to eq @id
        expect(invitation.status).to eq @invitation[:status]
      end
    end

    context 'when .create raises a WrongAttributes exception' do
      it 'raises the same EntityNotFound WrongAttributes' do
        expect(TD::Jobs::Invitation).to receive(:create).once.and_raise(TD::Jobs::WrongAttributes)
        invitation = TD::Jobs::Invitation.new(invitation)
        expect { invitation.create }.to raise_error TD::Jobs::WrongAttributes
      end
    end

    context 'when .create raises an EntityNotFound' do
      it 'raises the same EntityNotFound' do
        expect(TD::Jobs::Invitation).to receive(:create).once.and_raise(TD::Jobs::EntityNotFound)
        invitation = TD::Jobs::Invitation.new(invitation)
        expect { invitation.create }.to raise_error TD::Jobs::EntityNotFound
      end
    end
  end

  describe '#send' do
    context 'when invitation is valid and sendable' do
      it 'sends the invitation and returns true' do
        expect(TD::Jobs::Invitation).to receive(:send).once.and_return(@inv_obj)
        invitation = TD::Jobs::Invitation.new(@invitation)
        expect(invitation.send).to eq true
        expect(invitation.id).to eq @id
        expect(invitation.status).to eq @invitation[:status]
      end
    end

    context 'when .send raises a InvalidStatus exception' do
      it 'raises the same InvalidStatus' do
        expect(TD::Jobs::Invitation).to receive(:send).once
          .and_raise(TD::Jobs::InvalidStatus)
        invitation = TD::Jobs::Invitation.new(invitation)
        expect { invitation.send }.to raise_error TD::Jobs::InvalidStatus
      end
    end

    context 'when .send raises a EntityNotFound exception' do
      it 'raises the same EntityNotFound' do
        expect(TD::Jobs::Invitation).to receive(:send).once
          .and_raise(TD::Jobs::EntityNotFound)
        invitation = TD::Jobs::Invitation.new(invitation)
        expect { invitation.send }.to raise_error TD::Jobs::EntityNotFound
      end
    end
  end

  describe '#withdraw' do
    context 'when invitation is valid and withdrawable' do
      it 'withdraws the invitation and returns true' do
        expect(TD::Jobs::Invitation).to receive(:withdraw).once.and_return(@inv_obj)
        invitation = TD::Jobs::Invitation.new(@invitation)
        expect(invitation.withdraw).to eq true
        expect(invitation.id).to eq @id
        expect(invitation.status).to eq @invitation[:status]
      end
    end

    context 'when .withdraw raises a InvalidStatus exception' do
      it 'raises the same InvalidStatus' do
        expect(TD::Jobs::Invitation).to receive(:withdraw).once.and_raise(TD::Jobs::InvalidStatus)
        invitation = TD::Jobs::Invitation.new(invitation)
        expect { invitation.withdraw }.to raise_error TD::Jobs::InvalidStatus
      end
    end

    context 'when .withdraw raises a EntityNotFound exception' do
      it 'raises the same EntityNotFound' do
        expect(TD::Jobs::Invitation).to receive(:withdraw).once.and_raise(TD::Jobs::EntityNotFound)
        invitation = TD::Jobs::Invitation.new(invitation)
        expect { invitation.withdraw }.to raise_error TD::Jobs::EntityNotFound
      end
    end
  end

  describe '#accept' do
    context 'when invitation is valid and acceptable' do
      it 'accepts the invitation and returns true' do
        expect(TD::Jobs::Invitation).to receive(:accept).once.and_return(@inv_obj)
        invitation = TD::Jobs::Invitation.new(@invitation)
        expect(invitation.accept).to eq true
        expect(invitation.id).to eq @id
        expect(invitation.status).to eq @invitation[:status]
      end
    end

    context 'when .accept raises a InvalidStatus exception' do
      it 'raises the same InvalidStatus' do
        expect(TD::Jobs::Invitation).to receive(:accept).once.and_raise(TD::Jobs::InvalidStatus)
        invitation = TD::Jobs::Invitation.new(invitation)
        expect { invitation.accept }.to raise_error TD::Jobs::InvalidStatus
      end
    end

    context 'when .accept raises a EntityNotFound exception' do
      it 'raises the same EntityNotFound' do
        expect(TD::Jobs::Invitation).to receive(:accept).once.and_raise(TD::Jobs::EntityNotFound)
        invitation = TD::Jobs::Invitation.new(invitation)
        expect { invitation.accept }.to raise_error TD::Jobs::EntityNotFound
      end
    end
  end

  describe '#reject' do
    context 'when invitation is valid and rejectable' do
      it 'rejects the invitation and returns true' do
        expect(TD::Jobs::Invitation).to receive(:reject).once.and_return(@inv_obj)
        invitation = TD::Jobs::Invitation.new(@invitation)
        expect(invitation.reject).to eq true
        expect(invitation.id).to eq @id
        expect(invitation.status).to eq @invitation[:status]
      end
    end

    context 'when .reject raises a InvalidStatus exception' do
      it 'raises the same InvalidStatus' do
        expect(TD::Jobs::Invitation).to receive(:reject).once.and_raise(TD::Jobs::InvalidStatus)
        invitation = TD::Jobs::Invitation.new(invitation)
        expect { invitation.reject }.to raise_error TD::Jobs::InvalidStatus
      end
    end

    context 'when .reject raises a EntityNotFound exception' do
      it 'raises the same EntityNotFound' do
        expect(TD::Jobs::Invitation).to receive(:reject).once.and_raise(TD::Jobs::EntityNotFound)
        invitation = TD::Jobs::Invitation.new(invitation)
        expect { invitation.reject }.to raise_error TD::Jobs::EntityNotFound
      end
    end
  end
end

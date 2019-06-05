require 'rails_helper'

describe 'Api::V1::Otus', type: :request do

  let(:user) { FactoryBot.create(:valid_user, :user_valid_token) }

  context 'otu/index' do

    # let!(:otu) { Otu.create!(name: 'Foo') }
    # let(:headers) { { "Authorization": 'Token token=' + user.api_access_token, project_id: otu.project_id } }
    # let(:path) { '/api/v1/otus/' }

    it_behaves_like 'secured by both user and project token', :valid_otu, '/api/v1/otus/'

    # project token-only for now
    xcontext 'with a valid user token and project_id' do
      before { get path, headers: headers, params: { project_id: otu.project_id } }
      it_behaves_like 'a successful response'
    end

  end
end

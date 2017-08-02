require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe CollectionObjectsController, :type => :controller do
  before(:each) {
    sign_in
  }

  # This should return the minimal set of attributes required to create a valid
  # Georeference. As you add validations to Georeference be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    strip_housekeeping_attributes(FactoryGirl.build(:valid_collection_object).attributes)
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # CollectionObjectsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET list" do
    it "with no other parameters, assigns 20/page collection_objects as @collection_objects" do
      collection_object = CollectionObject.create! valid_attributes
      get :list, params: {}, session: valid_session
      expect(assigns(:collection_objects)).to include(collection_object)
    end

    it "renders the list template" do
      get :list, params: {}, session: valid_session
      expect(response).to render_template("list")
    end
  end

  describe "GET index" do
    it "assigns all collection_objects as @recent_objects" do
      collection_object = CollectionObject.create! valid_attributes
      get :index, params: {}, session: valid_session
      expect(assigns(:recent_objects)).to eq([collection_object])
    end
  end

  describe "GET show" do
    it "assigns the requested collection_object as @collection_object" do
      collection_object = CollectionObject.create! valid_attributes
      get :show, params: {id: collection_object.to_param}, session: valid_session
      expect(assigns(:collection_object)).to eq(collection_object)
    end

    context "JSON format request" do
      render_views
      let(:collection_object) do
        CollectionObject.create! valid_attributes.merge(
            {
                depictions_attributes: [
                    {
                        image_attributes: {
                            image_file: fixture_file_upload((Rails.root + 'spec/files/images/tiny.png'),
                                                            'image/png')
                        }
                    }
                ]
            }
        )
      end

      context 'valid collection_object' do
        before {get :show, params: {id: collection_object.to_param,
                                    include: ['images'],
                                    format: :json},
                    session: valid_session}
        let (:data) { JSON.parse(response.body) }

        it "returns a successful JSON response" do
          expect(data["success"]).to be true
        end

        describe "JSON data contents" do

          it "has a result object" do
            expect(data["result"]).to be_truthy
          end

          describe "result attributes" do
            let (:result) { data["result"] }

            it "has an id" do
              expect(result["id"]).to eq(collection_object.id)
            end

            it "has a type" do
              expect(result["type"]).to eq(collection_object.type)
            end

            context "when it has no images" do
              before do
                collection_object.images.delete_all
              end

              it "has images as empty array" do
                get :show, params: {id: collection_object.to_param,
                                    include: ["images"],
                                    format: :json},
                    session: valid_session
                expect(result["images"]).to eq([])
              end
            end

            context "when it has images" do

              context "when requested" do

                it "has an array of images" do
                  expect(result["images"].length).to eq(collection_object.images.size)
                end

                describe "array items attributes" do
                  let(:item) { result["images"].first }
                  let(:image) { collection_object.images.first }

                  it "has an id" do
                    expect(item["id"]).to eq(image.id)
                  end

                  it "has an API endpoint URL" do
                    expect(item["url"]).to eq(api_v1_image_url(image.to_param))
                  end
                end
              end

              context 'when not requested' do

                it 'does not have images attribute' do
                  get :show, params: {id: collection_object.to_param,
                                      format: :json},
                      session: valid_session
                  expect(JSON.parse(response.body)['result']['images']).to be nil
                end
              end
            end
          end
        end
      end

      context "invalid collection_object" do
        before {get :show, params: {id: -1, format: :json}, session: valid_session}

        it "returns an unsuccessful JSON response" do
          expect(JSON.parse(response.body)).to eq({"success" => false})
        end
      end

      context 'GET api/v1/collection_objects/n/geo_json' do
        # This is tested in the API section of spec/features/collection_objects_spec
      end

      context 'GET api/v1/collection_objects/n/images' do
        # This is tested in the API section of spec/features/collection_objects_spec
      end
    end
  end

  describe "GET by_identifier" do
    render_views
    let(:namespace) { FactoryGirl.create(:valid_namespace, short_name: 'ABCD') }
    let!(:collection_object) do
      CollectionObject.create! valid_attributes.merge(
          {identifiers_attributes: [{identifier: '123', type: 'Identifier::Local::CatalogNumber', namespace: namespace}]})
    end

    context "valid identifier" do
      before {get :by_identifier, params: {identifier: "ABCD 123", format: :json}, session: valid_session}

      let (:data) { JSON.parse(response.body) }

      it "returns a successful JSON response" do
        expect(data["success"]).to be true
      end

      describe "JSON data contents" do
        it "has a request object" do
          expect(data["request"]).to be_truthy
        end

        it "has a result object" do
          expect(data["result"]).to be_truthy
        end

        describe "request attributes" do
          let(:request) { data["request"] }

          it "has a params attribute" do
            expect(request["params"]).to be_truthy
          end

          describe "params attributes" do
            let(:params) { request["params"] }

            it "has a project_id attribute" do
              expect(params["project_id"]).to eq(1)
            end

            it "has an identifier attribute" do
              expect(params["identifier"]).to eq("ABCD 123")
            end
          end
        end

        describe "result attributes" do
          let (:result) { data["result"] }

          it "has a collection_objects array attribute" do
            expect(result["collection_objects"].length).to eq(1)
          end

          describe "collection_objects items attributes" do
            let(:item) { result["collection_objects"].first }

            it "has an id attribute" do
              expect(item["id"]).to eq(collection_object.id)
            end

            it "has an API endpoint URL" do
              expect(item["url"]).to eq(api_v1_collection_object_url(collection_object.to_param))
            end
          end
        end
      end
    end

    context "invalid identifier" do
      before {get :by_identifier, params: {identifier: "FOO", format: :json}, session: valid_session}

      it "returns 404 HTTP status" do
        expect(response.status).to eq(404)
      end

      it "returns an unsuccessful JSON response" do
        expect(JSON.parse(response.body)).to eq({"success" => false})
      end
    end

  end

  describe "GET new" do
    it "assigns a new collection_object as @collection_object" do
      get :new, params: {}, session: valid_session
      expect(assigns(:collection_object)).to be_a_new(CollectionObject)
    end
  end

  describe "GET edit" do
    it "assigns the requested collection_object as @collection_object" do
      collection_object = CollectionObject.create! valid_attributes
      get :edit, params: {id: collection_object.to_param}, session: valid_session
      expect(assigns(:collection_object)).to eq(collection_object)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new CollectionObject" do
        expect {
          post :create, params: {collection_object: valid_attributes}, session: valid_session
        }.to change(CollectionObject, :count).by(1)
      end

      it "assigns a newly created collection_object as @collection_object" do
        post :create, params: {collection_object: valid_attributes}, session: valid_session
        expect(assigns(:collection_object)).to be_a(CollectionObject)
        expect(assigns(:collection_object)).to be_persisted
      end

      it "redirects to the created collection_object" do
        post :create, params: {collection_object: valid_attributes}, session: valid_session
        expect(response).to redirect_to(CollectionObject.last.metamorphosize)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved collection_object as @collection_object" do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(CollectionObject).to receive(:save).and_return(false)
        post :create, params: {collection_object: {"total" => "invalid value"}}, session: valid_session
        expect(assigns(:collection_object)).to be_a_new(CollectionObject)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(CollectionObject).to receive(:save).and_return(false)
        post :create, params: {collection_object: {"total" => "invalid value"}}, session: valid_session
        expect(response).to render_template("new")
      end
    end
  end

  describe 'PUT update' do
    describe 'with valid params' do
      it 'updates the requested collection_object' do
        collection_object = CollectionObject.create! valid_attributes
        # Assuming there are no other collection_objects in the database, this
        # specifies that the CollectionObject created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        update_params = ActionController::Parameters.new({'total' => '1'}).permit(:total)
        expect_any_instance_of(CollectionObject).to receive(:update).with(update_params)
        put :update, params: {id: collection_object.to_param, collection_object: {'total' => '1'}}, session: valid_session
      end

      it "assigns the requested collection_object as @collection_object" do
        collection_object = CollectionObject.create! valid_attributes
        put :update, params: {id: collection_object.to_param, collection_object: valid_attributes}, session: valid_session
        expect(assigns(:collection_object)).to eq(collection_object.metamorphosize)
      end

      it "redirects to the collection_object" do
        collection_object = CollectionObject.create! valid_attributes
        put :update, params: {id: collection_object.to_param, collection_object: valid_attributes}, session: valid_session
        expect(response).to redirect_to(collection_object.becomes(CollectionObject))
      end
    end

    describe "with invalid params" do
      it "assigns the collection_object as @collection_object" do
        collection_object = CollectionObject.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(CollectionObject).to receive(:save).and_return(false)
        put :update, params: {id: collection_object.to_param, collection_object: {"total" => "invalid value"}}, session: valid_session
        expect(assigns(:collection_object)).to eq(collection_object)
      end

      it "re-renders the 'edit' template" do
        collection_object = CollectionObject.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(CollectionObject).to receive(:save).and_return(false)
        put :update, params: {id: collection_object.to_param, collection_object: {"total" => "invalid value"}}, session: valid_session
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested collection_object" do
      collection_object = CollectionObject.create! valid_attributes
      expect {
        delete :destroy, params: {id: collection_object.to_param}, session: valid_session
      }.to change(CollectionObject, :count).by(-1)
    end

    it "redirects to the collection_objects list" do
      collection_object = CollectionObject.create! valid_attributes
      delete :destroy, params: {id: collection_object.to_param}, session: valid_session
      expect(response).to redirect_to(collection_objects_url)
    end
  end

end

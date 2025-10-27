# frozen_string_literal: true
require 'hyrax/specs/shared_specs/simple_work'

RSpec.describe Hyrax::CustomQueries::FindOrCreateById, valkyrie_adapter: :test_adapter do
  subject(:query_handler) { described_class.new(query_service: Hyrax.query_service) }

  it 'has a class method' do
    expect(described_class.queries).to eq([:find_or_create_by_id])
  end
  describe '#find_or_create_by_id' do
    let!(:work) { FactoryBot.valkyrie_create(:hyrax_work, title: ['The original title']) }

    context 'with an object that exists' do
      it 'can find the work' do
        expect(query_handler.find_or_create_by_id(id: work.id, model: work.class)).to eq(work)
      end

      it 'does not update the work' do
        expect do
          query_handler.find_or_create_by_id(id: work.id, model: work.class, attrs: { title: ['My cool title'] })
        end.not_to change { work.title }
      end
    end
    context 'with an object that does not exist' do
      before do
        allow(Rails.logger).to receive(:info).and_call_original
      end

      it 'logs that it cannot find the object' do
        query_handler.find_or_create_by_id(id: '123', model: GenericWork)
        expect(Rails.logger).to have_received(:info).with("GenericWork with id of 123 not found, attempting to create")
      end
      it 'can create the work' do
        expect do
          query_handler.find_or_create_by_id(id: '123', model: GenericWork)
        end.to change { Hyrax.custom_queries.find_ids_by_model(model: GenericWork).count }.by(1)
      end

      context 'with attributes' do
        it 'applies the attributes to the object' do
          new_obj = query_handler.find_or_create_by_id(id: '123', model: GenericWork, attrs: { title: ['My cool title'] })
          expect(new_obj.title).to eq(['My cool title'])
        end
      end

      context 'with a class that does not exist' do
        it 'raises an error' do
          expect { query_handler.find_or_create_by_id(id: '123', model: ClassThatDoesNotExist) }.to raise_error(NameError)
        end
      end
    end
  end
end

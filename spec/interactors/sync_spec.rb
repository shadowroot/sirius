require 'spec_helper'
require 'interactors/sync'

describe Sync do

  describe '.[]' do

    it 'returns anonymous subclass of Sync' do
      cls = described_class[String]
      expect(cls).to be < described_class
    end

    it 'sets model_class attribute' do
      cls = described_class[String]
      expect(cls.model_class).to eq String
    end

    it 'can set key_name attribute' do
      cls = described_class[String, key_name: :foo]
      expect(cls.key_name).to eq :foo
    end

    it 'can set key_name attribute' do
      cls = described_class[String, matching_attributes: [:foo]]
      expect(cls.matching_attributes).to contain_exactly :foo
    end

    it 'plularizes model_class as default key_name' do
      cls = described_class[String]
      expect(cls.key_name).to eq :strings
    end
  end

  describe '#perform' do

    subject(:sync) { described_class[Person]}
    let(:person) { Fabricate.build(:person) }

    it 'inserts new entity' do
      expect { sync.perform({people: [person]}) }.to change(person, :new?).from(true).to(false)
    end

    context 'with existing record' do

      let(:existing_person) { Fabricate(:person, full_name: 'Dude') }
      let(:person) { Fabricate.build(:person, id: existing_person.id, full_name: 'Mr. Dude') }

      it 'updates existing entity' do
        expect do
          sync.perform({people: [person]})
          existing_person.refresh
        end.to change(existing_person, :full_name).from('Dude').to('Mr. Dude')
      end

      it 'updates updated_at timestamp' do
        expect do
          sync.perform({people: [person]})
          existing_person.refresh
        end.to change(existing_person, :updated_at)
      end

      it 'keeps created_at timestamp' do
        expect do
          sync.perform({people: [person]})
          existing_person.refresh
        end.not_to change(existing_person, :created_at)
      end

    end

    context 'with invalid input' do

      it 'raises RuntimeError' do
        expect { sync.perform({}) }.to raise_error(RuntimeError)
      end

    end

    context 'with custom key_name' do

      subject(:sync) { described_class[Person, key_name: :foo] }

      it 'accepts input from it' do
        expect { sync.perform({foo: []}) }.not_to raise_error
      end

    end

    context 'with custom matching_attributes' do

      subject(:sync) { described_class[Person, matching_attributes: [:full_name]] }
      let!(:existing_person) { Fabricate(:person, full_name: 'Pete') }
      let(:person) { Fabricate.build(:person, id: existing_person.id, full_name: 'Pete') }

      it 'looks up model according to it' do

        expect(Person).to receive(:find).with(full_name: 'Pete').and_call_original
        sync.perform({people: [person]})
      end

    end

    context 'with key-value matching_attributes' do

      subject(:sync) { described_class[ScheduleException, matching_attributes: [options: :stuff_id]] }

      let!(:existing_exception) { Fabricate(:schedule_exception, name: 'Foo', options: {stuff_id: 42})}
      let(:exception) { Fabricate.build(:schedule_exception, name: 'Bar', options: {stuff_id: 42})}
      let(:other_exception) { Fabricate.build(:schedule_exception, name: 'Bar', options: {stuff_id: 99999})}

      it 'updates correct record' do
        expect {
          sync.perform({schedule_exceptions: [exception]})
          existing_exception.refresh
        }.to change(existing_exception, :name).from('Foo').to('Bar')
      end

      it 'does not update different record' do
        expect {
          sync.perform({schedule_exceptions: [other_exception]})
          existing_exception.refresh
        }.not_to change(existing_exception, :name)
      end

    end

    it 'puts saved entities into results' do
      results = sync.perform({people: [person]}).results
      expect(results).to include people: [person]
    end

    it 'passes other data along' do
      results = sync.perform({people: [], foo: :bar}).results
      expect(results).to include foo: :bar
    end

    context 'with skip_updating' do

      let!(:person) { Fabricate(:person, full_name: 'Pete') }
      subject(:sync) { described_class[Person, skip_updating: [:full_name]] }

      it 'skips updating specified attributes' do
        person.full_name = 'Joe'
        expect do
          sync.perform({people: [person]})
          person.refresh
        end.to change(person, :full_name).from('Joe').to('Pete')
      end

    end

  end

end

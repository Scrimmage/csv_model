require 'spec_helper'

describe CSVModel::Utilities::Options do
  class ObjectWithOptions
    include CSVModel::Utilities::Options

    def initialize(options)
      @options = options
    end
  end
  
  let(:options) { double('options') }
  let(:key) { :foo }
  let(:value) { :bar }
  let(:default) { :default }
  subject { ObjectWithOptions.new(options) }

  describe '#option' do
    context 'when options responds to []' do
      before do
        allow(options).to receive(:[]).with(key).and_return(value)
      end

      it 'returns the value of [key]' do
        expect(subject.option(key)).to eq(value)
      end

      context 'and the value of [key] is nil' do
        let(:value) { nil }

        it 'returns nil when no default is specified' do
          expect(subject.option(key)).to eq(nil)
        end

        it 'returns the default value when a default is specified' do
          expect(subject.option(key, default)).to eq(default)
        end
      end
    end

    context 'when options responds to :key' do
      before do
        allow(options).to receive(key).with(no_args).and_return(value)
      end

      it 'returns the value of :key' do
        expect(subject.option(key)).to eq(value)
      end

      context 'and the value of :key is nil' do
        let(:value) { nil }

        it 'returns nil when no default is specified' do
          expect(subject.option(key)).to eq(nil)
        end

        it 'returns the default value when a default is specified' do
          expect(subject.option(key, default)).to eq(default)
        end
      end
    end

    context 'when options responds to both [] and :key' do
      before do
        allow(options).to receive(:[]).with(key).and_return(value)
        allow(options).to receive(key).with(no_args).and_return(:alt)
      end

      it 'returns the value of [key]' do
        expect(subject.option(key)).to eq(value)
      end

      context 'and the value of [key] is nil' do
        let(:value) { nil }

        it 'returns the value of :key' do
          expect(subject.option(key)).to eq(:alt)
        end
      end
    end
  end
end

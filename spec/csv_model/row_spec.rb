require 'spec_helper'

describe CSVModel::Row do

  let(:header) { double("header") }
  let(:column) { double("column", key: "column one", model_attribute: :column_one, name: "Column One") }
  let(:columns) { [column] }
  let(:primary_key_columns) { [] }

  let(:data) { ["Value One"] }
  let(:subject) { described_class.new(header, data) }

  before do
    allow(header).to receive(:columns).and_return(columns)
    allow(header).to receive(:column_index).and_return(nil)
    allow(header).to receive(:column_index).with("column one").and_return(0)
    allow(header).to receive(:primary_key_columns).and_return(primary_key_columns)
  end

  describe "#errors" do
    context "when no errors" do
      let(:model_finder) { double("model-finder") }
      let(:subject) { described_class.new(header, data, row_model_finder: model_finder) }
      let(:model_instance) { double("model-instance", changed?: false, marked_for_destruction?: false, new_record?: false, valid?: true) }

      before do
        allow(model_finder).to receive(:find_row_model).and_return(model_instance)
        allow(model_instance).to receive(:save)
      end

      it "returns an empty array when no errors" do
        expect(subject.errors).to eq([])
      end
    end

    context "when subject is a duplicate" do
      before do
        subject.mark_as_duplicate
      end

      context "during normal processing" do
        it "does not return an error" do
          expect(subject.errors).to_not include("Duplicate row")
        end
      end

      context "during a dry-run" do
        let(:subject) { described_class.new(header, data, dry_run: true) }

        it "returns an error" do
          expect(subject.errors).to include("Duplicate row")
        end

        context "when the row has a primary key" do
          let(:primary_key_columns) { [column] }

          it "returns an error specific to the column" do
            expect(subject.errors).to include("Duplicate Column One")
          end
        end
      end
    end

    context "when the model instance has errors" do
      let(:model_finder) { double("model-finder") }
      let(:subject) { described_class.new(header, data, row_model_finder: model_finder) }
      let(:model_instance) { double("model-instance", changed?: false, errors: errors, marked_for_destruction?: false, new_record?: false, valid?: false) }
      let(:errors) { ["Message one", "Message two"] }

      before do
        allow(model_finder).to receive(:find_row_model).and_return(model_instance)
      end

      it "includes the model instance errors" do
        expect(subject.errors).to eq(errors)
      end
    end
  end

  describe "#index, #[]" do
    it "returns nil when index is before than first element" do
      expect(subject.index(-1)).to eq(nil)
      expect(subject[-1]).to eq(nil)
    end

    it "returns nil when index is after than the last element" do
      expect(subject.index(data.size)).to eq(nil)
      expect(subject[data.size]).to eq(nil)
    end

    it "returns the value at the specified index" do
      expect(subject.index(0)).to eq("Value One")
      expect(subject[0]).to eq("Value One")
    end

    it "returns the value for the specified column key" do
      expect(subject.index("column one")).to eq("Value One")
      expect(subject["column one"]).to eq("Value One")
    end

    it "returns nil when the specified column key not exist" do
      expect(subject.index("column two")).to eq(nil)
      expect(subject["column two"]).to eq(nil)
    end
  end

  describe "#key" do
    it "returns the entire row if no primary key is defined" do
      expect(subject.key).to eq(data)
    end

    context "when the row has a single primary key column" do
      let(:primary_key_columns) { [column] }

      it "returns the value for the key column" do
        expect(subject.key).to eq(data.first)
      end
    end

    context "when the row has a composite key" do
      let(:columns) { [
        double("column", key: "column one"),
        double("column", key: "column two"),
        double("column", key: "column three")
      ] }
      let(:primary_key_columns) { [
        double("column", key: "column one"),
        double("column", key: "column two")
      ] }
      let(:data) { ["Value One", "Value Two", "Value Three"] }

      before do
        allow(header).to receive(:column_index).with("column two").and_return(1)
      end

      it "returns the value for the key columns" do
        expect(subject.key).to eq(["Value One", "Value Two"])
      end
    end
  end

  describe "#mark_as_duplicate" do
    it "returns true" do
      expect(subject.mark_as_duplicate).to eq(true)
    end
  end

  describe "#marked_as_duplicate?" do
    it "returns false when not marked as duplicate" do
      expect(subject.marked_as_duplicate?).to eq(false)
    end

    it "returns true when marked as duplicate" do
      subject.mark_as_duplicate
      expect(subject.marked_as_duplicate?).to eq(true)
    end
  end

  describe "#status" do
    let(:model) { double("model") }
    let(:wrapper) { double("wrapper", status: :some_status) }

    before do
      allow(subject).to receive(:find).and_return(model)
      allow(wrapper).to receive(:assign_attributes)
      allow(wrapper).to receive(:save)
    end

    it "is delegates status to the model" do
      expect(CSVModel::RowActiveRecordAdaptor).to receive(:new).and_return(wrapper)
      expect(subject.status).to eq(:some_status)
    end
  end

  describe "#valid?" do
    it "returns true if no errors" do
      expect(subject).to receive(:errors).and_return([])
      expect(subject.valid?).to eq(true)
    end

    it "returns false if errors" do
      expect(subject).to receive(:errors).and_return(["error"])
      expect(subject.valid?).to eq(false)
    end
  end

  describe "internals" do
    describe "#all_attributes" do
      it "doesn't respond to all_attributes" do
        expect(subject.respond_to?(:all_attributes)).to eq(false)
      end

      it "returns all attributes and values" do
        expect(subject.send(:all_attributes)).to eq(column_one: "Value One")
      end

      context "with a column mapping" do
        let(:model_mapper) { double("model-mapper") }
        let(:subject) { described_class.new(header, data, row_model_mapper: model_mapper) }

        before do
          allow(model_mapper).to receive(:map_all_attributes).with({ column_one: "Value One" }).and_return(mapped_key: "mapped_value")
        end

        it "maps attributes" do
          expect(subject.send(:all_attributes)).to eq(mapped_key: "mapped_value")
        end
      end

      context "with multiple columns" do
        let(:columns) { [
          double("column", key: "column one", model_attribute: :column_one),
          double("column", key: "column two", model_attribute: :column_two),
          double("column", key: "column three", model_attribute: :column_three)
        ] }
        let(:data) { ["Value One", "", "Value Three"] }

        before do
          allow(header).to receive(:column_index).with("column two").and_return(1)
          allow(header).to receive(:column_index).with("column three").and_return(2)
        end

        it "returns all attributes and values" do
          expect(subject.send(:all_attributes)).to eq({ column_one: "Value One", column_two: "", column_three: "Value Three" })
        end
      end
    end

    describe "#inherit_or_delegate" do
      let(:model_finder) { double("model-finder") }
      let(:subject) { described_class.new(header, data, row_model_finder: model_finder) }

      it "doesn't respond to inherit_or_delegate" do
        expect(subject.respond_to?(:inherit_or_delegate)).to eq(false)
      end

      it "returns nil when no method invoked" do
        expect(subject.send(:inherit_or_delegate, :some_method, :multiple, :args)).to eq(nil)
      end

      it "invokes internal method if method is defined" do
        allow(subject).to receive(:respond_to?).with(:some_method).and_return(true)
        allow(subject).to receive(:respond_to?).with(:some_method, false).and_return(true)
        expect(subject).to receive(:some_method).with(:multiple, :args).and_return(:some_value)
        expect(subject.send(:inherit_or_delegate, :some_method, :multiple, :args)).to eq(:some_value)
      end

      it "invokes delegate method if delegate exists and internal method is not defined" do
        expect(model_finder).to receive(:some_method).with(:multiple, :args).and_return(:some_value)
        expect(subject.send(:inherit_or_delegate, :some_method, :multiple, :args)).to eq(:some_value)
      end
    end

    describe "#key_attributes" do
      it "doesn't respond to key_attributes" do
        expect(subject.respond_to?(:key_attributes)).to eq(false)
      end

      it "returns the entire row if no primary key is defined" do
        expect(subject.send(:key_attributes)).to eq(column_one: "Value One")
      end

      context "when the row has a single primary key column" do
        let(:primary_key_columns) { [column] }

        it "returns the value for the key column" do
          expect(subject.send(:key_attributes)).to eq(column_one: "Value One")
        end
      end

      context "when the row has a composite key" do
        let(:columns) { [
          double("column", key: "column one", model_attribute: :column_one),
          double("column", key: "column two", model_attribute: :column_two),
          double("column", key: "column three", model_attribute: :column_three)
        ] }
        let(:primary_key_columns) { [
          double("column", key: "column one", model_attribute: :column_one),
          double("column", key: "column two", model_attribute: :column_two)
        ] }
        let(:data) { ["Value One", "Value Two", "Value Three"] }

        before do
          allow(header).to receive(:column_index).with("column two").and_return(1)
        end

        it "returns the value for the key columns" do
          expect(subject.send(:key_attributes)).to eq(column_one: "Value One", column_two: "Value Two")
        end
      end

      context "with a column mapping" do
        let(:model_mapper) { double("model-mapper") }
        let(:subject) { described_class.new(header, data, row_model_mapper: model_mapper) }

        before do
          allow(model_mapper).to receive(:map_key_attributes).with({ column_one: "Value One" }).and_return(mapped_key: "mapped_value")
        end

        it "maps attributes" do
          expect(subject.send(:key_attributes)).to eq(mapped_key: "mapped_value")
        end
      end
    end

    describe "#model_instance" do
      let(:model_finder) { double("model-finder") }
      let(:model_instance) { double("model-instance") }
      let(:subject) { described_class.new(header, data, row_model_finder: model_finder) }

      before do
        allow(subject).to receive(:key_attributes).and_return(:key_attributes)
      end

      it "doesn't respond to model_instance" do
        expect(subject.respond_to?(:model_instance)).to eq(false)
      end

      it "first tries to find an instance via #find_row_model" do
        allow(subject).to receive(:respond_to?).with(:find_row_model).and_return(true)
        allow(subject).to receive(:respond_to?).with(:find_row_model, false).and_return(true)
        expect(subject).to receive(:find_row_model).with(:key_attributes).and_return(model_instance)
        expect(subject.send(:model_instance)).to eq(model_instance)
      end

      it "tries to find an instance via model#find_row_model when #find_row_model does not exist" do
        expect(model_finder).to receive(:find_row_model).with(:key_attributes).and_return(model_instance)
        expect(subject.send(:model_instance)).to eq(model_instance)
      end

      it "tries to instantiate a new model via #new_row_model when a model cannot be found" do
        allow(subject).to receive(:respond_to?).with(:find_row_model).and_return(true)
        allow(subject).to receive(:respond_to?).with(:find_row_model, false).and_return(true)
        allow(subject).to receive(:respond_to?).with(:new_row_model).and_return(true)
        allow(subject).to receive(:respond_to?).with(:new_row_model, false).and_return(true)
        expect(subject).to receive(:find_row_model).with(:key_attributes).and_return(nil)
        expect(subject).to receive(:new_row_model).with(:key_attributes).and_return(model_instance)
        expect(subject.send(:model_instance)).to eq(model_instance)
      end

      it "tries to instantiate a new model via model#new_row_model when a model cannot be found and #new_row_model does not exist" do
        expect(model_finder).to receive(:find_row_model).with(:key_attributes).and_return(nil)
        expect(model_finder).to receive(:new_row_model).with(:key_attributes).and_return(model_instance)
        expect(subject.send(:model_instance)).to eq(model_instance)
      end
    end

    describe "#process_row" do
      let(:model_finder) { double("model-finder") }
      let(:model_instance) { double("model-instance", changed?: true, marked_for_destruction?: false, new_record?: false, valid?: true) }
      let(:subject) { described_class.new(header, data, row_model_finder: model_finder) }

      before do
        allow(model_finder).to receive(:find_row_model).and_return(model_instance)
        allow(subject).to receive(:all_attributes).and_return(:all_attributes)
      end

      it "doesn't respond to process_row" do
        expect(subject.respond_to?(:process_row)).to eq(false)
      end

      it "assigns attributes and saves the model instance" do
        expect(model_instance).to receive(:assign_attributes).with(:all_attributes).ordered
        expect(model_instance).to receive(:save)
        subject.send(:process_row)
      end

      it "only processes a record once" do
        expect(model_instance).to receive(:assign_attributes).with(:all_attributes).ordered
        expect(model_instance).to receive(:save)
        subject.send(:process_row)
        subject.send(:process_row)
      end
    end
  end

end

require 'spec_helper'

describe CSVModel::RowActiveRecordAdaptor do
  let(:model) { double("model", changed?: false, marked_for_destruction?: false, new_record?: false, valid?: false) }
  let(:subject) { described_class.new(model) }

  describe "#assign_attributes" do
    it "does not raise when model is nil" do
      subject = described_class.new(nil)
      expect { subject.assign_attributes({}) }.to_not raise_exception
    end
  end

  describe "#errors" do
    it "does not raise when model is nil" do
      subject = described_class.new(nil)
      expect { subject.errors }.to_not raise_exception
    end

    it "returns an error when model is nil" do
      subject = described_class.new(nil)
      expect(subject.errors).to eq(["Record could not be created or updated"])
    end

    it "delegates to errors when model is not nil" do
      model = double("model", errors: :some_errors)
      subject = described_class.new(model)
      expect(subject.errors).to eq(:some_errors)
    end

    it "uses to errors#full_messages when available" do
      errors = double(full_messages: :some_errors)
      model = double("model", errors: errors)
      subject = described_class.new(model)
      expect(subject.errors).to eq(:some_errors)
    end
  end

  describe "#mark_as_duplicate" do
    describe "internals" do
      it "sets is_duplicate flag to true" do
        subject.mark_as_duplicate
        expect(subject.instance_variable_get("@is_duplicate")).to eq(true)
      end
    end
  end

  describe "#save" do
    context "with an invalid model" do
      let(:model) { double("model", changed?: true, marked_for_destruction?: false, new_record?: true, valid?: false) }

      it "does not calls save on underlying model" do
        expect(model).to_not receive(:save)
        subject.save
      end
    end

    context "on a normal-run with an editable, valid model" do
      let(:model) { double("model", changed?: true, marked_for_destruction?: false, new_record?: false, valid?: true) }

      it "calls save on underlying model" do
        expect(model).to receive(:save)
        subject.save
      end
    end
    
    context "on a normal-run with an editable, valid model that is marked for destruction" do
      let(:model) { double("model", changed?: true, marked_for_destruction?: true, new_record?: false, valid?: true) }

      it "calls destroy on underlying model" do
        expect(model).to receive(:destroy)
        subject.save
      end
    end

    describe "internals" do
      before do
        allow(model).to receive(:valid?).and_return(true)
        allow(model).to receive(:save).and_return(true)
        subject.save
      end

      it "sets was_saved flag to true when editable and valid" do
        allow(model).to receive(:valid?).and_return(true)
        subject.save(dry_run: true)
        expect(subject.instance_variable_get("@was_saved")).to eq(true)
      end

      it "sets was_saved flag to false when not editable" do
        allow(model).to receive(:editable?).and_return(false)
        allow(model).to receive(:valid?).and_return(true)
        subject.save(dry_run: true)
        expect(subject.instance_variable_get("@was_saved")).to eq(false)
      end

      it "sets was_saved flag to false when not valid" do
        allow(model).to receive(:valid?).and_return(false)
        subject.save(dry_run: true)
        expect(subject.instance_variable_get("@was_saved")).to eq(false)
      end

      it "capture dry run flag to false" do
        expect(subject.instance_variable_get("@is_dry_run")).to eq(false)
      end

      it "captures changed flag" do
        expect(subject.instance_variable_get("@was_changed")).to eq(false)
      end

      it "captures deleted flag" do
        expect(subject.instance_variable_get("@was_deleted")).to eq(false)
      end

      it "captures editable flag" do
        expect(subject.instance_variable_get("@was_editable")).to eq(true)
      end

      it "captures new flag" do
        expect(subject.instance_variable_get("@was_new")).to eq(false)
      end

      it "captures save flag" do
        expect(subject.instance_variable_get("@was_saved")).to eq(true)
      end

      it "captures valid flag" do
        expect(subject.instance_variable_get("@was_valid")).to eq(true)
      end
    end
  end

  describe "#status" do
    it "is ERROR_ON_READ when model is nil" do
      subject = described_class.new(nil)
      expect(subject.status).to eq(CSVModel::RecordStatus::ERROR_ON_READ)
    end

    context "during a dry-run" do
      it "is DUPLICATE when record is marked as a duplicate" do
        subject.mark_as_duplicate
        subject.save(dry_run: true)
        expect(subject.status).to eq(CSVModel::RecordStatus::DUPLICATE)
      end

      it "is NOT_CHANGED when record exists and was not changed" do
        subject.save(dry_run: true)
        expect(subject.status).to eq(CSVModel::RecordStatus::NOT_CHANGED)
      end

      it "is CREATE when record was new and valid" do
        expect(model).to receive(:new_record?).and_return(true)
        expect(model).to receive(:valid?).and_return(true)
        subject.save(dry_run: true)
        expect(subject.status).to eq(CSVModel::RecordStatus::CREATE)
      end

      it "is ERROR_ON_CREATE when record was new and not valid" do
        expect(model).to receive(:new_record?).and_return(true)
        subject.save(dry_run: true)
        expect(subject.status).to eq(CSVModel::RecordStatus::ERROR_ON_CREATE)
      end

      it "is DELETE when record exists and is marked for destruction" do
        expect(model).to receive(:marked_for_destruction?).and_return(true)
        subject.save(dry_run: true)
        expect(subject.status).to eq(CSVModel::RecordStatus::DELETE)
      end

      it "is ERROR_ON_DELETE when record was new and marked for destruction" do
        expect(model).to receive(:new_record?).and_return(true)
        expect(model).to receive(:marked_for_destruction?).and_return(true)
        subject.save(dry_run: true)
        expect(subject.status).to eq(CSVModel::RecordStatus::ERROR_ON_DELETE)
      end

      it "is UPDATE when record exists, was changed and was valid" do
        expect(model).to receive(:changed?).and_return(true)
        expect(model).to receive(:valid?).and_return(true)
        subject.save(dry_run: true)
        expect(subject.status).to eq(CSVModel::RecordStatus::UPDATE)
      end

      it "is ERROR_ON_UPDATE when record exists but was changed and not editable" do
        expect(model).to receive(:changed?).and_return(true)
        expect(model).to receive(:editable?).and_return(false)
        subject.save(dry_run: true)
        expect(subject.status).to eq(CSVModel::RecordStatus::ERROR_ON_UPDATE)
      end

      it "is ERROR_ON_UPDATE when record exists, was changed and was not valid" do
        expect(model).to receive(:changed?).and_return(true)
        subject.save(dry_run: true)
        expect(subject.status).to eq(CSVModel::RecordStatus::ERROR_ON_UPDATE)
      end
    end

    context "during normal processing" do
      it "is not DUPLICATE when record is marked as a duplicate" do
        subject.mark_as_duplicate
        subject.save
        expect(subject.status).to eq(CSVModel::RecordStatus::NOT_CHANGED)
      end

      it "is NOT_CHANGED when record exists and is not changed" do
        subject.save
        expect(subject.status).to eq(CSVModel::RecordStatus::NOT_CHANGED)
      end

      it "is CREATE when record is new, valid and saves" do
        expect(model).to receive(:new_record?).and_return(true)
        expect(model).to receive(:valid?).and_return(true)
        expect(model).to receive(:save).and_return(true)
        subject.save
        expect(subject.status).to eq(CSVModel::RecordStatus::CREATE)
      end

      it "is ERROR_ON_CREATE when record is new and not valid" do
        expect(model).to receive(:new_record?).and_return(true)
        subject.save
        expect(subject.status).to eq(CSVModel::RecordStatus::ERROR_ON_CREATE)
      end

      it "is DELETE when record exists, is marked for destruction and saves" do
        expect(model).to receive(:marked_for_destruction?).and_return(true)
        subject.save
        expect(subject.status).to eq(CSVModel::RecordStatus::DELETE)
      end

      it "is ERROR_ON_DELETE when record is new and marked for destruction" do
        expect(model).to receive(:new_record?).and_return(true)
        expect(model).to receive(:marked_for_destruction?).and_return(true)
        subject.save
        expect(subject.status).to eq(CSVModel::RecordStatus::ERROR_ON_DELETE)
      end

      it "is UPDATE when record exists, is changed, valid and saves" do
        expect(model).to receive(:changed?).and_return(true)
        expect(model).to receive(:save).and_return(true)
        expect(model).to receive(:valid?).and_return(true)
        subject.save
        expect(subject.status).to eq(CSVModel::RecordStatus::UPDATE)
      end

      it "is ERROR_ON_UPDATE when record exists, is changed and is not valid" do
        expect(model).to receive(:changed?).and_return(true)
        subject.save
        expect(subject.status).to eq(CSVModel::RecordStatus::ERROR_ON_UPDATE)
      end

      it "is ERROR_ON_UPDATE when record exists, is changed, is valid and does not save" do
        expect(model).to receive(:changed?).and_return(true)
        subject.save
        expect(subject.status).to eq(CSVModel::RecordStatus::ERROR_ON_UPDATE)
      end
    end
  end

  describe "#valid?" do
    it "does not raise when model is nil" do
      subject = described_class.new(nil)
      expect { subject.valid? }.to_not raise_exception
    end
  end

  describe "internals" do
    describe "#is_duplicate?" do
      it "doesn't respond to is_duplicate?" do
        expect(subject.respond_to?(:is_duplicate?)).to eq(false)
      end

      it "defaults to nil" do
        expect(subject.send(:is_duplicate?)).to eq(nil)
      end

      it "displays @is_duplicate" do
        subject.instance_variable_set("@is_duplicate", true)
        expect(subject.send(:is_duplicate?)).to eq(true)
      end
    end

    describe "#was_saved?" do
      it "doesn't respond to was_saved?" do
        expect(subject.respond_to?(:was_saved?)).to eq(false)
      end

      it "defaults to nil" do
        expect(subject.send(:was_saved?)).to eq(nil)
      end

      it "displays @was_saved" do
        subject.instance_variable_set("@was_saved", true)
        expect(subject.send(:was_saved?)).to eq(true)
      end
    end
  end

end

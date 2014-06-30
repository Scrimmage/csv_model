require 'spec_helper'

describe CSVModel::Column do

  let(:column_name) { "Column One" }
  let(:subject) { described_class.new(column_name) }

  describe "#is_primary_key?" do
    it "defaults to false" do
      expect(subject.is_primary_key?).to eq(false)
    end

    it "returns false if options indicate column is a primary key" do
      subject = described_class.new(column_name, primary_key: true)
      expect(subject.is_primary_key?).to eq(true)
    end
  end

  describe "#key" do
    it "returns the column key" do
      expect(subject.key).to eq("column one")
    end
  end

  describe "#model_attribute" do
    it "returns a symbolized version of the column key" do
      expect(subject.model_attribute).to eq(:column_one)
    end
  end

end

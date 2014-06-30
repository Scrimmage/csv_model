require 'spec_helper'

describe CSVModel::Model do

  let(:header_row) { ["Column One", "Column Two"] }
  let(:data_row) { ["Value One", "Value Two"] }
  let(:data) { [header_row.join("\t"), data_row.join("\t")].join($/) }
  let(:subject) { described_class.new(data) }

  describe "#row_count" do
    it "returns 0 when no data" do
      expect(described_class.new("").row_count).to eq(0)
    end

    it "returns the number of rows" do
      expect(subject.row_count).to eq(1)
    end
  end

  describe "#structure_errors" do
    it "returns an empty array when CSV data has integrity" do
      expect(subject.structure_errors).to eq([])
    end

    it "returns a parser specific error when CSV data is maleformed" do
      expect(CSV).to receive(:parse).and_raise(CSV::MalformedCSVError.new("foo"))
      expect(subject.structure_errors).to eq(["The data could not be parsed. Please check for formatting errors: foo"])
    end

    it "returns a parser specific error when CSV data is inconsistent" do
      data_row.shift
      expect(subject.structure_errors).to eq(["Each row should have exactly 2 columns. Error on row 2."])
    end

    it "returns a generic error when CSV data is invalid" do
      expect(CSV).to receive(:parse).and_raise(Exception.new("foo"))
      expect(subject.structure_errors).to eq(["An unexpected error occurred. Please try again or contact support if the issue persists: foo"])
    end

    it "returns header errors when header is invalid" do
      header_row.pop
      header_row << header_row.first
      expect(subject.structure_errors).to eq(["Multiple columns found for Column One, column headings must be unique"])
    end

    context "with required columns" do
      let(:options) { OpenStruct.new(required_columns: ["Column Two", "Column Three", "Column Four"]) }
      let(:subject) { described_class.new(data, options) }

      it "returns errors for each missing required column" do
        expect(subject.structure_errors).to eq(["Missing column Column Three", "Missing column Column Four"])
      end
    end
  end

  describe "#structure_valid?" do
    it "returns true when CSV data has integrity" do
      expect(subject.structure_valid?).to eq(true)
    end

    it "returns false when CSV data is maleformed" do
      expect(CSV).to receive(:parse).and_raise(CSV::MalformedCSVError.new("foo"))
      expect(subject.structure_valid?).to eq(false)
    end

    it "returns false when CSV data is invalid" do
      expect(CSV).to receive(:parse).and_raise(Exception.new("foo"))
      expect(subject.structure_valid?).to eq(false)
    end

    it "returns false when header is invalid" do
      header_row.shift
      header_row << header_row.first
      expect(subject.structure_valid?).to eq(false)
    end
  end

  describe "internals" do
    describe "#parse_data" do
      context "with duplicate rows" do
        let(:data) { [header_row.join("\t"), data_row.join("\t"), data_row.join("\t"), data_row.join("\t")].join($/) }

        before do
          subject.send(:parse_data)
        end

        it "does not mark the first row as a duplicate" do
          expect(subject.rows.first.marked_as_duplicate?).to eq(false)
        end

        it "marks subsequent instances as a duplicates" do
          rows = subject.rows
          rows.shift
          rows.each { |row| expect(row.marked_as_duplicate?).to eq(true) }
        end
      end
    end
  end

end

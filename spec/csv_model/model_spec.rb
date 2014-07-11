require 'spec_helper'

describe CSVModel::Model do

  let(:header_row) { ["Column One", "Column Two"] }
  let(:data_row) { ["Value One", "Value Two"] }
  let(:data) { [header_row.join("\t"), data_row.join("\t")].join($/) }
  let(:subject) { described_class.new(data) }

  describe "header" do
    context "with options" do
      let(:options) { { dry_run: true } }
      let(:subject) { described_class.new(data, options) }

      it "instantiates header with options" do
        expect(subject.header.options).to eq(options)
      end
    end
  end

  describe "rows" do
    it "has a row for each data row" do
      expect(subject.rows.count).to eq(1)
    end

    context "with options" do
      let(:options) { { dry_run: true } }
      let(:subject) { described_class.new(data, options) }

      it "instantiates rows with options" do
        expect(subject.rows.first.options).to eq(options)
      end
    end
  end

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
      context "with a custom header row class" do
        class TestHeaderRow < CSVModel::HeaderRow; end

        let(:subject) { described_class.new(data, header_class: TestHeaderRow) }

        before do
          subject.send(:parse_data)
        end

        it "uses the custom class in parsing" do
          expect(subject.header.class).to eq(TestHeaderRow)
        end
      end

      context "With a custom row class" do
        class TestRow < CSVModel::Row; end

        let(:subject) { described_class.new(data, row_class: TestRow) }

        before do
          subject.send(:parse_data)
        end

        it "uses the custom class in parsing" do
          expect(subject.rows.count).to eq(1)
          expect(subject.rows.first.class).to eq(TestRow)
        end
      end

      context "with duplicate rows" do
        let(:data) { [header_row.join("\t"), data_row.join("\t"), data_row.join("\t"), data_row.join("\t")].join($/) }

        before do
          subject.send(:parse_data)
        end

        context "with duplicate checking disabled" do
          let(:subject) { described_class.new(data, detect_duplicate_rows: false, primary_key: [header_row.first]) }

          it "does not mark any row as a duplicate" do
            subject.rows.each { |row| expect(row.marked_as_duplicate?).to eq(false) }
          end
        end

        context "with a single column primary key" do
          let(:subject) { described_class.new(data, primary_key: [header_row.first]) }

          context "when primary key values are present" do
            it "does not mark the first row as a duplicate" do
              expect(subject.rows.first.marked_as_duplicate?).to eq(false)
            end

            it "marks subsequent instances as a duplicates" do
              rows = subject.rows
              rows.shift
              rows.each { |row| expect(row.marked_as_duplicate?).to eq(true) }
            end
          end

          context "when no primary key values are present" do
            let(:data_row) { ["", ""] }

            it "does not mark any row as a duplicate" do
              subject.rows.each { |row| expect(row.marked_as_duplicate?).to eq(false) }
            end
          end
        end

        context "with a compount primary key" do
          context "when primary key values are present" do
            it "does not mark the first row as a duplicate" do
              expect(subject.rows.first.marked_as_duplicate?).to eq(false)
            end

            it "marks subsequent instances as a duplicates" do
              rows = subject.rows
              rows.shift
              rows.each { |row| expect(row.marked_as_duplicate?).to eq(true) }
            end
          end

          context "when no primary key values are present" do
            let(:data_row) { ["", ""] }

            it "does not mark any row as a duplicate" do
              subject.rows.each { |row| expect(row.marked_as_duplicate?).to eq(false) }
            end
          end
        end
      end
    end
  end
end

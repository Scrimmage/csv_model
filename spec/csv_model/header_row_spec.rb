require 'spec_helper'

describe CSVModel::HeaderRow do

  let(:data) { ["Column One"] }
  let(:subject) { described_class.new(data) }

  describe "#new" do
    it "raises an ArgumentError when primary_key is not a subset of legal columns" do
      expect { described_class.new(data, legal_columns: ["Column One"], primary_key: ["Column Two"]) }.to raise_error(ArgumentError)
    end

    it "does not raises an ArgumentError when primary_key is a subset of legal columns" do
      expect { described_class.new(data, legal_columns: ["Column One"], primary_key: ["column one"]) }.to_not raise_error
    end

    it "raises an ArgumentError when primary_key is specified but empty" do
      expect { described_class.new(data, primary_key: []) }.to raise_error(ArgumentError)
    end

    it "raises an ArgumentError when alternative_primary_key is specified but no primary_key is specified" do
      expect { described_class.new(data, alternate_primary_key: ["Column One"]) }.to raise_error(ArgumentError)
    end

    it "raises an ArgumentError when alternative_primary_key is not a subset of legal columns" do
      expect { described_class.new(data, legal_columns: ["Column One"], primary_key: ["Column One"], alternate_primary_key: ["Column Two"]) }.to raise_error(ArgumentError)
    end

    it "raises an ArgumentError when alternative_primary_key colums are idential to primary key columns" do
      expect { described_class.new(data, primary_key: ["Column One"], alternate_primary_key: ["Column One"]) }.to raise_error(ArgumentError)
    end
  end

  describe "#columns" do
    it "returns an empty array when no columns exist" do
      subject = described_class.new([])
      expect(subject.columns).to eq([])
    end

    it "returns a column object that describes each column" do
      columns = subject.columns
      expect(columns).to be_an(Array)
      expect(columns.size).to eq(1)

      column = columns.first
      expect(column.name).to eq(data.first)
    end
  end

  describe "#column_index" do
    it "returns nil when a column does not exist" do
      expect(subject.column_index("Non-existent Column")).to eq(nil)
    end

    it "finds the index of a column given its value" do
      expect(subject.column_index("Column One")).to eq(0)
    end

    it "finds the index of a column regardless of capitalization" do
      expect(subject.column_index("column ONE")).to eq(0)
    end

    it "finds the index of a column regardless of leading whitespace" do
      expect(subject.column_index(" Column One")).to eq(0)
    end

    it "finds the index of a column regardless of trailing whitespace" do
      expect(subject.column_index("Column One\t")).to eq(0)
    end

    it "finds the index of a column given its symbolic representation" do
      expect(subject.column_index("Column One".to_sym)).to eq(0)
    end
  end

  describe "#column_count" do
    it "returns 0 when no columns" do
      subject = described_class.new([])
      expect(subject.column_count).to eq(0)
    end

    it "returns the number of columns" do
      expect(subject.column_count).to eq(1)
    end
  end

  describe "#errors" do
    it "returns an empty array when header is valid" do
      expect(subject.errors).to eq([])
    end

    it "returns duplicate column message when header has duplicate columns" do
      subject = described_class.new(data + data)
      expect(subject.errors).to eq(["Multiple columns found for Column One, column headings must be unique"])
    end

    it "returns illegal column message when header contains illegal columns" do
      subject = described_class.new(data, legal_columns: ["Column Two"])
      expect(subject.errors).to eq(["Unknown column Column One"])
    end

    it "returns required column message when header is missing required columns" do
      subject = described_class.new(data, required_columns: ["Column Two"])
      expect(subject.errors).to eq(["Missing column Column Two"])
    end

    it "returns required column message when header is missing required primary key columns" do
      subject = described_class.new(data, primary_key: ["Column Two"])
      expect(subject.errors).to eq(["Missing column Column Two"])
    end

    it "returns single message when column is missing required and primary key" do
      subject = described_class.new(data, primary_key: ["Column Two"], required_columns: ["Column Two"])
      expect(subject.errors).to eq(["Missing column Column Two"])
    end

    it "returns empty array when header is missing required primary key column but alternate is available" do
      subject = described_class.new(data, primary_key: ["Column Two"], alternate_primary_key: ["Column One"])
      expect(subject.errors).to eq([])
    end

    it "returns required column message when header is missing required primary key and alternate is not available " do
      subject = described_class.new(data, primary_key: ["Column Two"], alternate_primary_key: ["Column Three"])
      expect(subject.errors).to eq(["Missing column Column Two"])
    end
  end

  describe "#has_column?" do
    it "returns false when a column does not exist" do
      expect(subject.has_column?("Non-existent Column")).to eq(false)
    end

    it "returns true when a column does exist" do
      expect(subject.has_column?("Column One")).to eq(true)
    end
  end

  describe "#primary_key_columns" do
    it "returns emptry array when no primary key columns specified" do
      expect(subject.primary_key_columns).to eq([])
    end

    context "when the row has a single primary key column" do
      let(:subject) { described_class.new(data, OpenStruct.new(primary_key: ["Column One"])) }

      it "has a single key column" do
        expect(subject.primary_key_columns.count).to eq(1)
      end

      it "returns the key column" do
        column = subject.primary_key_columns.first
        expect(column.name).to eq("Column One")
      end

      context "even if the column capitalization does not match" do
        let(:subject) { described_class.new(data, OpenStruct.new(primary_key: ["column one"])) }

        it "returns the key column" do
          column = subject.primary_key_columns.first
          expect(column.name).to eq("Column One")
        end
      end

      context "when the primary key column is not present but an alternate is available and present" do
        let(:subject) { described_class.new(data, OpenStruct.new(primary_key: ["column four"], alternate_primary_key: ["column one"])) }

        it "returns the alternate key column" do
          column = subject.primary_key_columns.first
          expect(column.name).to eq("Column One")
        end
      end
    end

    context "when the row has multiple primary key columns" do
      let(:data) { ["Column One", "Column Two"] }
      let(:subject) { described_class.new(data, primary_key: data) }

      it "returns the key columns" do
        expect(subject.primary_key_columns.collect { |x| x.name }).to eq(["Column One", "Column Two"])
      end
    end
  end

  describe "#valid?" do
    it "returns true when header is valid" do
      expect(subject.valid?).to eq(true)
    end

    it "returns false when header has duplicate columns" do
      subject = described_class.new(data + data)
      expect(subject.valid?).to eq(false)
    end

    it "returns false when header contains illegal columns" do
      subject = described_class.new(data, legal_columns: ["Column Two"])
      expect(subject.valid?).to eq(false)
    end

    it "returns false when header is missing a primary key column" do
      subject = described_class.new(data, primary_key: ["Column Two"])
      expect(subject.valid?).to eq(false)
    end

    it "returns false when header is missing required columns" do
      subject = described_class.new(data, required_columns: ["Column Two"])
      expect(subject.valid?).to eq(false)
    end

    it "returns true when header is missing required primary key column but alternate is available" do
      subject = described_class.new(data, primary_key: ["Column Two"], alternate_primary_key: ["Column One"])
      expect(subject.valid?).to eq(true)
    end

    it "returns false when header is missing required primary key and alternate is not available " do
      subject = described_class.new(data, primary_key: ["Column Two"], alternate_primary_key: ["Column Three"])
      expect(subject.valid?).to eq(false)
    end
  end

  describe "internals" do
    describe "#duplicate_column_names" do
      it "doesn't respond to duplicate_column_names" do
        expect(subject.respond_to?(:duplicate_column_names)).to eq(false)
      end

      it "returns an empty array when no duplicate columns exist" do
        expect(subject.send(:duplicate_column_names)).to eq([])
      end

      it "returns the duplicate column names when duplicate columns exist" do
        data << data.first
        expect(subject.send(:duplicate_column_names)).to eq(["Column One"])
      end
    end

    describe "#has_alternate_primary_key?" do
      it "doesn't respond to has_alternate_primary_key?" do
        expect(subject.respond_to?(:has_alternate_primary_key?)).to eq(false)
      end

      it "returns false when an alternate primary key is not specified" do
        expect(subject.send(:has_alternate_primary_key?)).to eq(false)
      end

      context "with an alternate primary key" do
        let(:subject) { described_class.new(data, primary_key: ["Column Four"], alternate_primary_key: ["Column One"]) }

        it "returns true" do
          expect(subject.send(:has_alternate_primary_key?)).to eq(true)
        end
      end
    end

    describe "#has_alternate_primary_key_columns?" do
      it "doesn't respond to has_alternate_primary_key_columns?" do
        expect(subject.respond_to?(:has_alternate_primary_key_columns?)).to eq(false)
      end

      it "returns true when no primary key columns specified" do        
        expect(subject.send(:has_alternate_primary_key_columns?)).to eq(true)
      end

      context "with alternate key columns specified" do
        let(:subject) { described_class.new(data, primary_key: ["Column Four"], alternate_primary_key: ["Column One"]) }

        it "returns true when all alternate primary key columns are present" do
          expect(subject.send(:has_alternate_primary_key_columns?)).to eq(true)
        end

        it "returns false when an alternate primry key column is missing" do
          data[0] = "Column Two"
          expect(subject.send(:has_alternate_primary_key_columns?)).to eq(false)
        end
      end
    end

    describe "#has_duplicate_columns?" do
      it "doesn't respond to has_duplicate_columns?" do
        expect(subject.respond_to?(:has_duplicate_columns?)).to eq(false)
      end

      it "returns false when no duplicate columns exist" do
        expect(subject.send(:has_duplicate_columns?)).to eq(false)
      end

      it "returns true when duplicate columns exist" do
        data << data.first
        expect(subject.send(:has_duplicate_columns?)).to eq(true)
      end
    end

    describe "#has_illegal_columns?" do
      it "doesn't respond to has_illegal_columns?" do
        expect(subject.respond_to?(:has_illegal_columns?)).to eq(false)
      end

      it "returns false when no legal columns specified" do
        expect(subject.send(:has_illegal_columns?)).to eq(false)
      end

      context "with legal columns specified" do
        let(:subject) { described_class.new(data, legal_columns: ["Column One"]) }

        it "returns false when no illegal columns are present" do
          expect(subject.send(:has_illegal_columns?)).to eq(false)
        end

        it "returns true when an illegal column is present" do
          data[0] = "Column Two"
          expect(subject.send(:has_illegal_columns?)).to eq(true)
        end
      end
    end

    describe "#has_primary_key?" do
      it "doesn't respond to has_primary_key?" do
        expect(subject.respond_to?(:has_primary_key?)).to eq(false)
      end

      it "returns false when a primary key is not specified" do
        expect(subject.send(:has_primary_key?)).to eq(false)
      end

      context "with a primary key" do
        let(:subject) { described_class.new(data, primary_key: ["Column One"]) }

        it "returns true" do
          expect(subject.send(:has_primary_key?)).to eq(true)
        end
      end
    end

    describe "#has_primary_key_columns?" do
      it "doesn't respond to has_primary_key_columns?" do
        expect(subject.respond_to?(:has_primary_key_columns?)).to eq(false)
      end

      it "returns true when no primary key columns specified" do
        expect(subject.send(:has_primary_key_columns?)).to eq(true)
      end

      context "with primary key columns specified" do
        let(:subject) { described_class.new(data, primary_key: ["Column One"]) }

        it "returns true when all primary key columns are present" do
          expect(subject.send(:has_primary_key_columns?)).to eq(true)
        end

        it "returns false when a primry key column is missing" do
          data[0] = "Column Two"
          expect(subject.send(:has_primary_key_columns?)).to eq(false)
        end
      end
    end

    describe "#has_required_columns?" do
      it "doesn't respond to has_required_columns?" do
        expect(subject.respond_to?(:has_required_columns?)).to eq(false)
      end

      it "returns true when no required columns specified" do
        expect(subject.send(:has_required_columns?)).to eq(true)
      end

      context "with required columns specified" do
        let(:subject) { described_class.new(data, required_columns: ["Column One"]) }

        it "returns true when all required columns are present" do
          expect(subject.send(:has_required_columns?)).to eq(true)
        end

        it "returns false when a required columns is missing" do
          data[0] = "Column Two"
          expect(subject.send(:has_required_columns?)).to eq(false)
        end
      end
    end

    describe "#has_required_key_columns?" do
      it "doesn't respond to has_required_key_columns?" do
        expect(subject.respond_to?(:has_required_key_columns?)).to eq(false)
      end

      it "returns true when no primary key is specified" do
        expect(subject.send(:has_required_key_columns?)).to eq(true)
      end

      context "with primary key columns specified" do
        let(:subject) { described_class.new(data, primary_key: ["Column One"]) }

        it "returns true when all primary key columns are present" do
          expect(subject.send(:has_required_key_columns?)).to eq(true)
        end

        it "returns false when a primary key columns is missing" do
          data[0] = "Column Two"
          expect(subject.send(:has_required_key_columns?)).to eq(false)
        end
      end

      context "with primary and alternate key columns specified" do
        let(:subject) { described_class.new(data, primary_key: ["Column Two"], alternate_primary_key: ["Column Four"]) }

        it "returns true when all primary key columns are present" do
          data[0] = "Column Two"
          expect(subject.send(:has_required_key_columns?)).to eq(true)
        end

        it "returns true when a primary key columns is missing but all alternate primary key columns are present" do
          data[0] = "Column Four"
          expect(subject.send(:has_required_key_columns?)).to eq(true)
        end

        it "returns false when a primary key column is missing and no alternative is available" do
          data[0] = "Column Three"
          expect(subject.send(:has_required_key_columns?)).to eq(false)
        end
      end
    end

    describe "#illegal_column_names" do
      it "doesn't respond to illegal_colum_names" do
        expect(subject.respond_to?(:illegal_colum_names)).to eq(false)
      end

      it "returns emptry array when no legal columns specified" do
        expect(subject.send(:illegal_column_names)).to eq([])
      end

      context "with legal columns specified" do
        let(:subject) { described_class.new(data, OpenStruct.new(legal_columns: ["Column One"])) }

        it "returns empty array when no illegal columns are present" do
          expect(subject.send(:illegal_column_names)).to eq([])
        end

        it "returns array of illegal column names when a illegal column is present" do
          data[0] = "Column Two"
          expect(subject.send(:illegal_column_names)).to eq(["Column Two"])
        end
      end
    end

    describe "#missing_column_names" do
      it "doesn't respond to missing_column_names" do
        expect(subject.respond_to?(:missing_column_names)).to eq(false)
      end

      it "returns emptry array when no required columns specified" do
        expect(subject.send(:missing_column_names)).to eq([])
      end

      context "with required columns specified" do
        let(:subject) { described_class.new(data, OpenStruct.new(required_columns: ["Column One"])) }

        it "returns empty array when all required columns are present" do
          expect(subject.send(:missing_column_names)).to eq([])
        end

        it "returns array of missing column names when a required column is missing" do
          data[0] = "Column Two"
          expect(subject.send(:missing_column_names)).to eq(["Column One"])
        end
      end
    end

    describe "#missing_primary_key_column_names" do
      it "doesn't respond to missing_primary_key_column_names" do
        expect(subject.respond_to?(:missing_primary_key_column_names)).to eq(false)
      end

      it "returns emptry array when no primary key columns specified" do
        expect(subject.send(:missing_primary_key_column_names)).to eq([])
      end

      context "with primary key columns specified" do
        let(:subject) { described_class.new(data, OpenStruct.new(primary_key: ["Column One"])) }

        it "returns empty array when all primary key columns are present" do
          expect(subject.send(:missing_primary_key_column_names)).to eq([])
        end

        it "returns array of missing column names when a primary key column is missing" do
          data[0] = "Column Two"
          expect(subject.send(:missing_primary_key_column_names)).to eq(["Column One"])
        end
      end
    end
  end

end

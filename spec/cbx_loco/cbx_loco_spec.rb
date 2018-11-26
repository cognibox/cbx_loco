require "spec_helper"

describe CbxLoco do
  let(:any_api_key) { "ANY API KEY" }

  before do
    CbxLoco.configure do |c|
      c.api_key = any_api_key
    end
  end

  describe ".configure" do
    it "should return a configuration" do
      expect(CbxLoco.configuration.is_a?(CbxLoco::Configuration)).to be true
    end

    it "should set values" do
      expect(CbxLoco.configuration.api_key).to eq any_api_key
    end
  end

  describe ".run" do
    context "called with import" do
      let(:importer) { double }

      it "should create an importer and run" do
        params = { import: true }
        allow(CbxLoco::Importer).to receive(:new) { importer }
        allow(importer).to receive(:run)

        CbxLoco.run params

        expect(CbxLoco::Importer).to have_received(:new)
        expect(importer).to have_received(:run)
      end
    end

    context "called with extract" do
      let(:extractor) { double }

      it "should create an extractor and run" do
        params = { extract: true }
        allow(CbxLoco::Extractor).to receive(:new) { extractor }
        allow(extractor).to receive(:run)

        CbxLoco.run params

        expect(CbxLoco::Extractor).to have_received(:new)
        expect(extractor).to have_received(:run)
      end
    end
  end
end

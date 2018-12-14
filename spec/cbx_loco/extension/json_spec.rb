require "spec_helper"

describe CbxLoco::Extension::Json do
  let(:instance) { CbxLoco::Extension::Json.new }

  describe "#bundle_translations" do
    let(:content) { { en: "any", fr: "thing" } }

    before do
      instance.instance_variable_set(:@translations, content)
    end

    it "should unset @translations" do
      expect(instance.instance_variable_get(:@translations)).to eq content
      instance.bundle_translations
      expect(instance.instance_variable_get(:@translations)).to be_nil
    end

    it "should format to json" do
      translations = instance.bundle_translations
      expect(translations).to eq("{ \"en\": any, \"fr\": thing }")
    end
  end

  describe "#validate" do
    let(:file_path) { "test.json" }

    before(:each) do
      suppress_console_output
      allow(STDOUT).to receive(:puts)
      create_file(content, file_path)
    end

    after(:each) do
      delete_file(file_path)
    end

    context "when invalid" do
    let(:content) { "any content" }

      it "should puts error" do
        expect{ instance.validate(CbxLoco.file_path(file_path)) }.to raise_error SystemExit
        expect(STDOUT).to have_received(:puts).with(/\n\nFILE ERROR: "#{CbxLoco.file_path(file_path)}" is not JSON or is invalid:\n/)
      end
    end

    context "when valid" do
      let(:content) { "{}" }
      it "should not puts error" do
        expect{ instance.validate(CbxLoco.file_path(file_path)) }.to_not raise_error
        expect(STDOUT).to_not have_received(:puts).with(/\n\nFILE ERROR: "#{CbxLoco.file_path(file_path)}" is not JSON or is invalid:\n/)
      end
    end
  end
end

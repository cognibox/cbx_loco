require "spec_helper"

describe CbxLoco::Extention::Yaml do
  let(:instance) { CbxLoco::Extention::Yaml.new }

  describe "#validate" do
    let(:file_path) { "test.yml" }

    before(:each) do
      suppress_console_output
      allow(STDOUT).to receive(:puts)
      create_file(content, file_path)
    end

    after(:each) do
      delete_file(file_path)
    end

    context "when invalid" do
    let(:content) { "\"" }

      it "should puts error" do
        expect{ instance.validate(CbxLoco.file_path(file_path)) }.to raise_error SystemExit
        expect(STDOUT).to have_received(:puts).with(/\n\nFILE ERROR: "#{CbxLoco.file_path(file_path)}" is not YAML or is invalid:\n/)
      end
    end

    context "when valid" do
      let(:content) { "---\nen:\n  key: value" }
      it "should not puts error" do
        expect{ instance.validate(CbxLoco.file_path(file_path)) }.to_not raise_error
        expect(STDOUT).to_not have_received(:puts).with(/\n\nFILE ERROR: "#{CbxLoco.file_path(file_path)}"is not YAML or is invalid:\n/)
      end
    end
  end
end

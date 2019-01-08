require "spec_helper"

describe CbxLoco::Importer do
  before(:all) do
    @fake_file_formats = {
      gettext: {
        api_ext: "po",
        delete: true,
        dst_ext: "po",
        src_ext: "pot",
        path: "locale"
      },
      yaml: {
        api_ext: "yml",
        delete: false,
        dst_ext: "yml",
        src_ext: "yml",
        path: "locale"
      }
    }

    @fake_i18n_files = [
      {
        format: :yaml,
        id: "test_server",
        name: "test_cbx"
      },
      {
        format: :gettext,
        id: "test_client",
        name: "test_front_end"
      }
    ]

    @fake_languages = %w[en fr]

    @str_response = rand_str
    @str_json = "{\"test\": \"#{@str_response}\"}"
  end

  before(:each) do
    @after_import_call = false

    CbxLoco.configure do |c|
      c.api_key = fake_api_key
      c.api_url = fake_api_url
      c.file_formats = @fake_file_formats
      c.i18n_files = @fake_i18n_files
      c.languages = @fake_languages

      c.on :after_import do
        @after_import_call = true
      end
    end

    suppress_console_output
  end

  describe "#run" do
    before(:each) do
      allow(CbxLoco::Adapter).to receive(:get).and_return(@str_response)
      @fake_i18n_files.each do |i18n_file|
        extension_class = "CbxLoco::Extension::#{i18n_file[:format].to_s.camelize}".constantize
        allow(extension_class).to receive(:new).and_return(extension_class)
        allow(extension_class).to receive(:download)
      end
    end

    it "should call API for each language file" do
      CbxLoco::Importer.new.run

      @fake_i18n_files.each do |i18n_file|
        extension_class = "CbxLoco::Extension::#{i18n_file[:format].to_s.camelize}".constantize

        expect(extension_class).to have_received(:new)
        expect(extension_class).to have_received(:download)
      end
    end

    it "should run after_import" do
      CbxLoco::Importer.new.run
      expect(@after_import_call).to be true
    end
  end
end

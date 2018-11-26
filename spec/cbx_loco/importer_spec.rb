require "spec_helper"

describe CbxLoco::Importer do
  def create_files
    @fake_i18n_files.each do |i18n_file|
      create_file i18n_file
    end
  end

  def create_file(i18n_file)
    fmt = @fake_file_formats[i18n_file[:format]]
    case i18n_file[:format]
    when :gettext
      file_path = CbxLoco.file_path fmt[:path], [i18n_file[:name], fmt[:src_ext]].join(".")
    when :yaml
      language = @fake_languages.first
      file_path = CbxLoco.file_path fmt[:path], [i18n_file[:name], language, fmt[:src_ext]].join(".")
    end

    f = File.new file_path, "w:UTF-8"
    f.write @fake_translations[i18n_file[:id]].force_encoding("UTF-8")
    f.close
  end

  def delete_files
    @fake_i18n_files.each do |i18n_file|
      # unlink src_ext
      fmt = @fake_file_formats[i18n_file[:format]]
      case i18n_file[:format]
      when :gettext
        file_path = CbxLoco.file_path fmt[:path], [i18n_file[:name], fmt[:src_ext]].join(".")
      when :yaml
        language = CbxLoco.configuration.languages.first
        file_path = CbxLoco.file_path fmt[:path], [i18n_file[:name], language, fmt[:src_ext]].join(".")
      end

      File.unlink file_path if File.file? file_path

      # unlink dst_ext
      @fake_languages.each do |language|
        case i18n_file[:format]
        when :gettext
          file_path = CbxLoco.file_path fmt[:path], language, [i18n_file[:name], fmt[:dst_ext]].join(".")
        when :yaml
          file_path = CbxLoco.file_path fmt[:path], [i18n_file[:name], language, fmt[:dst_ext]].join(".")
        end
        File.unlink file_path if File.file? file_path
      end
    end
  end

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
        format: :yaml,
        id: "test_server",
        name: "test_devise"
      },
      {
        format: :gettext,
        id: "test_client",
        name: "test_front_end"
      }
    ]
    @pot_header = "msgid \"\"\nmsgstr \"\"\n\"Content-Type: text/plain; charset=UTF-8\\n\"\n\"Content-Transfer-Encoding: 8bit\\n\"\n\n"
    @fake_translations = {
      "test_server" => "en:\n  cbx:\n    some_asset:\n    some_other_asset:\n    some_asset_with_a_really_long_name_that_exceeds_locos_100_character_limit_to_asset_names_because_we_want_everything_to_work_properly:",
      "test_client" => @pot_header + "msgid \"Some asset\"\nmsgstr \"\"\n\nmsgid \"Some other asset\"\nmsgstr \"\"\n"
    }

    @fake_api_key = "abcd1234"
    @fake_api_url = "http://example.com/api/"
    @fake_languages = %w[en fr]

    @str_response = rand_str
    @str_json = "{\"test\": \"#{@str_response}\"}"
  end

  before(:each) do
    @after_import_call = false

    CbxLoco.configure do |c|
      c.api_key = @fake_api_key
      c.api_url = @fake_api_url
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
      # allow(CbxLoco::LocoAdapter).to receive(:`)
    end

    before(:all) do
      create_files
    end

    after(:all) do
      delete_files
    end

    it "should call API for each language file" do
      @fake_i18n_files.each do |i18n_file|
        CbxLoco.configuration.languages.each do |language|
          fmt = CbxLoco.configuration.file_formats[i18n_file[:format]]
          api_ext = fmt[:api_ext]
          tag = CbxLoco.asset_tag i18n_file[:id], i18n_file[:name]

          api_params = { filter: tag, order: :id }
          case i18n_file[:format]
          when :gettext
            api_params[:index] = "name"
          when :yaml
            api_params[:format] = "rails"
          end

          expect(CbxLoco::Adapter).to receive(:get).with("export/locale/#{language}.#{api_ext}", api_params, false)
        end
      end

      CbxLoco::Importer.new.run
    end

    context "when locale folder does not exist" do
      let!(:mock_file) { double }
      let(:folder_to_create) { "./locale/en" }
      let(:keep_file) { File.join(folder_to_create, ".keep") }

      before do
        allow(File).to receive(:directory?).and_return(true)
        allow(File).to receive(:directory?).with(folder_to_create).and_return(false)
        allow(FileUtils).to receive(:mkdir_p).with(folder_to_create)
        allow(FileUtils).to receive(:touch)
      end

      it "should create the folder" do
        CbxLoco::Importer.new.run
        expect(FileUtils).to have_received(:mkdir_p).with(folder_to_create)
      end

      it "should create .keep file" do
        CbxLoco::Importer.new.run
        expect(FileUtils).to have_received(:touch).with(keep_file)
      end
    end

    it "should only validate YAML file" do
      allow(YAML).to receive(:load_file)
      CbxLoco::Importer.new.run
      @fake_i18n_files.each do |file|
        case file[:format]
        when :gettext
          expect(YAML).to_not have_received(:load_file).with(/#{file[:name]}/)
        when :yaml
          expect(YAML).to have_received(:load_file).with(/#{file[:name]}/).exactly(2).times
        end
      end
    end

    context "when file is not valid YAML" do
      it "should exit with error" do
        allow(YAML).to receive(:load_file).and_raise
        expect { CbxLoco::Importer.new.run }.to raise_error(SystemExit)
      end
    end

    it "should write API return in language files" do
      CbxLoco::Importer.new.run

      @fake_i18n_files.each do |i18n_file|
        fmt = CbxLoco.configuration.file_formats[i18n_file[:format]]
        CbxLoco.configuration.languages.each do |language|
          case i18n_file[:format]
          when :gettext
            file_path = CbxLoco.file_path fmt[:path], language, [i18n_file[:name], fmt[:dst_ext]].join(".")
          when :yaml
            file_path = CbxLoco.file_path fmt[:path], [i18n_file[:name], language, fmt[:dst_ext]].join(".")
          end
          expect(File.read(file_path)).to eq @str_response
        end
      end
    end

    it "should run after_import" do
      CbxLoco::Importer.new.run
      expect(@after_import_call).to be true
    end
  end
end

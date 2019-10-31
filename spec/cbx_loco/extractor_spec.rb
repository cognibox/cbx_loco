 require "spec_helper"

describe CbxLoco::Extractor do
  def create_files
    (@fake_i18n_files || []).each do |i18n_file|
      fmt = @fake_file_formats[i18n_file[:format]]
      next if !fmt[:path] || !fmt[:src_ext]

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
    (@fake_i18n_files || []).each do |i18n_file|
      # unlink src_ext
      fmt = @fake_file_formats[i18n_file[:format]]
      next if !fmt[:path] || !fmt[:src_ext]

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

  before do
    @fake_file_formats = {
      gettext: {
        extractable: true,
        api_ext: "po",
        delete: true,
        dst_ext: "po",
        src_ext: "pot",
        path: "locale"
      },
      yaml: {
        extractable: true,
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

    @before_extract_call = false
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

      c.on :before_extract do
        @before_extract_call = true
      end
    end

    suppress_console_output
  end

  describe "#run" do
    before do
      create_files
      CbxLoco.configuration.version = "1.0.19"

      get_response = [
        { "id" => "cbx.some_other_asset", "name" => "cbx.some_other_asset", "tags" => ["testserver-testcbx"] },
        { "id" => "cbx.some_asset_with_a_really_long_name_that_exceeds_locos_100_character_limit_to_asset_names_because_we_want_everything_to_work_properly", "name" => "cbx.some_asset_with_a_really_long_name_that_exceeds_locos_100_character_limit_to_asset_names_beca...", "tags" => ["testserver-testcbx"] },
        { "id" => "some-other-asset", "name" => "Some other asset", "tags" => ["testclient-testfrontend"] }
      ]
      allow(CbxLoco::Adapter).to receive(:get).and_return(get_response)
      allow(CbxLoco::Adapter).to receive(:post).and_return("id" => "test", "tags" => [])
      allow(File).to receive(:unlink)
    end

    after(:each) do
      # restore mocking to be sure it delete files
      allow(File).to receive(:unlink).and_call_original
      delete_files
    end

    context "when delete file" do
      let(:expected_output) { /path or src_ext is not provided for name: '#{file_without_path[:name]}', id: '#{file_without_path[:id]}', format: '#{file_without_path[:format]}'/ }
      let(:file_without_path) do
        {
          format: :gettext,
          id: "test_client",
          name: "test_front_end"
        }
      end

      before(:each) do
        @previous_files = @fake_i18n_files.deep_dup
        @previous_formats = @fake_file_formats.deep_dup
      end

      after(:each) {
        @fake_i18n_files = @previous_files
        @fake_file_formats = @previous_formats
      }

      context "when no path" do
        it "should output to console" do
          @fake_file_formats[:gettext][:delete] = true
          @fake_file_formats[:gettext][:path] = nil

          @fake_i18n_files = [file_without_path]

          allow(STDOUT).to receive(:puts)
          expect { CbxLoco::Extractor.new.run }.to raise_error SystemExit
          expect(STDOUT).to have_received(:puts).with(expected_output)
        end
      end

      context "when no src_ext" do
        it "should output to console" do
          @fake_file_formats[:gettext][:delete] = true
          @fake_file_formats[:gettext][:src_ext] = nil

          @fake_i18n_files = [file_without_path]

          allow(STDOUT).to receive(:puts)
          expect { CbxLoco::Extractor.new.run }.to raise_error SystemExit
          expect(STDOUT).to have_received(:puts).with(expected_output)
        end
      end
    end

    it "should delete old files" do
      CbxLoco::Extractor.new.run
      expect(File).to have_received(:unlink).once
    end

    it "should run before_extract" do
      CbxLoco::Extractor.new.run
      expect(@before_extract_call).to be true
    end

    it "should extract assets with tags" do
      expected_value = {
        "Some asset" => { tags: %w[testclient-testfrontend] },
        "Some other asset" => { tags: %w[testclient-testfrontend] },
        "cbx.some_asset" => { tags: %w[testserver-testcbx testserver-testdevise], id: "cbx.some_asset" },
        "cbx.some_asset_with_a_really_long_name_that_exceeds_locos_100_character_limit_to_asset_names_because_we_want_everything_to_work_properly" => { tags: %w[testserver-testcbx testserver-testdevise], id: "cbx.some_asset_with_a_really_long_name_that_exceeds_locos_100_character_limit_to_asset_names_because_we_want_everything_to_work_properly" },
        "cbx.some_other_asset" => { tags: %w[testserver-testcbx testserver-testdevise], id: "cbx.some_other_asset" }
      }
      instance = CbxLoco::Extractor.new
      instance.run
      expect(instance.instance_variable_get(:@assets)).to eq expected_value
    end

    it "should get the list of existing assets on Loco" do
      CbxLoco::Extractor.new.run
      expect(CbxLoco::Adapter).to have_received(:get).with("assets.json")
    end

    it "should upload non-existing assets to Loco" do
      CbxLoco::Extractor.new.run
      expect(CbxLoco::Adapter).to have_received(:post).with("assets.json", anything).twice
    end

    it "should upload non-existing asset tags to Loco" do
      CbxLoco::Extractor.new.run
      expect(CbxLoco::Adapter).to have_received(:post).with(%r[assets/.*/tags\.json], anything).exactly(5).times
    end
  end
end

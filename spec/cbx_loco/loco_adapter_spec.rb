require "spec_helper"

describe CbxLoco::LocoAdapter do
  def rand_str
    ("a".."z").to_a.sample(16).join
  end

  def create_files
    @fake_i18n_files.each do |i18n_file|
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
      "test_server" => "en:\n  cbx:\n    some_asset:\n    some_other_asset:",
      "test_client" => @pot_header + "msgid \"Some asset\"\nmsgstr \"\"\n\nmsgid \"Some other asset\"\nmsgstr \"\"\n"
    }
    @fake_api_key = "abcd1234"
    @fake_api_url = "http://example.com/api/"
    @fake_languages = %w[en fr]

    @str_response = rand_str
    @str_json = "{\"test\": \"#{@str_response}\"}"
  end

  before(:each) do
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

  describe "get" do
    before(:each) do
      allow(RestClient).to receive(:get).and_return(double(body: @str_json))
    end

    it "should call RestClient.get" do
      CbxLoco::LocoAdapter.get("test")
      expect(RestClient).to have_received(:get)
    end

    it "should build the request URL" do
      random_str = rand_str
      CbxLoco::LocoAdapter.get(random_str)
      expect(RestClient).to have_received(:get).with("#{@fake_api_url}#{random_str}", anything)
    end

    it "should build the request parameters" do
      cur_datetime = Time.parse "2016-12-25"
      allow(Time).to receive(:now).and_return(cur_datetime)
      random_sym = rand_str.to_sym
      random_str = rand_str
      CbxLoco::LocoAdapter.get("test", random_sym => random_str)
      expect(RestClient).to have_received(:get).with(anything, params: { key: @fake_api_key, random_sym => random_str, ts: cur_datetime })
    end

    it "should prevent overriding the API key" do
      cur_datetime = Time.parse "2016-12-25"
      allow(Time).to receive(:now).and_return(cur_datetime)
      random_str = rand_str
      CbxLoco::LocoAdapter.get("test", key: random_str)
      expect(RestClient).to have_received(:get).with(anything, params: { key: @fake_api_key, ts: cur_datetime })
    end

    context "with json undefined or true" do
      it "should parse the response body" do
        expect(CbxLoco::LocoAdapter.get("test")).to eq "test" => @str_response
        expect(CbxLoco::LocoAdapter.get("test", {}, true)).to eq "test" => @str_response
      end
    end

    context "with json false" do
      it "should not parse the response body" do
        expect(CbxLoco::LocoAdapter.get("test", {}, false)).to eq @str_json
      end
    end
  end

  describe "post" do
    before(:each) do
      allow(RestClient).to receive(:post).and_return(double(body: @str_json))
    end

    it "should call RestClient.post" do
      CbxLoco::LocoAdapter.post("test")
      expect(RestClient).to have_received(:post)
    end

    it "should build the request URL" do
      random_str = rand_str
      CbxLoco::LocoAdapter.post(random_str)
      expect(RestClient).to have_received(:post).with("#{@fake_api_url}#{random_str}?key=#{@fake_api_key}", anything)
    end

    it "should use the untouched request parameters" do
      random_sym = rand_str.to_sym
      random_str = rand_str
      CbxLoco::LocoAdapter.post("test", random_sym => random_str)
      expect(RestClient).to have_received(:post).with(anything, random_sym => random_str)
    end
  end

  describe "extract" do
    before(:all) do
      create_files
    end

    before(:each) do
      get_response = [
        { "id" => "cbx.some_other_asset", "name" => "cbx.some_other_asset", "tags" => ["testserver-testcbx"] },
        { "id" => "some-other-asset", "name" => "Some other asset", "tags" => ["testclient-testfrontend"] }
      ]
      allow(CbxLoco::LocoAdapter).to receive(:get).and_return(get_response)
      allow(CbxLoco::LocoAdapter).to receive(:post).and_return("id" => "test", "tags" => [])
      allow(CbxLoco::LocoAdapter).to receive(:`)
      allow(File).to receive(:unlink)
    end

    after(:all) do
      delete_files
    end

    it "should delete old files" do
      CbxLoco::LocoAdapter.extract
      expect(File).to have_received(:unlink).once
    end

    it "should run before_extract" do
      CbxLoco::LocoAdapter.extract
      expect(@before_extract_call).to be true
    end

    it "should extract assets with tags" do
      expected_value = {
        "Some asset" => { tags: %w[testclient-testfrontend] },
        "Some other asset" => { tags: %w[testclient-testfrontend] },
        "cbx.some_asset" => { tags: %w[testserver-testcbx testserver-testdevise], id: "cbx.some_asset" },
        "cbx.some_other_asset" => { tags: %w[testserver-testcbx testserver-testdevise], id: "cbx.some_other_asset" }
      }
      CbxLoco::LocoAdapter.extract
      expect(CbxLoco::LocoAdapter.instance_variable_get(:@assets)).to eq expected_value
    end

    it "should get the list of existing assets on Loco" do
      CbxLoco::LocoAdapter.extract
      expect(CbxLoco::LocoAdapter).to have_received(:get).with("assets.json")
    end

    it "should upload non-existing assets to Loco" do
      CbxLoco::LocoAdapter.extract
      expect(CbxLoco::LocoAdapter).to have_received(:post).with("assets.json", anything).twice
    end

    it "should upload non-existing asset tags to Loco" do
      CbxLoco::LocoAdapter.extract
      expect(CbxLoco::LocoAdapter).to have_received(:post).with(%r[assets/.*/tags\.json], anything).exactly(4).times
    end

    context "with missing API_KEY" do
      before(:each) do
        stub_const("CbxLoco::LocoAdapter::API_KEY", nil)
      end

      it "should not do anything" do
        expect(CbxLoco::LocoAdapter).to_not have_received(:get)
        expect(CbxLoco::LocoAdapter).to_not have_received(:post)
        expect(CbxLoco::LocoAdapter).to_not have_received(:`)
        expect(File).to_not have_received(:unlink)
      end
    end
  end

  describe "import" do
    before(:each) do
      allow(CbxLoco::LocoAdapter).to receive(:get).and_return(@str_response)
      allow(CbxLoco::LocoAdapter).to receive(:`)
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

          expect(CbxLoco::LocoAdapter).to receive(:get).with("export/locale/#{language}.#{api_ext}", api_params, false)
        end
      end

      CbxLoco::LocoAdapter.import
    end

    context "when locale folder does not exist" do
      let!(:mock_file) { double }
      before do
        allow(File).to receive(:directory?).and_return(true)
        allow(File).to receive(:new).and_call_original
      end

      it "should create the folder" do
        not_exist_folder = "./locale/en"
        allow(File).to receive(:directory?).with(not_exist_folder).and_return(false)
        allow(FileUtils).to receive(:mkdir_p).with(not_exist_folder)

        CbxLoco::LocoAdapter.import

        expect(FileUtils).to have_received(:mkdir_p).with(not_exist_folder)
      end
    end

    it "should write API return in language files" do
      CbxLoco::LocoAdapter.import

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
      CbxLoco::LocoAdapter.import
      expect(@after_import_call).to be true
    end

    context "with missing API_KEY" do
      before(:each) do
        stub_const("CbxLoco::LocoAdapter::API_KEY", nil)
      end

      it "should not do anything" do
        expect(CbxLoco::LocoAdapter).to_not have_received(:get)
        expect(CbxLoco::LocoAdapter).to_not have_received(:`)
      end
    end
  end
end

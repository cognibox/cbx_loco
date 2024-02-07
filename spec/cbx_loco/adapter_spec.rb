require "spec_helper"

describe CbxLoco::Adapter do
  let(:str_response) { rand_str }
  let(:str_json) { "{\"test\": \"#{str_response}\"}" }

  before(:each) do
    CbxLoco.configure do |c|
      c.api_key = fake_api_key
      c.api_url = fake_api_url
    end

    suppress_console_output
  end

  describe "get" do
    before(:each) do
      allow(Net::HTTP).to receive(:get).and_return(str_json)
    end

    it "should call Net::HTTP.get" do
      CbxLoco::Adapter.get("test")
      expect(Net::HTTP).to have_received(:get)
    end

    it "should build the request URL" do
      random_str = rand_str
      CbxLoco::Adapter.get(random_str)
      expect(Net::HTTP).to have_received(:get) do |uri|
        expect(uri.to_s).to start_with("#{fake_api_url}#{random_str}")
      end
    end

    context "when api version" do
      it "should send it to get" do
        CbxLoco.configuration.version = "1.0.0"
        CbxLoco::Adapter.get("test")
        get_params = { key: fake_api_key }
        get_params[:v] = CbxLoco.configuration.version
        expect(Net::HTTP).to have_received(:get) do |uri|
          expect(uri.to_s).to include("key=#{fake_api_key}").and(include("v=1.0.0"))
        end
      end
    end

    context "when no api version" do
      it "should not send version" do
        CbxLoco.configuration.version = nil
        CbxLoco::Adapter.get("test")
        get_params = { key: fake_api_key }
        expect(Net::HTTP).to have_received(:get) do |uri|
          expect(uri.to_s).to include("key=#{fake_api_key}")
          expect(uri.to_s).not_to include("v=")
        end
      end
    end

    it "should build the request parameters" do
      random_sym = rand_str.to_sym
      random_str = rand_str
      CbxLoco::Adapter.get("test", random_sym => random_str)
      get_params = { key: fake_api_key, random_sym => random_str }
      get_params[:v] = CbxLoco.configuration.version if CbxLoco.configuration.version.present?
      expect(Net::HTTP).to have_received(:get) do |uri|
        expect(uri.to_s).to include("key=#{fake_api_key}").and(include("#{random_sym}=#{random_str}"))
        expect(uri.to_s).to include("v=#{CbxLoco.configuration.version}") if CbxLoco.configuration.version.present?
      end
    end

    it "should prevent overriding the API key" do
      random_str = rand_str
      CbxLoco::Adapter.get("test", key: random_str)
      get_params = { key: fake_api_key }
      get_params[:v] = CbxLoco.configuration.version if CbxLoco.configuration.version.present?
      expect(Net::HTTP).to have_received(:get) do |uri|
        expect(uri.to_s).to include("key=#{fake_api_key}")
      end
    end

    context "with json undefined or true" do
      it "should parse the response body" do
        expect(CbxLoco::Adapter.get("test")).to eq "test" => str_response
        expect(CbxLoco::Adapter.get("test", {}, true)).to eq "test" => str_response
      end
    end

    context "with json false" do
      it "should not parse the response body" do
        expect(CbxLoco::Adapter.get("test", {}, false)).to eq str_json
      end
    end
  end

  describe "post" do
    before(:each) do
      allow(Net::HTTP).to receive(:post).and_return(double(body: str_json))
    end

    it "should call Net::HTTP.post" do
      CbxLoco::Adapter.post("test")
      expect(Net::HTTP).to have_received(:post)
    end

    it "should build the request URL" do
      random_str = rand_str
      CbxLoco::Adapter.post(random_str)
      expect(Net::HTTP).to have_received(:post) do |uri, _data|
        expect(uri.to_s).to eq("#{fake_api_url}#{random_str}?key=#{fake_api_key}")
      end
    end

    it "should use the untouched request parameters" do
      random_sym = rand_str.to_sym
      random_str = rand_str
      CbxLoco::Adapter.post("test", random_sym => random_str)
      expect(Net::HTTP).to have_received(:post) do |_uri, data|
        expect(data).to eq("#{random_sym}=#{random_str}")
      end
    end
  end
end

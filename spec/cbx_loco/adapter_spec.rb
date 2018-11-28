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
      allow(RestClient).to receive(:get).and_return(double(body: str_json))
    end

    it "should call RestClient.get" do
      CbxLoco::Adapter.get("test")
      expect(RestClient).to have_received(:get)
    end

    it "should build the request URL" do
      random_str = rand_str
      CbxLoco::Adapter.get(random_str)
      expect(RestClient).to have_received(:get).with("#{fake_api_url}#{random_str}", anything)
    end

    context "when api version" do
      it "should send it to get" do
        cur_datetime = Time.parse "2016-12-25"
        allow(Time).to receive(:now).and_return(cur_datetime)
        CbxLoco.configuration.version = "1.0.0"
        CbxLoco::Adapter.get("test")
        get_params = { key: fake_api_key, ts: cur_datetime }
        get_params[:v] = CbxLoco.configuration.version
        expect(RestClient).to have_received(:get).with(anything, params: get_params)
      end
    end

    context "when no api version" do
      it "should not send version" do
        cur_datetime = Time.parse "2016-12-25"
        allow(Time).to receive(:now).and_return(cur_datetime)
        CbxLoco.configuration.version = nil
        CbxLoco::Adapter.get("test")
        get_params = { key: fake_api_key, ts: cur_datetime }
        expect(RestClient).to have_received(:get).with(anything, params: get_params)
      end
    end

    it "should build the request parameters" do
      cur_datetime = Time.parse "2016-12-25"
      allow(Time).to receive(:now).and_return(cur_datetime)
      random_sym = rand_str.to_sym
      random_str = rand_str
      CbxLoco::Adapter.get("test", random_sym => random_str)
      get_params = { key: fake_api_key, ts: cur_datetime, random_sym => random_str }
      get_params[:v] = CbxLoco.configuration.version if CbxLoco.configuration.version.present?
      expect(RestClient).to have_received(:get).with(anything, params: get_params)
    end

    it "should prevent overriding the API key" do
      cur_datetime = Time.parse "2016-12-25"
      allow(Time).to receive(:now).and_return(cur_datetime)
      random_str = rand_str
      CbxLoco::Adapter.get("test", key: random_str)
      get_params = { key: fake_api_key, ts: cur_datetime }
      get_params[:v] = CbxLoco.configuration.version if CbxLoco.configuration.version.present?
      expect(RestClient).to have_received(:get).with(anything, params: get_params)
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
      allow(RestClient).to receive(:post).and_return(double(body: str_json))
    end

    it "should call RestClient.post" do
      CbxLoco::Adapter.post("test")
      expect(RestClient).to have_received(:post)
    end

    it "should build the request URL" do
      random_str = rand_str
      CbxLoco::Adapter.post(random_str)
      expect(RestClient).to have_received(:post).with("#{fake_api_url}#{random_str}?key=#{fake_api_key}", anything)
    end

    it "should use the untouched request parameters" do
      random_sym = rand_str.to_sym
      random_str = rand_str
      CbxLoco::Adapter.post("test", random_sym => random_str)
      expect(RestClient).to have_received(:post).with(anything, random_sym => random_str)
    end
  end
end

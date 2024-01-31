require "spec_helper"
require "json"
require "net/http"


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
      http_double = instance_double(Net::HTTP)
      allow(http_double).to receive(:use_ssl=)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      response_double = instance_double(Net::HTTPResponse, body: str_json)
      allow(http_double).to receive(:request).and_return(response_double)
    end

    it "sends a GET request and parses the JSON response by default" do
      result = CbxLoco::Adapter.get("test")

      expect(result).to eq("test" => str_response)
    end

    it "sends a GET request and returns the raw response body if json is false" do
      get_params = {  key1: "value1", key2: "value2" }
      result = CbxLoco::Adapter.get("test", get_params, false)

      expect(result).to eq(str_json)
    end

    it "should build the request URL" do
      random_str = rand_str
      result = CbxLoco::Adapter.get(random_str)
      expect(result).to eq "test" => str_response
    end

    context "when api version" do
      it "should send it to get" do
        CbxLoco.configuration.version = "1.0.0"
        get_params = { key: fake_api_key, v: "1.0.0" }
        allow(URI).to receive(:encode_www_form)
        result = CbxLoco::Adapter.get("test")

        expect(URI).to have_received(:encode_www_form).with(get_params)
      end
    end

    context "when no api version" do
      it "should not send version" do
        CbxLoco.configuration.version = nil
        get_params = { key: fake_api_key }
        allow(URI).to receive(:encode_www_form)
        result = CbxLoco::Adapter.get("test")

        expect(URI).to have_received(:encode_www_form).with(get_params)
      end
    end

    it "should build the request parameters" do
      random_sym = rand_str.to_sym
      random_str = rand_str
      allow(URI).to receive(:encode_www_form)
      result = CbxLoco::Adapter.get("test", random_sym => random_str)
      get_params = { key: fake_api_key, random_sym => random_str }
      get_params[:v] = CbxLoco.configuration.version if CbxLoco.configuration.version.present?

      expect(URI).to have_received(:encode_www_form).with(get_params)
    end

    it "should prevent overriding the API key" do
      random_str = rand_str
      allow(URI).to receive(:encode_www_form)
      CbxLoco::Adapter.get("test", key: random_str)
      get_params = { key: fake_api_key }
      get_params[:v] = CbxLoco.configuration.version if CbxLoco.configuration.version.present?

      expect(URI).to have_received(:encode_www_form).with(get_params)
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
    it 'sends the correct request and parses the response' do
      expected_url = "#{fake_api_url}test"
      response_body = '{"key": "value"}'

      uri = URI.parse(expected_url)

      http_double = double("http", request: double("request", body: response_body))
      allow(Net::HTTP).to receive(:new).and_return(http_double)

      expect(http_double).to receive(:request).with(an_instance_of(Net::HTTP::Get)) do |request_arg|
        expect(request_arg.path).to eq(uri.path)
        expect(request_arg.body).to eq(URI.encode_www_form(params))
      end
    end
  end

  describe "post" do
    before(:each) do
      http_double = instance_double(Net::HTTP, request: double(body: '{"result": "success"}'))
      allow(http_double).to receive(:use_ssl=)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
    end

    it "sends a POST request and parses the JSON response" do
      result = CbxLoco::Adapter.post("test")

      expect(Net::HTTP).to have_received(:new).with("example.com", 80)
      expect(result).to eq("result" => "success")
    end

    it "should use the untouched request parameters" do
      request_double = instance_double(Net::HTTP::Post, set_form_data: nil)
      allow(Net::HTTP::Post).to receive(:new).and_return(request_double)

      random_sym = rand_str.to_sym
      random_str = rand_str

      CbxLoco::Adapter.post("test",  random_sym => random_str)

      expect(request_double).to have_received(:set_form_data).with(random_sym => random_str)
    end
  end
end

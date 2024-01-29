require "spec_helper"
require 'json'
require 'net/http'


describe CbxLoco::Adapter do
  let(:str_response) { rand_str }
  let(:str_json) { "{\"test\": \"#{str_response}\"}" }
  let(:params) { { key1: 'value1', key2: 'value2' } }
  let(:api_path) { '/api/path' }

  before(:each) do
    CbxLoco.configure do |c|
      c.api_key = fake_api_key
      c.api_url = fake_api_url
    end

    suppress_console_output
  end

  describe "get" do
    before(:each) do
      uri = URI.parse(fake_api_url + api_path)
      allow(URI).to receive(:parse).and_return(uri)
      allow(uri).to receive(:query=)

      http_double = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:use_ssl=)

      request_double = instance_double(Net::HTTP::Get)
      allow(Net::HTTP::Get).to receive(:new).and_return(request_double)

      response_double = instance_double(Net::HTTPResponse, body: str_json)
      allow(http_double).to receive(:request).and_return(response_double)
    end

    it 'sends a GET request and parses the JSON response by default' do
      result = CbxLoco::Adapter.get(api_path, params)

      expect(result).to eq('test' => str_response)
    end

    it 'sends a GET request and returns the raw response body if json is false' do
      result = CbxLoco::Adapter.get(api_path, params, false)

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
        get_params = { key: fake_api_key, v: '1.0.0' }
        allow(URI).to receive(:encode_www_form)
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(double(body: ''))

        CbxLoco::Adapter.get(api_path)

        expect(URI).to have_received(:encode_www_form).with(get_params)
      end
    end

    context "when no api version" do
      it "should not send version" do
        CbxLoco.configuration.version = nil
        get_params = { key: fake_api_key }
        allow(URI).to receive(:encode_www_form)
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(double(body: ''))

        CbxLoco::Adapter.get(api_path)

        expect(URI).to have_received(:encode_www_form).with(get_params)
      end
    end

    it "should build the request parameters" do
      random_sym = rand_str.to_sym
      random_str = rand_str
      allow(URI).to receive(:encode_www_form)
      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(double(body: ''))
      CbxLoco::Adapter.get("test", random_sym => random_str)
      get_params = { key: fake_api_key, random_sym => random_str }
      get_params[:v] = CbxLoco.configuration.version if CbxLoco.configuration.version.present?

      expect(URI).to have_received(:encode_www_form).with(get_params)
    end

    it "should prevent overriding the API key" do
      random_str = rand_str
      allow(URI).to receive(:encode_www_form)
      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(double(body: ''))
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
  end

  describe "post" do
    it 'sends a POST request and parses the JSON response' do
      get_params = { param1: 'value1', param2: 'value2' }
      http_double = instance_double(Net::HTTP)

      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:use_ssl=)
      allow_any_instance_of(Net::HTTP::Post).to receive(:set_form_data)
      allow(http_double).to receive(:request).and_return(double(body: '{"result": "success"}'))

      result = CbxLoco::Adapter.post(api_path, get_params)

      expect(Net::HTTP).to have_received(:new).with('example.com', 80).once

      expect(http_double).to have_received(:use_ssl=).with(true).once  if URI.parse(fake_api_url).scheme == 'https'

      expect(http_double).to have_received(:request).once do |request|
        expect(request).to be_a(Net::HTTP::Post)
        expect(request.path).to start_with(api_path)
      end
      expect(result).to eq('result' => 'success')
    end
  end
end

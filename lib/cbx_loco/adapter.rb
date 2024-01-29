require 'json'
require 'net/http'
require 'uri'

class CbxLoco::Adapter
  def self.get(api_path, params = {}, json = true)
    params = params.merge(key: CbxLoco.configuration.api_key)
    params = params.merge(v: CbxLoco.configuration.version) if CbxLoco.configuration.version

    uri = URI.parse(CbxLoco.configuration.api_url + api_path)
    uri.query = URI.encode_www_form(params)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    request = Net::HTTP::Get.new(uri)
    res = http.request(request)

    json ? JSON.parse(res.body) : res.body
  end

  def self.post(api_path, params = {})
    uri = URI.parse(CbxLoco.configuration.api_url + api_path)
    uri.query = "?key=#{CbxLoco.configuration.api_key}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    request = Net::HTTP::Post.new(uri)
    request.set_form_data(params)

    res = http.request(request)

    JSON.parse res.body
  end
end

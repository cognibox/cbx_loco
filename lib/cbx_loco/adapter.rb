require 'json'
require 'net/http'
require 'uri'

class CbxLoco::Adapter
  def self.get(api_path, params = {}, json = true)
    params = params.merge(key: CbxLoco.configuration.api_key)
    params = params.merge(v: CbxLoco.configuration.version) if CbxLoco.configuration.version

    res = Net::HTTP.get(URI(CbxLoco.configuration.api_url + api_path + "?#{URI.encode_www_form(params)}"))

    json ? JSON.parse(res) : res
  end

  def self.post(api_path, params = {})
    res = Net::HTTP.post(URI(CbxLoco.configuration.api_url + api_path + "?key=#{CbxLoco.configuration.api_key}"), URI.encode_www_form(params))

    JSON.parse res.body
  end
end

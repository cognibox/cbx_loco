require 'rest-client'
require 'json'

class CbxLoco::Adapter
  def self.get(api_path, params = {}, json = true)
    params = params.merge(key: CbxLoco.configuration.api_key)
    params = params.merge(v: CbxLoco.configuration.version) if CbxLoco.configuration.version
    res = RestClient.get CbxLoco.configuration.api_url + api_path, params: params

    json ? JSON.parse(res.body) : res.body
  end

  def self.post(api_path, params = {})
    res = RestClient.post CbxLoco.configuration.api_url + api_path + "?key=#{CbxLoco.configuration.api_key}", params

    JSON.parse res.body
  end
end

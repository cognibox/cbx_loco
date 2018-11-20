require "cbx_loco"
require "rspec"

RSpec.configure do |config|
end

CbxLoco.configuration.root = "."

def suppress_console_output
  allow(STDOUT).to receive(:puts)
  allow(STDOUT).to receive(:write)
end

def rand_str
  ("a".."z").to_a.sample(16).join
end

def fake_api_key
  "abcd1234"
end

def fake_api_url
  "http://example.com/api/"
end

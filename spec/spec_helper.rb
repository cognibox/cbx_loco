require "cbx_loco"
require "rspec"

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../lib/cbx_loco", __FILE__)

# RSpec.configure do |config|
# end

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
  "http://example.com"
end

def create_file(content, path)
  file_path = CbxLoco.file_path path

  f = File.new file_path, "w:UTF-8"
  f.write content.force_encoding("UTF-8")
  f.close
end

def delete_file(path)
  File.unlink CbxLoco.file_path path if File.file? path
end

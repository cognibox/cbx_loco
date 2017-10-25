require "cbx_loco"
require "rspec"

RSpec.configure do |config|
end

CbxLoco.configuration.root = "."

def suppress_console_output
  allow(STDOUT).to receive(:puts)
  allow(STDOUT).to receive(:write)
end

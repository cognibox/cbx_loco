require 'active_support'
require 'active_support/core_ext'
require "cbx_loco/version"
require 'cbx_loco/configuration'
require 'cbx_loco/extract_adapter'
require 'cbx_loco/loco_adapter'

module CbxLoco
  require 'cbx_loco/railtie' if defined?(Rails)

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    config = configuration
    yield(config)
  end

  def self.run(command)
    if command[:extract]
      LocoAdapter.extract
    end

    if command[:import]
      LocoAdapter.import
    end
  end
end

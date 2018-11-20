require 'active_support'
require 'active_support/core_ext'
require "cbx_loco/version"
require 'cbx_loco/configuration'
require 'cbx_loco/extract_adapter'
require 'cbx_loco/importer'
require 'cbx_loco/extracter'
require 'cbx_loco/adapter'

module CbxLoco
  require 'cbx_loco/railtie' if defined?(Rails)

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.asset_tag(*args)
    args.join("-").gsub(/[^a-z,-]/i, "")
  end

  def self.flatten_hash(data_hash, parent = [])
    data_hash.flat_map do |key, value|
      case value
      when Hash then flatten_hash value, parent + [key]
      else (parent + [key]).join(".")
      end
    end
  end

  def self.file_path(*args)
    File.join(CbxLoco.configuration.root.to_s, *args).to_s
  end

  def self.configure
    config = configuration
    yield(config)
  end

  def self.valid_api_key?
    valid = CbxLoco.configuration.api_key.present?
    unless valid
      puts "MISSING I18N API KEY. ABORTING.".colorize(:red).bold
      exit(1)
    end

    valid
  end

  def self.run(command)
    return unless valid_api_key?

    if command[:extract]
      Extracter.new.run
    end

    if command[:import]
      Importer.new.run
    end
  end
end

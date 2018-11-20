require 'cbx_loco/event'

class CbxLoco::Configuration < CbxLoco::Event
  attr_accessor :api_key
  attr_accessor :api_url
  attr_accessor :file_formats
  attr_accessor :i18n_files
  attr_accessor :languages
  attr_accessor :version
  attr_accessor :root

  def initialize
    super

    # initialize default values
    @api_key = nil
    @api_url = "https://localise.biz:443/api/"
    @root = "."
    @version = nil
    @file_formats = {}
    @i18n_files = []
    @languages = []
  end
end

module CbxLoco
  class Configuration
    attr_accessor :api_key
    attr_accessor :api_url
    attr_accessor :file_formats
    attr_accessor :i18n_files
    attr_accessor :languages
    attr_accessor :version
    attr_accessor :root

    def initialize
      # initialize default values
      @api_key = nil
      @tasks = {}
      @api_url = "https://localise.biz:443/api/"
      @root = "."
      @version = nil
      @file_formats = {}
      @i18n_files = []
      @languages = []
    end

    def on(event, &block)
      @tasks[event] = [] if !@tasks[event].kind_of?(Array)
      @tasks[event].push(block)
    end

    def tasks
      @tasks
    end
  end
end

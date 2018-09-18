module CbxLoco
  class ExtractAdapter
    def initialize(assets)
      @assets = assets
    end

    def grab_existing_assets
      return @existing_assets if @existing_assets

      @existing_assets = {}


      version = "1.0.19".delete(".").to_i
      new_version = Configuration.version.nil? || (Configuration.version.gsub(".", "").to_i > version)

      @assets.each do |asset|
        if new_version
          @existing_assets[asset["aliases"]["name"]] = { id: asset["id"], tags: asset["tags"] }
        else
          @existing_assets[asset["name"]] = { id: asset["id"], tags: asset["tags"] }
        end
      end

      @assets = nil
      @existing_assets
    end
  end
end

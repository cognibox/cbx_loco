class CbxLoco::ExtractAdapter
  def initialize(assets)
    @assets = assets
  end

  def grab_existing_assets
    existing_assets = {}

    new_version = CbxLoco.configuration.version.nil? || (Gem::Version.new(CbxLoco.configuration.version) > Gem::Version.new("1.0.19"))
    @assets.each do |asset|
      if new_version
        existing_assets[asset["aliases"]["name"]] = { id: asset["id"], tags: asset["tags"] }
      else
        existing_assets[asset["name"]] = { id: asset["id"], tags: asset["tags"] }
      end
    end

    @assets = nil
    existing_assets
  end
end

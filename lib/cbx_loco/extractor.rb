require 'time'
require 'json'
require 'yaml'
require 'colorize'
require 'get_pomo'
require 'fileutils'
require 'cbx_loco/utils'

class CbxLoco::Extractor
  def run
    puts "\n" + "Extract i18n assets".colorize(:green).bold

    puts "Removing old files... "
    CbxLoco.configuration.i18n_files.each do |i18n_file|
      fmt = CbxLoco.configuration.file_formats[i18n_file[:format]]

      next unless fmt[:delete]

      path = fmt[:path]
      src_ext = fmt[:src_ext]

      if path.blank? || src_ext.blank?
        CbxLoco::Utils.print_error "path or src_ext is not provided for name: '#{i18n_file[:name]}', id: '#{i18n_file[:id]}', format: '#{i18n_file[:format]}'"
        exit(1)
      end

      i18n_file_path = CbxLoco.file_path path, [i18n_file[:name], src_ext].join(".")

      tag = CbxLoco.asset_tag i18n_file[:id], i18n_file[:name]
      puts "Removing old assets #{tag}"
      File.unlink i18n_file_path if File.file?(i18n_file_path)
    end
    puts "Done!".colorize(:green).bold

    CbxLoco.configuration.emit :before_extract

    @assets = {}
    CbxLoco.configuration.i18n_files.each do |i18n_file|
      fmt = CbxLoco.configuration.file_formats[i18n_file[:format]]

      next unless fmt[:extractable]

      path = fmt[:path]
      src_ext = fmt[:src_ext]

      case i18n_file[:format]
      when :gettext
        file_path = CbxLoco.file_path path, [i18n_file[:name], src_ext].join(".")
        translations = GetPomo::PoFile.parse File.read(file_path)
        msgids = translations.reject { |t| t.msgid.blank? }.map(&:msgid)
      when :yaml
        language = CbxLoco.configuration.languages.first
        file_path = CbxLoco.file_path path, [i18n_file[:name], language, src_ext].join(".")
        translations = YAML.load_file file_path
        msgids = CbxLoco.flatten_hash(translations[language])
      else
        CbxLoco::Utils.print_error "#{i18n_file[:format]} IS NOT SUPPORTED FOR EXTRACTION"
        next
      end

      msgids.each do |msgid|
        if msgid.is_a? Array
          # we have a plural (get text only)
          singular = msgid[0]
          plural = msgid[1]

          # add the singular
          @assets[singular] = { tags: [] } if @assets[singular].nil?
          @assets[singular][:tags] << CbxLoco.asset_tag(i18n_file[:id], i18n_file[:name])

          # add the plural
          @assets[plural] = { tags: [] } if @assets[plural].nil?
          @assets[plural][:singular_id] = singular
          @assets[plural][:tags] << CbxLoco.asset_tag(i18n_file[:id], i18n_file[:name])
        else
          @assets[msgid] = { tags: [] } if @assets[msgid].nil?
          @assets[msgid][:id] = msgid if i18n_file[:format] == :yaml
          @assets[msgid][:tags] << CbxLoco.asset_tag(i18n_file[:id], i18n_file[:name])
        end
      end
    end

    puts "\n" + "Upload i18n assets to Loco".colorize(:green).bold
    begin
      print "Grabbing the list of existing assets... "
      res = CbxLoco::Adapter.get "assets.json"

      existing_assets = CbxLoco::ExtractAdapter.new(res).grab_existing_assets
      res = nil

      puts "Done!".colorize(:green)

      @assets.each do |asset_name, asset|
        trimmed_asset_name = asset_name.length > 100 ? asset_name[0..96] + "..." : asset_name
        existing_asset = existing_assets[trimmed_asset_name] || existing_assets[asset_name]

        if existing_asset.nil?
          print_asset_name = asset_name.length > 50 ? asset_name[0..46] + "[...]" : asset_name
          print "Uploading asset: \"#{print_asset_name}\"... "

          asset_hash = { name: asset_name, type: "text" }

          if !asset[:singular_id].blank?
            singular_id = existing_assets[asset[:singular_id]][:id]
            res = CbxLoco::Adapter.post "assets/#{singular_id}/plurals.json", asset_hash
          else
            asset_hash[:id] = asset_name if asset[:id]
            res = CbxLoco::Adapter.post "assets.json", asset_hash
          end

          existing_asset = { id: res["id"], tags: res["tags"] }
          existing_assets[trimmed_asset_name] = existing_asset
          puts "Done!".colorize(:green)
        end

        new_tags = asset[:tags] - existing_asset[:tags]
        new_tags.each do |tag|
          print_asset_id = existing_asset[:id].length > 30 ? existing_asset[:id][0..26] + "[...]" : existing_asset[:id]
          print "Uploading tag \"#{tag}\" for asset: \"#{print_asset_id}\"... "
          CbxLoco::Adapter.post "assets/#{URI.escape(existing_asset[:id])}/tags.json", name: tag
          puts "Done!".colorize(:green)
        end
      end

      puts "\n" + "All done!".colorize(:green).bold
    rescue => e
      res = JSON.parse e.response
      CbxLoco::Utils.print_error "Upload to Loco failed: #{e.message}: #{res["error"]}"
    end
  end
end

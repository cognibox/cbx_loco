require 'time'

require 'cbx_loco/utils'
require 'cbx_loco/extention'
require 'cbx_loco/extention/yaml'
require 'cbx_loco/extention/json'
require 'cbx_loco/extention/gettext'

class CbxLoco::Importer
  def run
    CbxLoco::Utils.print_success "Import i18n assets from Loco"

    begin
      CbxLoco.configuration.i18n_files.each do |i18n_file|
        extention_class = "CbxLoco::Extention::#{i18n_file[:format].to_s.camelize}".constantize
        extention_instance = extention_class.new

        fmt = CbxLoco.configuration.file_formats[i18n_file[:format]]
        tag = CbxLoco.asset_tag i18n_file[:id], i18n_file[:name]
        api_params = { filter: tag, order: :id, format: fmt[:format] }

        if (fmt[:import_params].is_a?(Hash))
          api_params = api_params.merge(fmt[:import_params])
        end

        download_params = {
          fmt: fmt,
          i18n_file: i18n_file,
          tag: tag,
          api_params: api_params
        }

        extention_instance.download(download_params)
      end

      CbxLoco.configuration.emit :after_import

    rescue Errno::ENOENT => e
      CbxLoco::Utils.print_error "Caught the exception: #{e}"
    rescue Exceptions::NotBundleable => e
      CbxLoco::Utils.print_error "The file format #{extention_class.name.split('::').last} can't be bundled. Please change the bundle options to 'false'"
    rescue => e
      CbxLoco::Utils.print_error "Caught the exception: #{e}"
    end
  end
end

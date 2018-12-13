require 'rest-client'
require 'time'
require 'json'
require 'yaml'
require 'colorize'
require 'get_pomo'
require 'fileutils'

class CbxLoco::Importer
    def run
      puts "\n" + "Import i18n assets from Loco".colorize(:green).bold

      begin
        CbxLoco.configuration.i18n_files.each do |i18n_file|
          CbxLoco.configuration.languages.each do |language|
            fmt = CbxLoco.configuration.file_formats[i18n_file[:format]]
            path = fmt[:path]
            dst_ext = fmt[:dst_ext]
            api_ext = fmt[:api_ext]
            tag = CbxLoco.asset_tag i18n_file[:id], i18n_file[:name]


            api_params = { filter: tag, order: :id }
            case i18n_file[:format]
            when :gettext
              api_params[:index] = "name"
              file_path = CbxLoco.file_path path, language, [i18n_file[:name], dst_ext].join(".")
            when :yaml
              api_params[:format] = "rails"
              file_path = CbxLoco.file_path path, [i18n_file[:name], language, dst_ext].join(".")
            end

            translations = CbxLoco::Adapter.get "export/locale/#{language}.#{api_ext}", api_params, false

            dirname = File.dirname(file_path)
            create_directory(dirname) unless File.directory?(dirname)

            print "Importing \"#{language}\" #{tag} assets... "
            f = File.new file_path, "w:UTF-8"
            f.write translations.force_encoding("UTF-8")
            f.close

            if i18n_file[:format] == :yaml
              begin
                YAML.load_file(file_path)
              rescue Exception
                puts "\n\nFILE ERROR: \"#{language}\" #{tag} is not YAML or is invalid:\n#{$!}\n\n"
                exit(1)
              end
            end

            puts "Done!".colorize(:green)
          end
        end

        CbxLoco.configuration.emit :after_import

      rescue Errno::ENOENT => e
        print_error "Caught the exception: #{e}"
      rescue => e
        translations = {}
        GetPomo::PoFile.parse(e.response).each do |t|
          translations[t.msgid] = t.msgstr unless t.msgid.blank?
        end
        print_error "Download from Loco failed: #{translations["status"]}: #{translations["error"]}"
      end
    end

    private

    def save_file(extention_class:, fmt:, i18n_file:, language:, tag:, translations:)
      if (fmt[:import_file_name].respond_to?(:call))
        file_path = CbxLoco.file_path *(fmt[:import_file_name].call(language, fmt, i18n_file))
      else
        puts "\n\nERROR: import_file_name is not set into file_formats[:#{i18n_file[:format]}] \n\n"
        exit(1)
      end

      dirname = File.dirname(file_path)
      create_directory(dirname) unless File.directory?(dirname)

      language_display = language ? " \"#{language}\"" : ""
      puts "Importing#{language_display} #{tag}"
      puts "path: #{file_path}"
      print "assets... "
      extention_class.new.export file_path: file_path, translations: translations, language: language
      puts "Done!".colorize(:green)
    end

    def create_directory(path)
      print "Creating \"#{path}\" folder... "

      FileUtils.mkdir_p(path)
      puts "Done!".colorize(:green)

      print "Creating \".keep\" file... "
      file_path = File.join path, ".keep"
      FileUtils.touch(file_path)

      puts "Done!".colorize(:green)
    end

    def print_error(message)
      puts "\n\n" + message.colorize(:red).bold
    end
end

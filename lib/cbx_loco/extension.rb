require 'cbx_loco/exceptions'
require 'cbx_loco/utils'

class CbxLoco::Extension
   def download(fmt:, i18n_file:, tag:, api_params:)
    puts "Downloading: #{tag}"

    if fmt[:bundle]
      if options[:bundleable?] == false
        raise Exceptions::NotBundleable
      end
    end

    download_from_zip(api_ext: fmt[:api_ext], api_params: api_params)
    save_translations(fmt: fmt, i18n_file: i18n_file, tag: tag)
  end

  def options
    @options ||= {
      bundleable?: true
    }
  end

  def validate(_file_path)
    # leave empty
  end

  private

  def bundle_translations
    @translations
  end

  def download_from_zip(api_ext:, api_params:)
    @translations = {}
    input = CbxLoco::Adapter.get "export/archive/#{api_ext}.zip", api_params, false
    Zip::InputStream.open(StringIO.new(input)) do |io|
      while entry = io.get_next_entry
        # Find the locale name in the file path
        locale = entry.name.match(/archive\/locales?\/([a-z]+).*/i)
        next if locale.nil?
        @translations[locale[1]] = io.read
      end
    end

    @translations
  end

  def export(file_path:, translations:)
    file = File.new(file_path, "w:UTF-8")
    file.write(translations.force_encoding("UTF-8"))
    file.close

    validate file_path
  end

  def save_file(fmt:, i18n_file:, tag:, translations:, locale: nil)
    if (fmt[:import_file_name].respond_to?(:call))
      file_path = CbxLoco.file_path *(fmt[:import_file_name].call(locale: locale, fmt: fmt, i18n_file: i18n_file))
    else
      puts "\n\nERROR: import_file_name is not set in file_formats[:#{i18n_file[:format]}] \n\n"
      exit(1)
    end

    dirname = File.dirname(file_path)
    CbxLoco::Utils.create_directory(dirname) unless File.directory?(dirname)

    locale_display = locale ? " \"#{locale}\"" : ""
    puts "path: #{file_path}" if ENV["verbose"]
    print "Exporting#{locale_display} #{tag} assets... "
    export file_path: file_path, translations: translations
    puts "Done!".colorize(:green)
  end

  def save_translations(fmt:, i18n_file:, tag:)
    options = {fmt: fmt, i18n_file: i18n_file, tag: tag}

    if fmt[:bundle]
      save_file options.merge(locale: nil, translations: bundle_translations)
    else
      @translations.each do |locale, trs|
        save_file options.merge(locale: locale, translations: trs)
      end
    end
  end
end

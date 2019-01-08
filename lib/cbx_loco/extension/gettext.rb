require 'get_pomo'

class CbxLoco::Extension::Gettext < CbxLoco::Extension
  protected

  def options
    @options ||= { bundleable?: false }
  end

  def validate(file_path)
    begin
      GetPomo::PoFile.parse(File.read(file_path))
    rescue Exception => e
      puts "\n\nFILE ERROR: \"#{file_path}\" is not PO or is invalid:\n#{e}\n\n"
      exit(1)
    end
  end
end

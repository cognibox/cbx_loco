require 'yaml'

class CbxLoco::Extension::Yaml < CbxLoco::Extension
  protected

  def validate(file_path)
    begin
      YAML.load_file(file_path)
    rescue Exception => e
      puts "\n\nFILE ERROR: \"#{file_path}\" is not YAML or is invalid:\n#{e}\n\n"
      exit(1)
    end
  end
end

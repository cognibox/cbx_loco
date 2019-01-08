require 'colorize'
require 'fileutils'

class CbxLoco::Utils
  def self.create_directory(path)
    print "Creating \"#{path}\" folder... "

    FileUtils.mkdir_p(path)
    puts "Done!".colorize(:green)

    print "Creating \".keep\" file... "
    file_path = File.join path, ".keep"
    FileUtils.touch(file_path)

    puts "Done!".colorize(:green)
  end

  def self.print_error(message)
    puts "\n\n" + message.colorize(:red).bold
  end

  def self.print_success(message)
    puts "\n\n" + message.colorize(:green).bold
  end
end

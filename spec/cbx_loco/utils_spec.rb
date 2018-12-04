require "spec_helper"

describe CbxLoco::Utils do
  describe ".create_directory" do
    let(:path) { "folder1/folder2" }

    def delete_path(path)
      File.delete(path + "/.keep")
      Dir.rmdir(path)
    end

    before(:each) { suppress_console_output }

    it "should create directory" do
      CbxLoco::Utils.create_directory path
      expect(File.directory?("folder1")).to be_truthy
      expect(File.directory?("folder1/folder2")).to be_truthy

      delete_path(path)
    end

    it "should create keep file" do
      CbxLoco::Utils.create_directory path
      expect(File.file?(path + "/.keep")).to be_truthy

      delete_path(path)
    end
  end
end

require "spec_helper"

class TestNotBundleableExtension < CbxLoco::Extension
  def options
    @options ||= { bundleable?: false }
  end
end

class TestBundleableExtension < CbxLoco::Extension
  def options
    @options ||= {}
  end
end

describe CbxLoco::Extension do
  before do
    suppress_console_output
  end

  describe "#download" do
    let(:file_name) { "any/file_name" }
    let(:file_name_proc) { double }

    let(:zip_result) { "any result" }
    let(:mocked_file) { double }

    before do
      # allow(zip_result).to receive(:force_encoding) { zip_result }
      allow(file_name_proc).to receive(:call) { file_name }
      allow(CbxLoco).to receive(:file_path) { |arg| arg }
      allow(File).to receive(:directory?).and_return(true)
      allow(File).to receive(:new).and_return(mocked_file)
      allow(mocked_file).to receive(:write)
      allow(mocked_file).to receive(:close)
      allow(CbxLoco::Utils).to receive(:create_directory)
    end

    context "when downloading with bundle" do
      let(:options) { { fmt: { bundle: true, import_file_name: file_name_proc }, i18n_file: {}, tag: "", api_params: {} } }

      context "when file format does not allow to be bundled" do
        it "should raise a NotBundleable" do
          expect { TestNotBundleableExtension.new.download(options) }.to raise_error(Exceptions::NotBundleable)
        end
      end

      context "when file format allow to be bundled" do
        let(:instance) { TestBundleableExtension.new }

        before do
          allow(instance).to receive(:download_from_zip)
          instance.instance_variable_set(:@translations, zip_result)
        end

        it "should download from zip" do
          instance.download(options)
          expect(instance).to have_received(:download_from_zip)
        end

        context "when folder does not exist" do
          it "should create it" do
            dir = File.dirname(file_name)
            allow(File).to receive(:directory?).with(dir).and_return(false)

            instance.download(options)
            expect(CbxLoco::Utils).to have_received(:create_directory).with(dir)
          end
        end

        it "should format the filename with nil locale" do
          instance.download(options)
          expect(file_name_proc).to have_received(:call).with(locale: nil, fmt: options[:fmt], i18n_file: options[:i18n_file])
        end

        context "when folder exists" do
          it "should not create it" do
            dir = File.dirname(file_name)
            allow(File).to receive(:directory?).with(dir).and_return(true)

            instance.download(options)
            expect(CbxLoco::Utils).to_not have_received(:create_directory).with(dir)
          end
        end

        it "should save translations" do
          allow(zip_result).to receive(:force_encoding) { zip_result }
          instance.download(options)
          expect(File).to have_received(:new).with(file_name, "w:UTF-8")
          expect(mocked_file).to have_received(:write).with(zip_result)
          expect(zip_result).to have_received(:force_encoding).with("UTF-8")
        end
      end
    end

    context "when downloading separately" do
      let(:options) { { fmt: { bundle: false, import_file_name: file_name_proc }, i18n_file: {}, tag: "", api_params: {} } }
      let(:zip_result) { { en: "any en", fr: "any fr" } }
      let(:file_names) { { en: "any_folder_en/file_en", fr: "any_folder_fr/file_fr" } }
      let(:instance) { TestNotBundleableExtension.new }

      before do
        allow(instance).to receive(:download_from_zip)
        instance.instance_variable_set(:@translations, zip_result)

        allow(file_name_proc).to receive(:call) do |locale:, fmt:, i18n_file:|
          file_names[locale]
        end
      end

      it "should download from zip" do
        instance.download(options)
        expect(instance).to have_received(:download_from_zip)
      end

      it "should format the filename by locale" do
        instance.download(options)
        zip_result.each do |key, value|
          expect(file_name_proc).to have_received(:call).with(locale: key, fmt: options[:fmt], i18n_file: options[:i18n_file])
        end
      end

      context "when folder does not exist" do
        it "should create it" do
          allow(File).to receive(:directory?).and_return(false)
          instance.download(options)

          file_names.each do |key, value|
            dir = File.dirname(value)
            expect(CbxLoco::Utils).to have_received(:create_directory).with(dir)
          end
        end
      end

      context "when folder exists" do
        it "should not create it" do
          dir = File.dirname(file_name)
          allow(File).to receive(:directory?).with(dir).and_return(true)

          instance.download(options)
          expect(CbxLoco::Utils).to_not have_received(:create_directory).with(dir)
        end
      end

      it "should save translations" do
        zip_result.each do |key, value|
          allow(value).to receive(:force_encoding) { value }
        end

        instance.download(options)

        file_names.each do |key, value|
          expect(File).to have_received(:new).with(value, "w:UTF-8")
          expect(mocked_file).to have_received(:write).with(zip_result[key])
          expect(zip_result[key]).to have_received(:force_encoding).with("UTF-8")
        end
      end

      it "should validate the created file" do
        allow(instance).to receive(:validate)
        instance.download(options)

        file_names.each do |key, value|
          expect(instance).to have_received(:validate).with(value)
        end
      end
    end
  end
end

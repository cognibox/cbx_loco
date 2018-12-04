require "spec_helper"

class TestNotBundleableExtention < CbxLoco::Extention
  def options
    @options ||= {
      bundleable?: false
    }
  end
end

class TestBundleableExtention < CbxLoco::Extention
  def options
    @options ||= {
    }
  end
end

describe CbxLoco::Extention do

  describe "#download" do
    context "when downloading with bundle" do
      let(:options) { { fmt: { bundle: true }, i18n_file: {}, tag: "" } }
      context "when file format does not allow to be bundled" do
        it "should do stuff" do
          expect { TestNotBundleableExtention.new.download(options) }.to raise_error(Exceptions::NotBundleable)
        end
      end

      context "when file format allow to be bundled" do
        it "should download from zip" do
          download_from_zip_result = "any result"
          instance = TestBundleableExtention.new
          allow(instance).to receive(:download_from_zip) { download_from_zip_result }

          instance.download(options)

          expect(instance).to have_received(:download_from_zip)
        end
      end
    end
  end
end

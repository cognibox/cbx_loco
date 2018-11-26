require "spec_helper"

describe CbxLoco::Configuration do
  describe "initially" do
    it "should set 'on' method" do
      expect(CbxLoco::Configuration.instance_methods.include?(:on)).to be true
    end

    it "should set 'emit' method" do
      expect(CbxLoco::Configuration.instance_methods.include?(:emit)).to be true
    end
  end
end

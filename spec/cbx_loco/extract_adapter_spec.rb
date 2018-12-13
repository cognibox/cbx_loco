require "spec_helper"

describe CbxLoco::ExtractAdapter do
  describe ".grab_existing_assets" do
    let(:expected_names) { ["cbx.some_other_asset", "cbx.some_asset_with_a_really_long_name_that_exceeds_locos_100_character_limit_to_asset_names_beca...", "Some other asset"] }
    context "when version is 1.0.19 or lower" do
      before do
        CbxLoco.configuration.version = "1.0.19"

        @get_response = [
          { "id" => "cbx.some_other_asset", "name" => "cbx.some_other_asset", "tags" => ["testserver-testcbx"] },
          { "id" => "cbx.some_asset_with_a_really_long_name_that_exceeds_locos_100_character_limit_to_asset_names_because_we_want_everything_to_work_properly", "name" => "cbx.some_asset_with_a_really_long_name_that_exceeds_locos_100_character_limit_to_asset_names_beca...", "tags" => ["testserver-testcbx"] },
          { "id" => "some-other-asset", "name" => "Some other asset", "tags" => ["testclient-testfrontend"] }
        ]
      end

      it "should map assets by aliases name" do
        existing_assets = CbxLoco::ExtractAdapter.new(@get_response).grab_existing_assets
        expect(existing_assets.keys).to match_array expected_names
      end
    end

    context "when version is  greater than 1.0.19" do
      before do
        CbxLoco.configuration.version = "1.0.20"

        @get_response = [
          { "id" => "cbx.some_other_asset", "aliases" => { "name" => "cbx.some_other_asset" }, "tags" => ["testserver-testcbx"] },
          { "id" => "cbx.some_asset_with_a_really_long_name_that_exceeds_locos_100_character_limit_to_asset_names_because_we_want_everything_to_work_properly",  "aliases" => { "name" => "cbx.some_asset_with_a_really_long_name_that_exceeds_locos_100_character_limit_to_asset_names_beca..." }, "tags" => ["testserver-testcbx"] },
          { "id" => "some-other-asset",  "aliases" => { "name" => "Some other asset" }, "tags" => ["testclient-testfrontend"] }
        ]
      end

      it "should map assets by aliases name" do
        existing_assets = CbxLoco::ExtractAdapter.new(@get_response).grab_existing_assets
        expect(existing_assets.keys).to match_array expected_names
      end
    end
  end
end

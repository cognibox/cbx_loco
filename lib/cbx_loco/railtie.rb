require 'rails'
require 'cbx_loco'

class CbxLoco::Railtie < Rails::Railtie
  railtie_name :cbx_loco

  initializer "cbx_loco.configure_rails_initialization" do
    CbxLoco.configuration.root = Rails.root
  end

  rake_tasks do
    load File.expand_path("../tasks/i18n.rake", File.dirname(__FILE__))
  end
end

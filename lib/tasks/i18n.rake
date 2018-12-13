namespace :i18n do
  require 'cbx_loco'

  desc "Extract i18n assets, and upload them to Loco"
  task :extract => :environment do
    command = { extract: true }
    CbxLoco.run command
  end

  desc "Import compiled i18n assets from Loco"
  task :import => :environment do
    command = { import: true }
    CbxLoco.run command
  end
end

class CbxLoco::Extention
  def export(file_path:, translations:, language:)
    file = File.new file_path, "w:UTF-8"
    file.write translations.force_encoding("UTF-8")
    file.close

    validate file_path
  end

  def validate(file_path)
  end
end

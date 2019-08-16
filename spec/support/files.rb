module Files
  extend self
  extend ActionDispatch::TestProcess

  def png_name; 'invalid.png' end
  def png; upload(png_name, 'image/png') end

  def csv_name; 'valid_sample.csv' end
  def csv; upload(csv_name, 'text/csv') end

  def invalid_csv_name; 'invalid_sample.csv' end
  def invalid_csv; upload(invalid_csv_name, 'text/csv') end

  private

  def upload(name, type)
    file_path = Rails.root.join('spec', 'fixtures', name)
    fixture_file_upload(file_path, type)
  end
end

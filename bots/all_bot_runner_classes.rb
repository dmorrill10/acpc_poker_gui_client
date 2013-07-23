Dir.glob("#{File.expand_path('../', __FILE__)}/run_*.rb").each do |runner_class|
  begin
    require runner_class
  rescue
  end
end
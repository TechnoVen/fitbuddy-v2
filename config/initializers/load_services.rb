"# Eager-load files in app/services so they are available in test/runner contexts"
Dir[Rails.root.join('app/services/**/*.rb')].sort.each do |file|
  require file
end

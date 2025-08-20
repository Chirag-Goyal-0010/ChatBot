# Fix migrations script
puts "Fixing migration status..."

migrations = [
  '20250715124241',
  '20250716064111', 
  '20250716132715',
  '20250716132951',
  '20250716140000'
]

migrations.each do |version|
  begin
    ActiveRecord::Base.connection.execute("INSERT INTO schema_migrations (version) VALUES ('#{version}') ON CONFLICT (version) DO NOTHING")
    puts "✅ Marked migration #{version} as run"
  rescue => e
    puts "⚠️  Migration #{version}: #{e.message}"
  end
end

puts "Migration status fixed!" 
namespace :db do
  desc "Enable pgvector extension"
  task enable_pgvector: :environment do
    puts "Enabling pgvector extension..."
    
    begin
      ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS vector;")
      puts "✅ pgvector extension enabled successfully!"
    rescue => e
      puts "❌ Failed to enable pgvector extension: #{e.message}"
      puts "Make sure PostgreSQL is running and you have the pgvector extension installed."
      exit 1
    end
  end

  desc "Reset database and enable pgvector"
  task reset_with_pgvector: :environment do
    puts "Resetting database and enabling pgvector..."
    
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:enable_pgvector"].invoke
    Rake::Task["db:migrate"].invoke
    
    puts "✅ Database reset and pgvector enabled successfully!"
  end
end 
require 'simplecov'  # Must be required first

require 'activerecord_tsvectors'

require 'logger'

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger.level = Logger::INFO

begin
  database_config = YAML.load(
    File.open(File.expand_path("../database.yml", __FILE__)))
rescue Errno::ENOENT
  abort "You need to create an ActiveRecord database configuration in #{File.expand_path("../database.yml", __FILE__)}."
else
  connection = ActiveRecord::Base.establish_connection(database_config).connection
  connection.execute("set client_min_messages = warning")
end

RSpec.configure do |c|
  c.mock_with :rspec

  c.before :each do
    ActiveRecord::Base.connection.execute %(
      create table if not exists things (
        id serial primary key,
        tags tsvector
      )
    )
    ActiveRecord::Base.connection.execute %(
      create table if not exists thangs (
        id serial primary key,
        tags tsvector
      )
    )
  end

  c.around(:each) do |example|
    ActiveRecord::Base.connection.transaction do
      example.run 
      raise ActiveRecord::Rollback
    end
  end
end

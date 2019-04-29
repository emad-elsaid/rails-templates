require 'fileutils'

def remove_comments(path)
  files = Dir.glob(path).select { |file| File.file?(file) }
  files.each do |file|
    content = File.read(file)
    without_comments = content.lines.reject do |line|
      line.strip[0] == '#' || line.strip.empty?
    end.join
    File.write(file, without_comments)
  end
end

def remove_empty(path)
  files = Dir.glob(path).select { |file| File.file?(file) }
  files.each do |file|
    content = File.read(file)
    File.delete(file) if content.strip.empty?
  end
end

remove_comments('**/**/*.rb')
remove_empty('**/**/*.rb')

remove_comments('**/**/*.yml')
remove_empty('**/**/*.yml')

remove_comments('Gemfile')

['app/jobs', 'app/channels', 'app/mailers'].each do |dir|
  FileUtils.rm_rf(dir) if no?("Do you need '#{dir}' directory?")
end

gem_group :development, :test do
  gem 'pry-rails'
  gem 'rubocop'
end

gem_group :test do
  gem 'rspec-rails'
end

gems_to_remove = ['coffee-rails', 'jbuilder', 'byebug', 'web-console', 'tzinfo-data']
File.write(
  'Gemfile',
  File.read('Gemfile').lines.reject do |line|
    gems_to_remove.any? do |gem_name|
      line.include?(gem_name)
    end
  end.join
)

run 'bundle install'

generate('rspec:install')

file '.rubocop.yml', <<-CODE
AllCops:
  Exclude:
    - 'vendor/**/*'
    - 'db/schema.rb'
    - 'db/migrate/**/*'
    - 'bin/**/*'
Style/Documentation:
  Enabled: false
Metrics/LineLength:
  Max: 100
CODE

run 'rubocop -a'

FileUtils.rm_rf('test')
FileUtils.rm_rf('tmp')

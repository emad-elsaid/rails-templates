require 'fileutils'

def filter_lines(path, &block)
  files = Dir.glob(path).select { |file| File.file?(file) }
  files.each do |file|
    content = File.read(file)
    filtered = content.lines.reject do |line|
      block.call(line)
    end.join
    File.write(file, filtered)
  end
end

def remove_comments(path, comment_mark = '#')
  filter_lines(path) do |line|
    line.strip.starts_with?(comment_mark)
  end
end

def remove_empty_lines(path, empty_line = '')
  filter_lines(path) do |line|
    line.strip == empty_line
  end
end

def remove_empty(path)
  files = Dir.glob(path).select { |file| File.file?(file) }
  files.each do |file|
    content = File.read(file)
    File.delete(file) if content.strip.empty?
  end
end

def remove_gem(gem_name)
  File.write(
    'Gemfile',
    File.read('Gemfile').lines.reject do |line|
      line.include?(gem_name)
    end.join
  )
end

def gem_exist?(gem_name)
  File.read('Gemfile').include?(gem_name)
end

{
  'Jobs' => [
    'app/jobs'
  ],
  'Channels' => [
    'app/channels',
    'app/assets/javascripts/channels',
    'app/assets/javascripts/cable.js',
    'config/cable.yml'
  ],
  'Mailers' => [
    'app/mailers',
    'app/views/layouts/mailer.html.erb',
    'app/views/layouts/mailer.text.erb'
  ],
  'Concerns' => [
    'app/controllers/concerns',
    'app/models/concerns'
  ],
  'Storage' => [
    'storage',
    'config/storage.yml'
  ]
}.each do |name, files|
  if files.any? { |file| File.exist?(file) } && no?("Do you need #{name}?")
    files.each { |file| FileUtils.rm_rf(file) }
  end
end

[
  'coffee-rails',
  'jbuilder',
  'byebug',
  'web-console',
  'tzinfo-data'
].each do |gem_name|
  if gem_exist?(gem_name) && no?("Do you need #{gem_name} gem?")
    remove_gem(gem_name)
  end
end

if gem_exist?('spring') && no?('Do you need spring?')
  remove_gem('spring')
  FileUtils.rm_rf('config/spring.rb')
  FileUtils.rm_rf('bin/spring')
end

gem_group :development, :test do
  gem 'pry-rails'
  gem 'rubocop', require: false
end

unless gem_exist?('rspec_rails') && yes?('Should I add rspec-rails?')
  gem_group :test do
    gem 'rspec-rails'
  end
  run 'bundle install'
  generate('rspec:install') unless File.exist?('spec')
end

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

remove_comments('**/**/*.rb')
remove_empty_lines('**/**/*.rb')
remove_empty('**/**/*.rb')

remove_comments('**/**/*.yml')
remove_empty_lines('**/**/*.yml')
remove_empty('**/**/*.yml')

remove_comments('**/**/*.js', '// ')
remove_empty_lines('**/**/*.js', '//')

remove_comments('**/**/*.css', '* ')
remove_empty_lines('**/**/*.css', '*')

[
  'Gemfile',
  'config.ru',
  'Rakefile'
].each do |file|
  remove_comments(file)
  remove_empty_lines(file)
end

FileUtils.rm_rf('test')

run 'rubocop -a'

[
  'tmp:clear',
  'log:clear'
].each do |cmd|
  rails_command cmd
end

run 'touch db/seeds.rb' unless File.exist?('db/seeds.rb')

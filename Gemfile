
source :rubygems

group :development do
  gem 'rake', '0.8.7'
  gem 'mini_portile', '0.2.2'
  gem 'rake-compiler', '0.7.8'
end

group :test do
  gem 'mini_shoulda', '0.3.0'
  gem 'activesupport', '2.3.5'
  gem 'bench_press', '0.3.1'
  platforms :mri_18 do
    gem 'ruby-prof', '0.9.1'
    gem 'ruby-debug', '0.10.3'
  end
  platforms :mri_19 do
    gem 'ruby-debug19', '0.11.6'
  end
end

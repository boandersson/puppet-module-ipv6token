source ENV['GEM_SOURCE'] || "https://rubygems.org"

group :test do
  gem 'safe_yaml', '~> 1.0.4'
  gem 'rake', '< 11.0'
  gem "puppet", ENV['PUPPET_GEM_VERSION'] || '~> 3.8.0'
  gem "rspec", '< 3.2.0'
  gem "rspec-puppet"
  gem "puppetlabs_spec_helper"
  gem "metadata-json-lint"
  gem "rspec-puppet-facts"
  gem 'rubocop', '0.49.1'
  gem 'simplecov', '>= 0.11.0'
  gem 'simplecov-console'

  gem "puppet-lint-absolute_classname-check"
  gem "puppet-lint-leading_zero-check"
  gem "puppet-lint-trailing_comma-check"
  gem "puppet-lint-version_comparison-check"
  gem "puppet-lint-classes_and_types_beginning_with_digits-check"
  gem "puppet-lint-unquoted_string-check"
  gem 'puppet-lint-resource_reference_syntax'

  gem 'json_pure', '<= 2.0.1' if RUBY_VERSION < '2.0.0'
end

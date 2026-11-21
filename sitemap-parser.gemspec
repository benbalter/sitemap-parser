# frozen_string_literal: true

require File.expand_path('lib/sitemap-parser/version', __dir__)

Gem::Specification.new do |s|
  s.name = 'sitemap-parser'
  s.summary = 'Ruby Gem to parse sitemaps.org compliant sitemaps'
  s.description = 'Ruby Gem to parse sitemaps.org compliant sitemaps.'
  s.version = SitemapParser::VERSION
  s.authors = ['Ben Balter']
  s.email = 'ben.balter@github.com'
  s.homepage = 'https://github.com/benbalter/sitemap-parser'
  s.licenses = ['MIT']
  s.metadata = {
    'homepage_uri' => 'https://github.com/benbalter/sitemap-parser',
    'source_code_uri' => 'https://github.com/benbalter/sitemap-parser',
    'bug_tracker_uri' => 'https://github.com/benbalter/sitemap-parser/issues',
    'changelog_uri' => 'https://github.com/benbalter/sitemap-parser/blob/main/CHANGELOG.md',
    # Trusted publishing still works: RubyGems skips the MFA check for
    # pushes that don't use a user's API key.
    'rubygems_mfa_required' => 'true'
  }
  s.files = ['lib/sitemap-parser.rb', 'lib/sitemap-parser/version.rb', 'LICENSE.md', 'README.md', 'CHANGELOG.md']
  s.required_ruby_version = '>= 3.0'
  s.add_dependency('nokogiri', '>= 1.6')
  s.add_dependency('typhoeus', '>= 0.6', '< 2.0')
  s.add_development_dependency('rake', '~> 13.0')
  s.add_development_dependency('rubocop', '~> 1.0')
  s.add_development_dependency('rubocop-performance', '~> 1.5')
  s.add_development_dependency('test-unit', '>= 3.1')
end

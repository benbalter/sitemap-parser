Gem::Specification.new do |s|
  s.name = "sitemap-parser"
  s.summary = "Ruby Gem to parse sitemaps.org compliant sitemaps"
  s.description = "Ruby Gem to parse sitemaps.org compliant sitemaps."
  s.version = "0.2.1"
  s.authors = ["Ben Balter"]
  s.email = "ben.balter@github.com"
  s.homepage = "https://github.com/benbalter/sitemap-parser"
  s.licenses = ["MIT"]
  s.files = [ "lib/sitemap-parser.rb" ]
  s.add_dependency("nokogiri","~> 1.6")
  s.add_dependency("typhoeus", "~> 0.6")
  s.add_development_dependency("rake", "~> 10.4")
  s.add_development_dependency("shoulda", "~> 3.5")
  s.add_development_dependency("bundler", "~> 1.6")
  s.add_development_dependency("minitest", "~> 4.7")
end

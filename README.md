# Sitemap Parser

*Ruby Gem to parse sitemaps.org compliant sitemaps*

## Usage

```ruby
sitemap = SitemapParser.new "http://ben.balter.com/sitemap.xml"
sitemap.urls # => Array of Nokigiri XML::Node objects
sitemap.to_a # => Array of url strings
```

## Roadmap

* Tests
* `sitemap_index` support

# Sitemap Parser

*Ruby Gem to parse sitemaps.org compliant sitemaps*

[![Build Status](https://travis-ci.org/benbalter/sitemap-parser.svg?branch=master)](https://travis-ci.org/benbalter/sitemap-parser) [![Gem Version](https://badge.fury.io/rb/sitemap-parser.svg)](http://badge.fury.io/rb/sitemap-parser)

## Usage

Create a new instance of the Parser:
```ruby
sitemap = SitemapParser.new "http://ben.balter.com/sitemap.xml"
```

Extract the URLs of the sitemap
```ruby
sitemap.urls # => Array of Nokigiri XML::Node objects
sitemap.to_a # => Array of url strings
```

## Options

### Recurse nested sitemaps

```ruby
sitemap = SitemapParser.new('http://ben.balter.com/sitemap.xml', {recurse: true})
```

Or if you only want to extract only sitemap urls maching a given pattern, you
can provide a regex that will be used to match each page.

```ruby
sitemap = SitemapParser.new('http://ben.balter.com/sitemap.xml', {recurse: true, url_regex: /sitemapregex/})
```

### Typhoeus Options

```ruby
sitemap = SitemapParser.new('http://ben.balter.com/sitemap.xml', { userpwd: "username:password" })
```
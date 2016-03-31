# Sitemap Parser

*Ruby Gem to parse sitemaps.org compliant sitemaps*

[![Build Status](https://travis-ci.org/benbalter/sitemap-parser.svg?branch=master)](https://travis-ci.org/benbalter/sitemap-parser) [![Gem Version](https://badge.fury.io/rb/sitemap-parser.svg)](http://badge.fury.io/rb/sitemap-parser)

## Usage

```ruby
sitemap = SitemapParser.new "http://ben.balter.com/sitemap.xml"
sitemap.urls # => Array of Nokigiri XML::Node objects
sitemap.to_a # => Array of url strings
```

## Options

```ruby
sitemap = SitemapParser.new "http://ben.balter.com/sitemap.xml", 
  :recurse => true // traverse one-level of sitemapindex tags and add their URLs to the output
  :followlocation => true // follow redirects
```

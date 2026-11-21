# Sitemap Parser

*Ruby Gem to parse sitemaps.org compliant sitemaps*

[![CI](https://github.com/benbalter/sitemap-parser/actions/workflows/ci.yml/badge.svg)](https://github.com/benbalter/sitemap-parser/actions/workflows/ci.yml) [![Gem Version](https://badge.fury.io/rb/sitemap-parser.svg)](https://badge.fury.io/rb/sitemap-parser)

## Usage

Create a new instance of the Parser with a URL or a path to a local file. Gzipped sitemaps (`sitemap.xml.gz`) work too.

```ruby
sitemap = SitemapParser.new "https://ben.balter.com/sitemap.xml"
sitemap = SitemapParser.new "path/to/sitemap.xml"
```

Extract the URLs of the sitemap

```ruby
sitemap.urls # => Array of Nokogiri XML::Node objects
sitemap.to_a # => Array of url strings
```

## Options

### Recurse nested sitemaps

By default, a sitemap index returns no URLs. Pass `recurse: true` to follow the sitemaps it lists, however deeply they're nested. Each sitemap is fetched once, even if it's listed more than once.

```ruby
sitemap = SitemapParser.new('https://ben.balter.com/sitemap.xml', recurse: true)
```

To only extract the URLs that match a pattern, pass a regex. It's matched against every URL, in nested sitemaps and pages alike.

```ruby
sitemap = SitemapParser.new('https://ben.balter.com/sitemap.xml', recurse: true, url_regex: /sitemapregex/)
```

### Request headers

Requests send a `Sitemap-Parser` User-Agent unless you set your own. Any other headers you pass are kept.

```ruby
sitemap = SitemapParser.new('https://ben.balter.com/sitemap.xml', headers: { 'User-Agent' => 'MyBot/1.0', 'Accept-Language' => 'en' })
```

### Typhoeus options

Any other option is passed to [Typhoeus](https://github.com/typhoeus/typhoeus), for every sitemap fetched.

```ruby
sitemap = SitemapParser.new('https://ben.balter.com/sitemap.xml', userpwd: "username:password")
```

## Releasing

1. Open a pull request that bumps `lib/sitemap-parser/version.rb` and adds a `## X.Y.Z` section to [`CHANGELOG.md`](CHANGELOG.md).
2. Merge it once CI passes.
3. Push a signed tag for the version, e.g. `git tag -s v0.6.0 -m v0.6.0 && git push origin v0.6.0`.

The [release workflow](.github/workflows/release.yml) then publishes the gem to RubyGems through [trusted publishing](https://guides.rubygems.org/trusted-publishing/) and creates the GitHub release from the changelog.

# Changelog

## 0.6.0

### Breaking changes

- Ruby 3.0 or newer is required.
- `SitemapParser::DEFLATE_TYPE_REGEX` is gone. Gzip is detected from the file's contents instead.
- A remote sitemap index that lists a local path, or anything else that isn't an http(s) URL, now raises instead of reading it.
- A sitemap listed more than once in an index tree is parsed once, so its URLs no longer appear twice in `urls` or `to_a`.

### New features

- Recurse through sitemap indexes nested more than one level deep. Before, `recurse: true` stopped after the first level (#25). Thanks to [@etagwerker](https://github.com/etagwerker).
- Pass Typhoeus options, such as `userpwd`, along to nested sitemaps when recursing (#28). Thanks to [@prasannaboga](https://github.com/prasannaboga).
- Send a `Sitemap-Parser` User-Agent by default, and include the URL in the error when a request fails (#29). Thanks to [@tamaloa](https://github.com/tamaloa).
- Set custom request headers with the `headers` option (#30). Thanks to [@sscherban](https://github.com/sscherban).
- Read local sitemaps with any file name, not just `sitemap.xml` (#30). Thanks to [@sscherban](https://github.com/sscherban).
- Read gzipped sitemaps whatever their `Content-Type`, and read local `.gz` files too. Gzip is now detected from the file's contents.

### Bug fixes

- Keep custom headers when no User-Agent is given, instead of replacing them with the default one (#34). Thanks to [@aksshatt](https://github.com/aksshatt).
- Treat a User-Agent header given in any case, such as `user-agent`, as the caller's own, and don't add a second one.
- Return `[]` for an empty sitemap instead of raising (#30). Thanks to [@sscherban](https://github.com/sscherban).
- Strip whitespace around `<loc>` values.
- Stop recursing when a sitemap index lists itself or an ancestor, which used to loop until the stack overflowed. A sitemap listed more than once is fetched only once.
- Refuse to read local files listed in a remote sitemap index. Before, a remote index could make the parser read any file on disk.
- Raise a clear error when a sitemap isn't a URL or an existing file, or when a `<url>` has no `<loc>`, instead of a `NoMethodError`.
- Don't try to gunzip plain XML served as `application/octet-stream`.

### Maintenance

- Move CI to GitHub Actions, and loosen the nokogiri constraint to `>= 1.6` (#26). Thanks to [@petergoldstein](https://github.com/petergoldstein).
- Test on Ruby 3.0, the oldest the gem allows, and every supported release, and upgrade RuboCop to 1.x.
- Publish releases to RubyGems from GitHub Actions through trusted publishing.

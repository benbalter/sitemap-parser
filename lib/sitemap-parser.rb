# frozen_string_literal: true

require 'nokogiri'
require 'set'
require 'typhoeus'
require 'zlib'
require_relative 'sitemap-parser/version'

# Parses a sitemaps.org sitemap or sitemap index, from a URL or a local file,
# into its <url> nodes (#urls) or their locations (#to_a).
class SitemapParser
  attr_accessor :url, :options

  DEFAULT_OPTIONS = {
    followlocation: true,
    recurse: false,
    url_regex: nil
  }.freeze

  # The first two bytes of every gzip stream (RFC 1952).
  GZIP_MAGIC = [0x1f, 0x8b].freeze

  def initialize(url, opts = {})
    @url = url
    @options = DEFAULT_OPTIONS.merge(opts)
  end

  def raw_sitemap
    @raw_sitemap ||= fetch_remote_sitemap || read_local_sitemap ||
                     raise("Could not read sitemap at #{url}: not an http(s) URL or an existing file")
  end

  def sitemap
    @sitemap ||= Nokogiri::XML(raw_sitemap)
  end

  def urls
    @urls ||= if urlset
                filter_sitemap_urls(urlset.search('url'))
              elsif sitemapindex
                options[:recurse] ? parse_sitemap_index : []
              elsif raw_sitemap.strip.empty?
                []
              else
                raise 'Malformed sitemap, no urlset or sitemapindex'
              end
  end

  def to_a
    urls.map { |url| url.at('loc').content }
  end

  protected

  # Sitemap locations already fetched while recursing, shared by every parser
  # in one tree so that an index which lists itself, an ancestor, or the same
  # child twice is fetched only once instead of looping forever.
  def visited
    @visited ||= Set[url]
  end

  attr_writer :visited

  private

  def parse_sitemap_index
    filter_sitemap_urls(sitemapindex.search('sitemap')).flat_map do |sitemap|
      location = sitemap.at('loc').content
      next [] unless visited.add?(location)

      child_parser(location).urls.to_a
    end
  end

  def child_parser(location)
    # A remote index must not be able to make us read files from local disk.
    if remote_sitemap? && !remote_sitemap?(location)
      raise "Refusing to read #{location}: sitemap index #{url} may only list http(s) URLs"
    end

    self.class.new(location, options).tap { |child| child.visited = visited }
  end

  def urlset
    @urlset ||= sitemap.at('urlset')
  end

  def sitemapindex
    @sitemapindex ||= sitemap.at('sitemapindex')
  end

  def strip_whitespace(urls)
    urls.each do |url|
      loc = url.at('loc') || raise("Malformed sitemap, #{url.name} without loc")
      loc.content = loc.content.strip
    end

    urls
  end

  def filter_sitemap_urls(urls)
    urls = strip_whitespace(urls)
    return urls if options[:url_regex].nil?

    urls.select { |url| url.at('loc').content =~ options[:url_regex] }
  end

  # Inflates gzipped sitemaps (e.g. sitemap.xml.gz), detected by their magic
  # bytes rather than the Content-Type, which servers often get wrong.
  def inflate_if_gzipped(body)
    return body unless body.byteslice(0, 2).bytes == GZIP_MAGIC

    Zlib.gunzip(body)
  end

  def remote_sitemap?(location = url)
    %r{\Ahttps?://}i.match?(location)
  end

  def local_sitemap?
    File.exist?(url)
  end

  def fetch_remote_sitemap
    return nil unless remote_sitemap?

    request_options = options.except(:recurse, :url_regex)
    request_options[:headers] = request_headers
    request = Typhoeus::Request.new(url, request_options)

    response = request.run
    raise "HTTP request to #{url} failed with code #{response.code}." unless response.success?

    inflate_if_gzipped(response.body)
  end

  # Returns the request headers, keeping any caller-supplied headers and adding
  # a default User-Agent only when the caller didn't provide one, in any case.
  def request_headers
    headers = options[:headers] || {}
    return headers if headers.keys.any? { |key| key.to_s.casecmp?('User-Agent') }

    headers.merge('User-Agent' => 'Sitemap-Parser')
  end

  def read_local_sitemap
    return nil unless local_sitemap?

    inflate_if_gzipped(File.binread(url))
  end
end

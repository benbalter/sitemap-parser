# frozen_string_literal: true

require 'nokogiri'
require 'typhoeus'
require 'zlib'
require_relative 'sitemap-parser/version'

class SitemapParser
  attr_accessor :url, :options

  DEFAULT_OPTIONS = {
    followlocation: true,
    recurse: false,
    url_regex: nil
  }.freeze

  DEFLATE_TYPE_REGEX = %r{application/((x-)?gzip|octet-stream)}.freeze

  def initialize(url, opts = {})
    @url = url
    @options = DEFAULT_OPTIONS.merge(opts)
  end

  def raw_sitemap
    @raw_sitemap ||= fetch_remote_sitemap || read_local_sitemap
  end

  def sitemap
    @sitemap ||= Nokogiri::XML(raw_sitemap)
  end

  def urls
    @urls ||= if urlset
                filter_sitemap_urls(urlset.search('url'))
              elsif sitemapindex
                options[:recurse] ? parse_sitemap_index : []
              else
                puts sitemapindex.inspect
                puts remote_sitemap?.inspect
                puts url.inspect

                raise 'Malformed sitemap, no urlset or sitemapindex'
              end
  end

  def to_a
    urls.map { |url| url.at('loc').content }
  rescue NoMethodError
    raise 'Malformed sitemap, url without loc'
  end

  private

  def parse_sitemap_index
    found_urls = []

    urls = sitemapindex.search('sitemap')
    urls = filter_sitemap_urls(urls)
    urls.each do |sitemap|
      child_sitemap_location = sitemap.at('loc').content
      found_urls << self.class.new(child_sitemap_location, recurse: false).urls
    end

    found_urls.flatten
  end

  def urlset
    @urlset ||= sitemap.at('urlset')
  end

  def sitemapindex
    @sitemapindex ||= sitemap.at('sitemapindex')
  end

  def strip_whitespace(urls)
    urls.each do |url|
      url.at('loc').content = url.at('loc').content.strip
    end

    urls
  end

  def filter_sitemap_urls(urls)
    urls = strip_whitespace(urls)
    return urls if options[:url_regex].nil?

    urls.select { |url| url.at('loc').content =~ options[:url_regex] }
  end

  def inflate_body_if_needed(response)
    return response.body unless response.headers
    return response.body unless DEFLATE_TYPE_REGEX.match?(response.headers['Content-type'])

    Zlib.gunzip(response.body)
  end

  def remote_sitemap?
    %r{\Ahttps?://}i.match?(url)
  end

  def local_sitemap?
    File.exist?(url) && url =~ %r{[\\/]sitemap(_index)?\.xml\Z}i
  end

  def fetch_remote_sitemap
    return nil unless remote_sitemap?

    request_options = options.dup.tap { |opts| opts.delete(:recurse); opts.delete(:url_regex) }
    request = Typhoeus::Request.new(url, request_options)

    response = request.run
    raise "HTTP request to #{url} failed" unless response.success?

    inflate_body_if_needed(response)
  end

  def read_local_sitemap
    return nil unless local_sitemap?

    File.open(url, &:read)
  end
end

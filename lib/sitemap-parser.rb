# frozen_string_literal: true

require 'nokogiri'
require 'net/http'
require 'uri'
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
              elsif raw_sitemap.strip.empty?
                []
              else
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
      found_urls << self.class.new(child_sitemap_location, @options).urls
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
    content_type = response['Content-Type'] || response['content-type']
    return response.body unless content_type
    return response.body unless DEFLATE_TYPE_REGEX.match?(content_type)

    Zlib.gunzip(response.body)
  end

  def remote_sitemap?
    %r{\Ahttps?://}i.match?(url)
  end

  def local_sitemap?
    File.exist?(url)
  end

  def fetch_remote_sitemap
    return nil unless remote_sitemap?

    uri = URI.parse(url)
    max_redirects = 10
    redirect_count = 0
    
    request_options = options.dup.tap { |opts| opts.delete(:recurse); opts.delete(:url_regex) }
    
    # Set up default headers if not provided
    headers = if options[:headers]
                options[:headers]
              else
                { 'User-Agent' => 'Sitemap-Parser' }
              end

    while redirect_count < max_redirects
      response = fetch_with_net_http(uri, headers, request_options)
      
      case response
      when Net::HTTPSuccess
        return inflate_body_if_needed(response)
      when Net::HTTPRedirection
        location = response['location']
        uri = URI.parse(location)
        redirect_count += 1
      else
        raise "HTTP request to #{url} failed with code #{response.code}."
      end
    end
    
    raise "HTTP request to #{url} failed: too many redirects."
  end

  def fetch_with_net_http(uri, headers, request_options)
    http = Net::HTTP.new(uri.host, uri.port)
    
    # Set up SSL if HTTPS
    if uri.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end
    
    # Set timeout if specified in options
    http.open_timeout = request_options[:timeout] if request_options[:timeout]
    http.read_timeout = request_options[:timeout] if request_options[:timeout]
    
    request = Net::HTTP::Get.new(uri.request_uri)
    
    # Add headers to request
    headers.each do |key, value|
      request[key] = value
    end

    http.request(request)
  end

  def read_local_sitemap
    return nil unless local_sitemap?

    File.open(url, &:read)
  end
end

require 'nokogiri'
require 'typhoeus'

require 'zlib'

class SitemapParser

  def initialize(url, opts = {})
    @url = url
    @options = {:followlocation => true, :recurse => false}.merge(opts)
  end

  def raw_sitemap
    @raw_sitemap ||= begin
      if @url =~ /\Ahttp/i
        request = Typhoeus::Request.new(@url, followlocation: @options[:followlocation])
        request.on_complete do |response|
          raise "HTTP request to #{@url} failed" unless response.success?
          return inflate_body_if_needed(response)
        end
        request.run
      elsif File.exist?(@url) && @url =~ /[\\\/]sitemap\.xml\Z/i
        open(@url) { |f| f.read }
      end
    end
  end

  def sitemap
    @sitemap ||= Nokogiri::XML(raw_sitemap)
  end

  def urls
    if sitemap.at('urlset')
      sitemap.at("urlset").search("url")
    elsif sitemap.at('sitemapindex')
      found_urls = []
      if @options[:recurse]
        sitemap.at('sitemapindex').search('sitemap').each do |sitemap|
          child_sitemap_location = sitemap.at('loc').content
          found_urls << self.class.new(child_sitemap_location, :recurse => false).urls
        end
      end
      return found_urls.flatten
    else
      raise 'Malformed sitemap, no urlset'
    end
  end

  def to_a
    urls.map { |url| url.at("loc").content }
  rescue NoMethodError
    raise 'Malformed sitemap, url without loc'
  end

  private

  def inflate_body_if_needed(response)
    if response.headers["Content-Type"] == "application/gzip"
      Zlib::Inflate.inflate(response.body)
    else
      response.body
    end
  end
end

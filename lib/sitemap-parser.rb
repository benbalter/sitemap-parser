require 'nokogiri'
require 'open-uri'

class SitemapParser

  def initialize(url)
    @url = url
  end

  def sitemap
    @sitemap ||= Nokogiri::XML(open(@url))
  end

  def urls
    sitemap.at("urlset").search("url")
  end

  def to_a
    urls.map { |url| url.at("loc").content }
  end
end

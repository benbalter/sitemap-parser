require 'nokogiri'
require 'typhoeus'

class SitemapParser

  def initialize(url)
    @url = url
  end

  def raw_sitemap
    @raw_sitemap ||= begin
      request = Typhoeus::Request.new(@url, followlocation: true)
      request.on_complete do |response|
        if response.success?
          return response.body
        else
          return nil
        end
      end
      request.run
    end
  end

  def sitemap
    @sitemap ||= Nokogiri::XML(raw_sitemap)
  rescue
    nil
  end

  def urls
    sitemap.at("urlset").search("url")
  rescue
    nil
  end

  def to_a
    urls.map { |url| url.at("loc").content }
  rescue
    []
  end
end

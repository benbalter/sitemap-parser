require 'nokogiri'
require 'typhoeus'

class SitemapParser

  def initialize(url, opts = {})
    @url = url
    @options = {:followlocation => true}.merge(opts)
  end

  def raw_sitemap
    @raw_sitemap ||= begin
      if @url =~ /\Ahttp/i
        request = Typhoeus::Request.new(@url, followlocation: @options[:followlocation])
        request.on_complete do |response|
          if response.success?
            if @url =~ /.gz$/
              gz = Zlib::GzipReader.new(StringIO.new(response.body.to_s))
              return gz.read
            else
              return response.body
            end
          else
            return nil
          end
        end
        request.run
      elsif File.exist?(@url) && @url =~ /[\\\/]sitemap\.xml\Z/i
        open(@url) { |f| f.read }
      end
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

  def sitemaps
    sitemap.at("sitemapindex").search("sitemap")
  rescue
    nil
  end

  def sitemap_url_array
    sitemaps.map { |url| url.at("loc").content }
  rescue
    []
  end

end

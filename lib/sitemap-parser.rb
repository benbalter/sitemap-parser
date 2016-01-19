require 'nokogiri'
require 'typhoeus'

class SitemapParser

  def initialize(url, opts = {})
    @url = url
    @options = {:followlocation => true, :recurse => true}.merge(opts)
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
    urlset = sitemap.at("urlset")
    urlset.search("url")
    rescue 
      nil
  end

  def all_urls 
    # includes URLs from other sub-sitemaps referenced via <sitemapindex>
    (@options[:recurse] ? sitemap_index_urls : []) << urls
  end

  def to_a
    all_urls.reduce([]){|memo, urlset| memo += urlset.map{|url| url.at("loc").content } }
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

  def sitemap_index_urls
    sitemap_url_array.map do |sitemap_url|
      STDERR.puts("recursively going to #{sitemap_url} from index")
      self.class.new(sitemap_url, :recurse => false).urls # only recurse one-level down, to avoid infinite recursion
    end
  end

end

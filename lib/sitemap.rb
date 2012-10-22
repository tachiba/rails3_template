class Sitemap
  SITEMAP_MAX = 50000
  SITEMAP_PATH_DEFAULT = %W(public system)
  SITEMAP_INDEX_PATH_DEFAULT = %W(public system)

  def initialize(host, opt={})
    @sitemap_path = opt.delete(:sitemap_path) || SITEMAP_PATH_DEFAULT
    @sitemap_index = 0
    @host = host
    @opt = opt
  end

  def add(path, opt={})
    @maps ||= []
    @maps << {
      path:   path,
      opt:    opt
    }

    next_if_50000
  end

  def done
    exec_all

    build_sitemap_index
  end

  protected
  def exec_all
    s = XmlSitemap::Map.new(@host, @opt) do |m|
      @maps.each do |map|
        m.add map[:path], map[:opt]
      end
    end

    s.render_to(sitemap_path(@sitemap_index))
    @sitemap_index += 1

    @maps = []
  end

  def next_if_50000
    if @maps.size >= SITEMAP_MAX
      exec_all
    end
  end

  def build_sitemap_index
    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct!(:xml, encoding: 'UTF-8', version: "1.0")

    xml.sitemapindex(xmlns: 'http://www.sitemaps.org/schemas/sitemap/0.9') do |sitemapindex|
      @sitemap_index.times do |i|
        sitemapindex.sitemap do |sitemap|
          sitemap.loc sitemap_url(i)
          sitemap.lastmod Time.now.strftime("%F")
        end
      end
    end

    File.write(sitemapindex_path, xml.target!)
  end

  def sitemap_path(i)
    Rails.root.join(@sitemap_path.join("/")).join("sitemap-#{i}.xml")
  end

  def sitemapindex_path
    Rails.root.join(SITEMAP_INDEX_PATH_DEFAULT.join("/")).join("sitemapindex.xml")
  end

  def sitemap_url(i)
    "http://#@host/#{@sitemap_path[1..-1].join("/")}/sitemap-#{i}.xml"
  end
end
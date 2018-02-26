module Jekyll
  # iiif_url filter
  module IIIFUrlFilter
    def iiif_url(input)
      site = @context.registers[:site]
      input.gsub(/IIIF_URL/, site.config['iiifurl'])
    end
  end
end

Liquid::Template.register_filter(Jekyll::IIIFUrlFilter)

Jekyll::Hooks.register :site, :after_init do |site|
  # if iiifurl is explicit in config, leave it alone
  break if site.config['iiifurl']
  site.config['env'] = ENV['JEKYLL_ENV'] || 'development'
  if site.config['env'] == 'production'
    site.config['iiifurl'] = site.config['url']
  else
    site.config['iiifurl'] = 'http://localhost:' + site.config['port']
  end
end

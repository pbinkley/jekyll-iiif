class IIIFManifestTag < IIIF
  def initialize(tag_name, manifest, tokens)
    super
    @manifest = manifest.strip
  end

  def render(context)
  	# build list of documents for Mirador
	#        { 'manifestUri': 'http://127.0.0.1:4000/projects/2016/jekyll-iiif-demo/tiles/danceofdeath/manifest.json', 'location': 'This jekyll-iiif site'},

	site = context.registers[:site]
	collections = ""
	documents = Dir["tiles/*"]
	documents.each do |document|
		if File.directory?(document)
			if File.file?(document + "/manifest.json")
				basename = File.basename(document, ".*")
				collections = collections + "," if collections != ""
				collections = collections +
					"{'manifestUri': '" + site.config["url"] + site.baseurl + "/tiles/" + basename + "/manifest.json', 'location': 'This jekyll-iiif site.'}"
			end
		end
	end

    context.registers[:page]["iiif_collections"] = collections
    context.registers[:page]["thismanifest"] = @manifest

    render_manifest(nil, "iiif_presentation", context)
  end
end

Liquid::Template.register_tag('iiif_presentation', IIIFManifestTag)

class IIIFGalleryTag < IIIF

  def initialize(tag_name, image, tokens)
    super
  end

  def render(context)
    images = ""
    coll = context.registers[:site].collections["iiif_collection"]
    coll.docs.each do |image|
      Jekyll.logger.info("IIIF:", image.path)
      # image has "_iiif/" prefix, which must be removed
      basename = File.basename(image.path, ".*")
      # get thumbnail link from tiles/<basename>/manifest.json
      manifest = JSON.parse(File.read("./tiles/" + basename + "/manifest.json"))
      thumbnail = manifest["thumbnail"]
      context.registers[:page]["thumbnail"] = thumbnail
      context.registers[:page]["thistitle"] = image.data["title"]
      images += render_instance(basename, "iiif_thumbnail", context)
    end
    images
  end
end

Liquid::Template.register_tag('iiif_gallery', IIIFGalleryTag)

class IIIFGalleryTag < IIIF

  def initialize(tag_name, image, tokens)
    super
  end

  def render(context)
    images = ""
    imagefiles = Dir["_iiif/*"].sort!
    imagefiles.each do |image|
      # image has "_iiif/" prefix, which must be removed
      basename = File.basename(image, ".*")
      # get thumbnail link from tiles/<basename>/manifest.json
      manifest = JSON.parse(File.read("./tiles/" + basename + "/manifest.json"))
      thumbnail = manifest["thumbnail"]
      context.registers[:page]["thumbnail"] = thumbnail
      images += render_instance(basename, "iiif_thumbnail", context)
    end
    images
  end
end

Liquid::Template.register_tag('iiif_gallery', IIIFGalleryTag)

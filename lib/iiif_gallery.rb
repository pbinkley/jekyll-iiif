class IIIFGalleryTag < IIIF

  def initialize(tag_name, image, tokens)
    super
  end

  def render(context)
    imagefiles = Dir["_iiif/*"].sort!
    images = ""
    imagefiles.each do |image|
      # image has "_iiif/" prefix, which must be removed
      basename = File.basename(image, ".*")
      images += render_instance(basename, "iiif_thumbnail", context)
    end
    images
  end

end

Liquid::Template.register_tag('iiif_gallery', IIIFGalleryTag)

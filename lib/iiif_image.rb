class IIIFTag < IIIF

  def initialize(tag_name, image, tokens)
    super
    @image = image.strip
  end

  def render(context)
    render_instance(@image, "iiif_image", context)
  end
end

Liquid::Template.register_tag('iiif', IIIFTag)

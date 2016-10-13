class IIIFTag < Liquid::Tag
  def initialize(tag_name, image, tokens)
    super
    @image = image.strip
  end

  def lookup(context, name)
    lookup = context
    if name == ""
      lookup = context["page"]["iiif_image"]
    else
      lookup = name
    end
    lookup
  end

  def render(context)
    <<-MARKUP.strip
<script src="osd/openseadragon.min.js"></script>
<div id="openseadragon1"></div>  
<script>
//<![CDATA[
        function initOpenSeadragon() {
          OpenSeadragon({
  id: "openseadragon1",
  minZoomImageRatio: 1,
  prefixUrl: "osd/images/",
  tileSources: "tiles\/#{ lookup(context, @image) }/info.json",
  crossOriginPolicy: false});
        }
        window.onload = initOpenSeadragon;
        document.addEventListener("page:load", initOpenSeadragon); // Initialize when using turbolinks
//]]>
</script>
    MARKUP
  end
end

Liquid::Template.register_tag('iiif', IIIFTag)
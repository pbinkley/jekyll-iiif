class IIIFTag < Liquid::Tag
  @@instance = 0
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
    @@instance += 1
    if @@instance == 1
      topper = <<-TOPPER.strip 
<script src="osd/openseadragon.min.js"></script>
<script>
//<![CDATA[
var osdfuncs = [];
window.onload = function() {
  var arrayLength = osdfuncs.length;
  for (var i = 0; i < arrayLength; i++) {
    osdfuncs[i]();
  }
}
//]]
</script>
      TOPPER
    else
      topper = ""
    end
    <<-MARKUP.strip
    #{ topper }
<div id="openseadragon#{ @@instance }" class="openseadragon"></div>  
<script>
//<![CDATA[
osdfuncs.push(
  function initOpenSeadragon#{ @@instance }() {
    OpenSeadragon({
      id: "openseadragon#{ @@instance }",
      minZoomImageRatio: 1,
      prefixUrl: "osd/images/",
      tileSources: "tiles\/#{ lookup(context, @image) }/info.json",
      crossOriginPolicy: false
    });
  }
)
//]]>
</script>
    MARKUP
  end
end

Liquid::Template.register_tag('iiif', IIIFTag)

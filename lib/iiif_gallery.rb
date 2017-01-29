class IIIFGalleryTag < IIIF

  # need to handle case of single pages for one-offs, and 
  # a gallery page for a collection. Both should be optional. 
  # Previous and next links should be optional.

  # So: if no collection is named, do the one-offs, otherwise do the
  # collection. 

  def initialize(tag_name, image, tokens)
    super
    @image = image.strip
  end


  def render(context)
    images = ""
    label = @image
    site = context.registers[:site]
    coll = site.collections[label]
    if coll 
      if coll.metadata["paged"]
        docs = {}
        coll.docs.each do |doc|
          docs[File.basename(doc.path, ".*")] = doc
        end
        manifest = "./tiles/" + label + "/manifest.json"
        manifest = JSON.parse(File.read(manifest))
        manifest["sequences"][0]["canvases"].each do |canvas|
          basename = File.basename(canvas["images"][0]["resource"]["service"]["@id"], ".*")
          if basename != "index"
            doc = docs[basename]
            images += render_gallery(context, basename, manifest["@id"], label, doc, canvas)
          end
        end
      else
        coll.docs.each do |doc|
          basename = File.basename(doc.path, ".*")
          if basename != "index"
            manifest = "tiles/" + basename + "/manifest.json"
            manifest = JSON.parse(File.read(manifest))
            canvas = manifest["sequences"][0]["canvases"][0]
            images += render_gallery(context, basename, manifest["@id"], label, doc, canvas)
          end
        end
      end
      images
    end
  end
end

def render_gallery(context, basename, manifestid, label, doc, canvas)
  site = context.registers[:site]
  context.registers[:page]["canvas"] = canvas["@id"]
  context.registers[:page]["thumbnail"] = URI(canvas["thumbnail"]).path # get relative url
  context.registers[:page]["manifest"] = manifestid
  context.registers[:page]["thistitle"] = doc.data["title"]
  context.registers[:page]["thiscollection"] = label
  render_instance(basename, "iiif_thumbnail", context)
end

Liquid::Template.register_tag('iiif_gallery', IIIFGalleryTag)

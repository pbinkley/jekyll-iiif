class IIIF < Liquid::Tag

  def lookup(context, name)
  #  lookup = context
    if name == ""
      lookup = context["page"]["iiif_image"]
    else
      lookup = name
    end
    lookup
  end

  def get_include(context, name)
    gem_lib_path = Gem::Specification.find_by_name("jekyll-iiif").full_gem_path() + "/lib/_includes"
    jekyll_lib_path = context.registers[:site].source + "/_includes"
    if File.file?(jekyll_lib_path + "/" + name + ".html")
      lib_path = jekyll_lib_path
    else
      lib_path = gem_lib_path
    end
    Liquid::Template.parse(read_file(lib_path + "/" + name + ".html", context))
  end

  def read_file(file, context)
    File.read(file, file_read_opts(context))
  end

  def file_read_opts(context)
    context.registers[:site].file_read_opts
  end

  def render_instance(image, template, context)
    instancecounter = context.registers[:page]["instancecounter"] + 1 if context.registers[:page]["instancecounter"] && template != "iiif_thumbnail"
    instancecounter = 1 if instancecounter == nil
    thisimage = lookup(context, image)
    if instancecounter == 1 && template != "iiif_thumbnail"
      partial = get_include(context, "iiif_topper")
      topper = partial.render(context)
    else
      topper = ""
    end
    partial = get_include(context, template)
    # persist instancecounter in page hash - it will be overwritten by each subsequent IIIF instance on page
    context.registers[:page]["instancecounter"] = instancecounter
    context.registers[:page]["thisimage"] = thisimage
    instance = partial.render(context)
    topper + instance
  end

  def render_manifest(image, template, context)
    partial = get_include(context, template)
    partial.render(context)
  end

end


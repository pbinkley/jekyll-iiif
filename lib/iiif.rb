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
    thisinstance = @@instance
    thisimage = lookup(context, @image)
    if thisinstance == 1
      partial = get_include(context, "iiif_topper")
      topper = partial.render!(context)
    else
      topper = ""
    end
      partial = get_include(context, "iiif_instance")
    # TODO make context available to render, so we don't have to pass
    # specific variables
    instance = partial.render ({'thisimage' => thisimage, 'thisinstance' => thisinstance})
    topper + instance
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
end

Liquid::Template.register_tag('iiif', IIIFTag)

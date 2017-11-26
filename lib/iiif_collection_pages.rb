Jekyll::Hooks.register :site, :after_reset do |site|
  # if there is no iiif_viewer dir in jekyll source, copy from plugin lib
  unless File.directory?(site.source + '/iiif_viewer')
    spec = Gem::Specification.find_by_name('jekyll-iiif')
    lib_path = spec.full_gem_path + '/lib'
    Find.find(lib_path + '/iiif_viewer') do |file|
      next unless File.file?(file)
      # get relative path from site.source
      file = Pathname(file[lib_path.length..-1])
      site.static_files << Jekyll::StaticFile.new(site, lib_path, file.dirname.to_s, file.basename.to_s)
    end
  end

  site.collections.each do |collection|
    collection = collection[1]
    next unless collection.metadata['iiif'] && collection.metadata['output']
    label = collection.label
    title = collection.metadata['title'] ? collection.metadata['title'] : collection.label
    targetdir = 'galleries/_' + label
    FileUtils::mkdir_p targetdir
    imagefiles = Dir['_iiif/' + label + '/*'].sort!
    counter = 1
    imagefiles.each do |image|
      next unless File.file?(image)
      # cases for image x:
      #   member of paged collection y: imagename y-1, pagepath y-1
      #   member of unpaged collection y: imagename x-1, pagepath x
      basename = File.basename(image, '.*')
      if collection.metadata['paged']
        imagename = label + '-' + counter.to_s.rjust(4, '0')
        pagepath = targetdir + '/' + imagename + '.md'
      else
        imagename = basename + '-1'
        pagepath = targetdir + '/' + basename + '.md'
      end
      unless File.exist?(pagepath)
        File.open(pagepath, 'w') { |file| file.write('---\nlayout: iiif\ntitle: \'' + basename + '\'\niiif_image: \'' + imagename + '\'\n---\n\n') }
      end
      counter += 1
    end
    pagepath = targetdir[1, targetdir.length - 1]
    unless File.exist?(pagepath + '.md')
      File.open(pagepath + '.md', 'w') { |file| file.write('---\nlayout: page\ntitle: \'' + title + ' Gallery\'\npermalink: ' + pagepath + '/index.html\n---\n\n{% iiif_gallery ' + label + ' %}\n') }
    end
  end
end

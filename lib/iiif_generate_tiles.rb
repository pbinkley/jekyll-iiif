require 'find'

Jekyll::Hooks.register :site, :pre_render do |site|

	# if there is no iiif_viewer dir in jekyll source, copy from plugin lib
    unless File.directory?(site.source + "/iiif_viewer")
	    spec = Gem::Specification.find_by_name("jekyll-iiif")
	    lib_path = spec.full_gem_path() + "/lib"
    	Find.find(lib_path + "/iiif_viewer") do |file|
    		if File.file?(file)
	    		# get relative path from site.source
	    		file = Pathname(file[lib_path.length..-1])
    			site.static_files << Jekyll::StaticFile.new(site, lib_path, file.dirname.to_s, file.basename.to_s)
    		end
    	end
	end

	iiif_static = site.config["iiif_static"]

	FileUtils::mkdir_p 'tiles'

	imagefiles = Dir["_iiif/*"].sort!
	imagefiles.each do |image|
		extension = File.extname(image).sub(/^\./) {""}
		basename = File.basename(image, ".*")

		if !File.exist?("tiles/" + basename)
			system iiif_static + " -d tiles " + image
			# we need to insert "tiles/" into the @id in info.json
			# so that OpenSeadragon will build correct paths
			#puts "Fix info.json"
			data = File.read("tiles/" + basename + "/info.json") 
			data.gsub!(/\"\@id\"\: \"/, '"@id": "' + site.baseurl + '/tiles/') 
			File.open("tiles/" + basename + "/info.json", "w") do |f|
			  f.write(data)
			end
		end
	end
end
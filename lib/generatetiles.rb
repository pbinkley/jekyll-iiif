Jekyll::Hooks.register :site, :pre_render do |site|

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

# load the file as a string
data = File.read("tiles/" + basename + "/info.json") 
# globally substitute "install" for "latest"
data.gsub!(/\"\@id\"\: \"/, '"@id": "tiles/') 
# open the file for writing
File.open("tiles/" + basename + "/info.json", "w") do |f|
  f.write(data)
end

		end
	end
end
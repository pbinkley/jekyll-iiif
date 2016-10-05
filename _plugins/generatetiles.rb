Jekyll::Hooks.register :site, :pre_render do |site|

	iiif_static = site.config["iiif_static"]

	imagefiles = Dir["_iiif/*"].sort!
	imagefiles.each do |file|
		extension = File.extname(file).sub(/^\./) {""}
		basename = File.basename(file, ".*")

		if !File.exist?(basename)
			system iiif_static + " -d . " + file
		end
	end
end
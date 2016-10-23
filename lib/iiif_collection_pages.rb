Jekyll::Hooks.register :site, :after_reset do |site|

	if site.collections["iiif_collection"]
		FileUtils::mkdir_p '_iiif_collection'

		imagefiles = Dir["_iiif/*"].sort!
		imagefiles.each do |image|
			basename = File.basename(image, ".*")
			target = "_iiif_collection/" + basename + ".md"
			if !File.exist?(target)
				Jekyll.logger.info("IIIF:","Creating " + target)
				File.open(target, 'w') { |file| file.write("---\ntitle: '" + basename + "'\niiif_image: '" + basename + "'\n---\n\n") }
			end
		end
	end
end
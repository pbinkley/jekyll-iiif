Jekyll::Hooks.register :site, :after_reset do |site|
	for collection in site.collections
		collname = collection[0]
		collection = collection[1]
		if collection.metadata["iiif"] && collection.metadata["output"]
			label = collection.label
			title = collection.metadata["title"] ? collection.metadata["title"] : collection.label
			targetdir = "_" + label
			FileUtils::mkdir_p targetdir
			imagefiles = Dir["_iiif/" + label + "/*"].sort!
			counter = 1
			imagefiles.each do |image|
				if File.file?(image)
					# cases for image x:
					#   member of paged collection y: imagename y-1, pagepath y-1
					#   member of unpaged collection y: imagename x-1, pagepath x
					basename = File.basename(image, ".*")
					if collection.metadata["paged"]
						imagename = label + "-" + counter.to_s.rjust(4, "0")
						pagepath = targetdir + "/" + imagename + ".md"
					else
						imagename = basename + "-1"
						pagepath = targetdir + "/" + basename + ".md"
					end
					if !File.exist?(pagepath)
						File.open(pagepath, 'w') { |file| file.write("---\nlayout: iiif\ntitle: '" + basename + "'\niiif_image: '" + imagename + "'\n---\n\n") }
					end
					counter = counter + 1
				end
			end
			pagepath = targetdir[1,targetdir.length-1]
			if !File.exist?(pagepath + ".md")
				File.open(pagepath + ".md", 'w') { |file| file.write("---\nlayout: page\ntitle: '" + title + " Gallery'\npermalink: " + pagepath + "/index.html\n---\n\n{% iiif_gallery " + label + " %}\n") }
			end
		end
	end
end
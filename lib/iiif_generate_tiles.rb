require 'find'
require 'iiif_s3'

Jekyll::Hooks.register :site, :after_reset do |site|

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

	FileUtils::mkdir_p 'tiles'

	site.config['env'] = ENV['JEKYLL_ENV'] || 'development'
	hosturl = "http://127.0.0.1:4000"
	if site.config["env"] == "production"
		hosturl = site.config["url"]
	end

	imagedata = []

	id_counter = 0
	imagedirs = Dir["./_iiif/*"].sort!
	imagedirs.each do |imagedir|
		id_counter = id_counter + 1
		collname = File.basename(imagedir, ".*")

		# collection of images
		imagefiles = Dir[imagedir + "/*"].sort!
		counter = 1
		imagefiles.each do |imagefile|
			basename = File.basename(imagefile, ".*")

			# TODO populate values for :label etc. from _config.yml
			opts = {}
			thiscoll = nil
			site.collections.each do |coll|
				thiscoll = coll if coll[0] == collname
			end
			if thiscoll == nil
				Jekyll.logger.error("IIIF:", "Collection " + collname + " not found in _config.yml")
			else
				fields = thiscoll[1].metadata["fields"]
				if thiscoll[1].metadata["paged"]
					opts[:id] = collname
					opts[:page_number] = counter.to_s.rjust(4, "0")
					opts[:is_document] = false
					opts[:is_primary] = counter == 1
					opts[:section] = counter.to_s
					opts[:section_label] = "p. " + counter.to_s

					allowablefields = site.config["iiif_allowablefields"]
					fields.each do |field|
						if allowablefields.include? field[0]
							if field[0] == 'logo'
								# convert logo to absolute url if necessary
								logo = field[1]
								uri = URI(logo)
								if !uri.host
									logo = URI.join(hosturl, site.config["baseurl"] + "/", logo)
								end
								opts['logo'] = logo
							else
								opts[field[0]] = field[1]
							end
						else
							Jekyll.logger.error("IIIF:", "Collection metadata for " + collname + " includes bad field '" + field[0] + "'")
						end
					end

					opts[:path] = imagefile
				else
					opts[:id] = basename
					opts[:is_document] = true
					opts[:path] = imagefile
					opts[:label] = site.config["title"] + " - " + collname + " - " + basename
				end

				i = IiifS3::ImageRecord.new(opts)
				counter = counter + 1
				imagedata.push(i)
			end
		end
	end
	builder = IiifS3::Builder.new({
		:base_url => hosturl + site.baseurl + "/tiles",
		:output_dir => "./tiles"
	})
	builder.load(imagedata)
	builder.process_data()

end
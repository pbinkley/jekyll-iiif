require 'find'
require 'iiif_s3'

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

	FileUtils::mkdir_p 'tiles'

	imagedata = []

	imagefiles = Dir["./_iiif/*"].sort!
	imagefiles.each do |image|
		basename = File.basename(image, ".*")

		imagedata.push(IiifS3::ImageRecord.new({
			:id => basename, 
			# :label => "This is the label", 
			# :description => "This is the description", 
			# :attribution => "This is the attribution", 
			# :logo => "http://www.wallandbinkley.com/logo.jpg", 
			:path => image
		}))
	end
	#Jekyll.logger.info("IIIF_S3:", JSON.pretty_generate(site))
	builder = IiifS3::Builder.new({
		:base_url => "http://127.0.0.1:4000" + site.baseurl + "/tiles",
		:output_dir => "./tiles"
	})
	builder.load(imagedata)
	builder.process_data()
end
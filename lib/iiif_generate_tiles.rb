require 'find'
require 'fileutils'
require 'pathname'
require 'iiif_s3'
require 'json'
require 'pry'

# tile generator
class TileGenerator < Jekyll::Command
  class << self
    def markdownify(s)
      @markdownconverter.convert(s).strip.gsub(/^<p>(.*)<\/p>$/, "\\1")
      # the gsub removes the <p>...</p> frame
    end

    def init_with_program(prog)
      prog.command(:iiif) do |c|
        c.syntax 'iiif'
        c.description 'Process IIIF derivatives.'
        c.option 'verbose', '-V', '--verbose', 'Print verbose output.'
        c.option 'iiif_regenerate_manifests', '-m', '--manifests', 'Regenerate all manifests.'

        c.action do |args, options|
          jekyll_options = configuration_from_options(options)
          site = Jekyll::Site.new(jekyll_options)
          reader = Jekyll::DataReader.new(site)
          data = reader.read('_data-production')
          documents = reader.content['documents']
          tilesdir = site.source + '/' + (site.config['tilesdir'] || 'tiles')
          # binding.pry

          FileUtils::mkdir_p tilesdir

          # placeholder value, which will be replaced when tiles
          # are deployed to target
          iiifurl = 'IIIF_URL'

          # trigger regeneration of manifests by deleting old ones
          if options['iiif_regenerate_manifests']
            Jekyll.logger.debug('IIIF:', 'Deleting manifests to trigger regeneration')
            Find.find(tilesdir) do |path|
              File.delete(path) if path =~ /.*\/manifest\.json$/
            end
          end

          # create a markdownify converter
          @markdownconverter = site.find_converter_instance(Jekyll::Converters::Markdown)

          imagedata = []

          id_counter = 0
          iiifsource = site.config['iiifsourcedir'] || '_iiif'
          imagedirs = Dir[site.source + '/' + iiifsource + '/*'].sort!
          # binding.pry
          imagedirs.each do |imagedir|
            id_counter = id_counter + 1
            collname = File.basename(imagedir, '.*')
            Jekyll.logger.debug('IIIF:', 'Collection ' + collname)

            thiscoll = nil
            documents.each do |coll|
              thiscoll = coll if coll['id'] == collname
            end
            unless thiscoll
              Jekyll.logger.error('IIIF:', 'Collection ' + collname + ' not found in _config.yml')
            else
              # collection of images
              imagefiles = Dir[imagedir + '/*'].sort!
              counter = 1
              imagefiles.each do |imagefile|
                basename = File.basename(imagefile, '.*')
                Jekyll.logger.debug('IIIF:', 'Image ' + basename)

                # TODO: populate values for :label etc. from _config.yml
                opts = {}
                fields = thiscoll['data']
                unless thiscoll['unpaged']
                  opts[:id] = collname
                  opts[:label] = thiscoll['name']
                  opts[:page_number] = counter.to_s.rjust(4, '0')
                  opts[:is_document] = false
                  opts[:is_primary] = counter == 1
                  opts[:section] = counter.to_s
                  opts[:section_label] = 'p. ' + counter.to_s

                  allowablefields = site.config['iiif_allowablefields']
                  fields.each do |field|
                    if allowablefields.include? field[0]
                      if field[0] == 'logo'
                        # convert logo to absolute url if necessary
                        logo = field[1]
                        uri = URI(logo)
                        Jekyll.logger.debug('IIIF:', 'logo uri: ' + uri.to_s)
                        Jekyll.logger.debug('IIIF:', 'iiifurl: ' + iiifurl)
                        unless uri.host
                          logo = iiifurl + site.config['baseurl'] + '/' + logo
                        end
                        opts['logo'] = logo
                      else
                        opts[field[0]] = markdownify(field[1])
                      end
                    else
                      Jekyll.logger.error('IIIF:', 'Collection metadata for ' + collname + ' includes bad field \'' + field[0] + '\'')
                    end
                  end

                  opts[:path] = imagefile
                else
                  opts[:id] = basename
                  opts[:is_document] = true
                  opts[:path] = imagefile
                  opts[:label] = site.config['title'] + ' - ' + collname + ' - ' + basename
                end

                i = IiifS3::ImageRecord.new(opts)
                Jekyll.logger.debug('IIIF:', 'ImageRecord ' + i.inspect)

                counter += 1
                imagedata.push(i)
              end
            end
          end
          builder = IiifS3::Builder.new(
            base_url: iiifurl + site.baseurl + '/tiles',
            output_dir: tilesdir
          )
          builder.load(imagedata)
          builder.process_data
        end
      end
    end
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  iiifurl = site.config['iiifurl']
  tilesdir = site.source + '/' + (site.config['tilesdir'] || './tiles')
# binding.pry
  Jekyll.logger.debug('IIIF:', 'deploy tiles from ' + tilesdir + ' with iiifurl ' + iiifurl)

  sourcepath = Pathname.new(site.source)

  Find.find(tilesdir) do |file|
    next unless File.file?(file)
    outfilepath = site.dest + '/tiles/' + (Pathname.new(file).relative_path_from(Pathname.new(tilesdir))).to_s
    #binding.pry
    FileUtils.mkdir_p(File.dirname(outfilepath))
    if file =~ /.*\.json$/
      text = File.read(file)
      new_contents = text.gsub(/IIIF_URL/, iiifurl)
      File.open(outfilepath, 'w') { |outfile| outfile.puts new_contents }
    else
      FileUtils.cp(file, outfilepath, :preserve => true)
    end
  end

  site.config['compounds'].each do |compound|
    compoundkey = compound
    compounddata = site.data[compoundkey]
    # add annotationlists to canvases in wardiary manifest.json
    manifestFile = site.dest + '/tiles/' + compoundkey + '/manifest.json'
    manifest = JSON.parse(File.read(manifestFile))
    annotatedPages = compounddata.group_by { |o| o['canvas'] }.keys
    annotatedCanvases = manifest['sequences'][0]['canvases'].select { |c| annotatedPages.include? c['@id'].gsub(/.*?(\d*)\.json$/, '\1').to_i }
    annotatedCanvases.each do |canvas|
      canvasId = URI.parse(canvas['@id'])
      annotationFile = site.dest + '/tiles/' + compoundkey + '/annotation/photos-' + canvasId.path.split('/').last
      canvas['otherContent'] = [{
        '@id': site.config['iiifurl'] + site.baseurl + '/tiles/' + compoundkey + '/annotation/photos-' + canvasId.path.split('/').last,
        '@type': 'sc:AnnotationList'
      }]
      #binding.pry
    end

    File.open(manifestFile, 'w') { |file| file.write(manifest.to_json) }  
  end
end

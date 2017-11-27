require 'find'
require 'fileutils'
require 'pathname'
require 'iiif_s3'

# tile generator
class TileGenerator < Jekyll::Command
  class << self
    def init_with_program(prog)
      prog.command(:iiif) do |c|
        c.syntax 'iiif'
        c.description 'Process IIIF derivatives.'
        c.option 'verbose', '-V', '--verbose', 'Print verbose output.'
        c.option 'iiif_regenerate_manifests', '-m', '--manifests', 'Regenerate all manifests.'

        c.action do |args, options|
          jekyll_options = configuration_from_options(options)
          site = Jekyll::Site.new(jekyll_options)

          FileUtils::mkdir_p site.source + '/tiles'

          # placeholder value, which will be replaced when tiles
          # are deployed to target
          iiifurl = 'IIIF_URL'

          # trigger regeneration of manifests by deleting old ones
          if options['iiif_regenerate_manifests']
            Jekyll.logger.debug('IIIF:', 'Deleting manifests to trigger regeneration')
            Find.find(site.source + '/tiles') do |path|
              File.delete(path) if path =~ /.*\/manifest\.json$/
            end
          end

          imagedata = []

          id_counter = 0
          imagedirs = Dir[site.source + '/_iiif/*'].sort!
          imagedirs.each do |imagedir|
            id_counter = id_counter + 1
            collname = File.basename(imagedir, '.*')
            Jekyll.logger.debug('IIIF:', 'Collection ' + collname)

            thiscoll = nil
            site.collections.each do |coll|
              thiscoll = coll if coll[0] == collname
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
                fields = thiscoll[1].metadata['fields']
                if thiscoll[1].metadata['paged']
                  opts[:id] = collname
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
                        opts[field[0]] = field[1]
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
            output_dir: './tiles'
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

  Jekyll.logger.debug('IIIF:', 'deploy tiles with iiifurl ' + iiifurl)

  sourcepath = Pathname.new(site.source)

  Find.find(site.source + '/tiles') do |file|
    next unless File.file?(file)
    outfilepath = site.dest + '/' + (Pathname.new(file).relative_path_from(sourcepath)).to_s
    FileUtils.mkdir_p(File.dirname(outfilepath))
    if file =~ /.*\.json$/
      text = File.read(file)
      new_contents = text.gsub(/IIIF_URL/, iiifurl)
      File.open(outfilepath, 'w') { |outfile| outfile.puts new_contents }
    else
      FileUtils.cp(file, outfilepath)
    end
  end
end

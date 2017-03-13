Gem::Specification.new do |s|
  s.name        = 'jekyll-iiif'
  s.version     = '0.3.6'
  s.date        = '2017-03-12'
  s.summary     = "Jekyll plugin to embed static IIIF images in jekyll pages"
  s.description = "Using IIIF_S3, it generates static IIIF tiles and other artefacts and provides Liquid tags to embed them in Jekyll pages."
  s.authors     = ["Peter Binkley"]
  s.email       = 'peter.binkley@ualberta.ca'
  s.files       = Dir.glob("{lib}/**/*") + %w(LICENSE README.md)
  s.homepage    = 'https://pbinkley.github.io/jekyll-iiif/'
  s.license     = 'Apache 2.0'
  s.requirements = "imagemagick (required by iiif_s3)"
  s.add_dependency 'iiif_s3'
end

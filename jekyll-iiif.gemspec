Gem::Specification.new do |s|
  s.name        = 'jekyll-iiif'
  s.version     = '0.0.0'
  s.date        = '2016-10-08'
  s.summary     = "Jekyll plugin to embed static IIIF images in jekyll pages"
  s.description = "First stab at using static_iiif.py to generate static tiles, and provide a liquid tag to embed IIIF images in Jekyll pages."
  s.authors     = ["Peter Binkley"]
  s.email       = 'peter.binkley@ualberta.ca'
  s.files       = ["lib/generatetiles.rb", "lib/iiif.rb"]
  s.homepage    =
    'https://github.com/pbinkley/jekyll-iiif'
  s.license       = 'Apache 2.0'
end
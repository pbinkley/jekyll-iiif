# jekyll-iiif
Jekyll plugin to embed static IIIF images in jekyll pages

This is a first stab at a [Jekyll](https://jekyllrb.com/) plugin that generates static tiles and a IIIF [Image API](http://iiif.io/api/image/2.1/) ```info.json``` file for images that will be displayed in the Jekyll site. It uses [zimeon](https://github.com/zimeon/)'s ```iiif_static.py``` script (part of his [IIIF Image API Python library](https://github.com/zimeon/iiif) and incorporates the [OpenSeadragon](https://openseadragon.github.io/) viewer.

Demo: [Council of Constance](https://www.wallandbinkley.com/projects/2016/jekyll-iiif-demo/)

To use it:

- Install [Jekyll](https://jekyllrb.com/)
- Install the [IIIF Image API Python library](https://github.com/zimeon/iiif), somewhere on the same machine
- Create a Jekyll instance with ```jekyll new```
- Within that Jekyll instance:
	- Create a Gemfile if there isn't one there already, and add to it:
		```gem 'jekyll-iiif', :git => 'https://github.com/pbinkley/jekyll-iiif.git'```
	- Add the gem to your ```_config.yml```: ```gems: [jekyll-iiif]
```
	- Run ```bundle install``` to install the gem. If necessary, install ```bundler``` with ```gem install bundler```.
	- Create a directory ```_iiif``` and put source images in it (nice big high-resolution images are best, to show off what IIIF can do)
	- Edit your ```_config.yaml``` to provide the full path to the ```iiif_static.py``` script, with a line like:

		```iiif_static: /full/path/to/iiif_static.py```

	- Edit the Jekyll css to add a section like this, so that your OpenSeadragon viewer will have width and height (otherwise it will be invisible):

		```
		.openseadragon {
			width: 100%;
			height: 500px;
		}
		```

## Single image

To serve a single image, create a Markdown page such as ```iiif.md```, containing a yaml header and a call to the ```iiif``` plugin, like this:

	```
	---
	title: jekyll-iiif demo
	---

	{% iiif imagename %}
	```

(Using the base name, without file extension, of one of the images you put in the ```_iiif``` directory) 

Render and serve the site with ```jekyll s```. You should see the output of the ```iiif_static.py``` script as it generates the tiles, something like:

	```
      Generating... 
	. / 00cover/0,0,512,512/512,/0/default.jpg
	. / 00cover/0,512,512,512/512,/0/default.jpg
	. / 00cover/0,1024,512,512/512,/0/default.jpg
	. / 00cover/0,1536,512,512/512,/0/default.jpg
	. / 00cover/0,2048,512,512/512,/0/default.jpg
	...
	```
Tiles are stored in a directory at ```tiles/<filename>```, which will be copied to the Jekyll site as static files. Tiles are only generated if their target directory doesn't already exist. To force tiles to be regenerated, therefore, just delete the ```tiles``` directory or the subdirectory for a given image.

Visit the page at [http://127.0.0.1:4000/iiif.html](http://127.0.0.1:4000/iiif.html). You should see your image displayed by OpenSeadragon in a deeply-zoomable tiled IIIF display

Instead of specifying the image name in the iiif call, you can put in the page yaml header as "iiif_image: imagename" (again without the filename extension), and invoke it with ```{% iiif %}```. 

A page can include more than one IIIF image.

## Collection

You can have jekyll-iiif generate pages for a [Collection](https://jekyllrb.com/docs/collections/) based one-to-one on the images you provide. 

To generate and render a page for each image:

- create a ```iiif_collection``` collection in ```_config.yml```:

```
collections:
  iiif_collection:
    output: true
defaults:
  - scope:
      path: ""
      type: iiif_collection
    values:
      layout: iiif_image
```

- notice that the collection uses ```iiif_image```; you need to create this layout in ```_layouts/iiif_image.html```:

```
---
layout: default
---
<article class="post">

  <header class="post-header">
    <h1 class="post-title">{{ page.title }}</h1>
  </header>

  <div class="post-content">
    {% iiif %}
    {{ content }}
  </div>

</article>
```

The important thing is that the layout contain the ```{% iiif %}``` tag, which will trigger the display of the image that is specified in the page's ```iiif_image``` yaml tag.

- create a directory ```_iiif_collection``` (note the leading underscore). This will contain the pages corresponding to the images in ```_iiif``` (e.g. image ```page001.tiff``` needs a file ```page001.md```). Files will be created by ```jekyll-iiif``` for any image that doesn't already have one, so it's easy to create the necessary skeleton pages and then edit them as needed. The default skeleton pages just contain the yaml header, populated with the filename:

```
---
title: page001
iiif_image: page001
---

```

This file could be modified to provide the proper title, add text to be displayed under the IIIF viewer, or anything else Jekyll can do.

A page of thumbnails can be generated using the ```iiif_gallery``` tag. For example, the ```index.md``` might include ```{% iiif_gallery %}```. Each image is represented by a thumbnail (actually a IIIF viewer instance with pan and zoom disabled); the formatting is controlled by CSS applied to the ```div.iiif_thumbnail```. (As with the main image display you'll want to add width and height at least, to make the div visible.) Clicking a thumbnail will take you to the collection page for that image.

## Next steps

- use [iiif_s3](https://github.com/cmoa/iiif_s3) to generate the static tiles, so that an external installation of the Python library will be unnecessary
- ennable multiple collections, based on subdirectories in the ```_iiif``` folder
- generate [Presentation API manifests](http://iiif.io/api/presentation/2.0/#manifest) for collections, to allow the publication of an IIIF object that can viewed in external viewers
- develop ```_include``` files for other IIIF viewers beside OpenSeadragon
- provide thumbnail images that don't require a IIIF viewer instance


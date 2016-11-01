# jekyll-iiif
Jekyll plugin to embed static IIIF images in jekyll pages

This is a first stab at a [Jekyll](https://jekyllrb.com/) plugin that generates static tiles and a IIIF [Image API](http://iiif.io/api/image/2.1/) ```info.json``` file for images that will be displayed in the Jekyll site. It uses [iiif_s3](https://github.com/cmoa/iiif_s3) and incorporates the [OpenSeadragon](https://openseadragon.github.io/) viewer. (For the time being it installs ```iiif_s3``` from [my fork](https://github.com/pbinkley/iiif_s3), but I'll point it back at the source repo as soon as possible.)

Demo: [Council of Constance](https://www.wallandbinkley.com/projects/2016/jekyll-iiif-demo/)

To use it:

- Install [Jekyll](https://jekyllrb.com/)
- Create a Jekyll instance with ```jekyll new```
- Within your Jekyll instance:
	- Create a Gemfile if there isn't one there already, and add to it:

		```
		gem 'jekyll-iiif', :github => 'pbinkley/jekyll-iiif'
		gem 'iiif_s3', :github => 'pbinkley/iiif_s3'
		```

	- Add the jekyll-iiif gem to the ```_config.yml```: ```gems: [jekyll-iiif]``` or add ```- jekyll-iiif``` to an existing list of gems
	- Run ```bundle install``` to install the gem and dependencies. If necessary, install ```bundler``` with ```gem install bundler```.
	- Create a directory ```_iiif``` and put source images in it (nice big high-resolution images are best, to show off what IIIF can do)

## Single image

To serve a single image, create a Markdown page such as ```iiif.md```, containing a yaml header and a call to the ```iiif``` plugin, like this:

```
---
title: jekyll-iiif demo
---

{% iiif imagename %}
```

(Using the base name, without file extension, of one of the images you put in the ```_iiif``` directory) 

Render and serve the site with ```jekyll s```. Tiles and IIIF artefacts will be generated for images that need them.

Tiles are stored in a directory at ```tiles/images/<filename>```, and will be copied to the Jekyll site as static files. Tiles are only generated if their target directory doesn't already exist. To force tiles to be regenerated, therefore, just delete the ```tiles```.

Visit the page at [http://127.0.0.1:4000/iiif.html](http://127.0.0.1:4000/iiif.html). You should see your image displayed by OpenSeadragon in a deeply-zoomable tiled IIIF display.

Instead of specifying the image name in the iiif call, you can put it in the page yaml header as "iiif_image: imagename" (again without the filename extension), and invoke it with ```{% iiif %}```. 

A page can include more than one IIIF image.

The size of the IIIF viewer div is hardcoded in ```lib/_includes/iiif_instance.html``` as ```width: 100%; height: 500px```. It can be overriden by overriding ```iiif_instance.html```, or simply by applying css rules to ```div.iiif_instance```.

## Collection

You can have jekyll-iiif generate pages for a [Collection](https://jekyllrb.com/docs/collections/) based one-to-one on the images you provide. The idea is to make it easy to publish a set of images with minimal overhead: you can drop all the images in the ```_iiif``` directory, and the necessary skeleton pages will be created for you. You can then edit those pages as needed.

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

- notice that the collection uses layout ```iiif_image```; you need to create this in ```_layouts/iiif_image.html```:

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

The important thing is that the layout must contain the ```{% iiif %}``` tag, which will trigger the display of the image that is specified in the page's ```iiif_image``` yaml tag. You can take advantage of the collection structure to provide [previous and next links](https://gist.github.com/budparr/3e637e575471401d01ec).

When you start the server again, you can visit the collection at [http://127.0.0.1:4000/iiif_collection/](http://127.0.0.1:4000/iiif_collection/)

A directory ```_iiif_collection``` (note the leading underscore) will be created if it doesn't exist. This will contain the pages corresponding to the images in ```_iiif``` (e.g. image ```page001.tiff``` needs a file ```page001.md```). Files will be created by ```jekyll-iiif``` for any image that doesn't already have one, so it's easy to create the necessary skeleton pages and then edit them as needed. The default skeleton pages just contain the yaml header, populated with the filename:

```
---
title: 'page001'
iiif_image: 'page001'
---
```

This file can be modified to provide the proper title, add text to be displayed under the IIIF viewer, or anything else Jekyll can do. The file won't be overwritten.

A page of thumbnails for the images in the collection can be generated using the ```iiif_gallery``` tag. For example, ```gallery.md``` might include ```{% iiif_gallery %}```. Each image is represented by a thumbnail; the formatting is controlled by CSS applied to ```div.iiif_thumbnail```. Clicking a thumbnail will take you to the collection page for that image.

## Manifests

Thanks to ```iiif_s3```, Presentation Manifests are created for each image. This allows external IIIF clients to import the item and display it. At the moment these manifests are created for each image individually; in a later release ```jekyll-iiif``` will use ```iiif_s3```'s ability to manage images as pages of an item, and produce a manifest at the collection level.

To serve manifests to external clients it is necessary to at a [CORS header](http://enable-cors.org/index.html). In the jekyll development environment, this is achieved by adding this configuration to ```_config.yml```:

```
webrick:
  headers:
    "Access-Control-Allow-Origin": "*"
```

In a production Apache environment, add ```Header set Access-Control-Allow-Origin "*"``` to a ```.htaccess``` file in the root of the jekyll deployment.

In either case you can find the manifest at ```tiles/<imagename>/manifest.json```. You can paste its url into a demo such as [Mirador](http://projectmirador.org/demo/): mouse over the four-square icon in a viewer menu bar and select "Replace Object", then paste the url of the manifest in the "Add new object from URL" box. Or, more easily, you can drag the IIIF logo from the gallery page to the Mirador demo, using [IIIF's drag-n-drop functionality](http://zimeon.github.io/iiif-dragndrop/).

Note that the manifest must include absolute urls to all IIIF resources, since it will be used outside of the original site. This is awkward when moving between development and production jekyll environments. ```jekyll-iiif``` will use the default development host ```http://127.0.0.1:4000``` when building the manifest, unless the ```JEKYLL_ENV``` environment variable is set to "production". In that case it will use the ```url``` property set in ```_config.yml```. However, ```iiif_s3``` won't be aware of the change, and won't regenerate the manifests when the environment changes. When changing environments, therefore, it is currently necessary to delete the ```tiles``` directory to force the regeneration of all the tiles and manifests. 

## Next steps

- enable multiple collections, based on subdirectories in the ```_iiif``` folder
- enable paged items in ```iiif_s3```
- enable populating the [Presentation API manifests](http://iiif.io/api/presentation/2.0/#manifest) that IIIF_S3 generates with metadata for the collection, to allow the publication of an IIIF object that can viewed in external viewers
- develop ```_include``` files for other IIIF viewers beside OpenSeadragon
- explore using Jekyll theme to make it easier to use default _includes or override them

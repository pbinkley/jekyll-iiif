# jekyll-iiif
Jekyll plugin to embed static IIIF views in jekyll pages

This is a first stab at a [Jekyll](https://jekyllrb.com/) plugin that generates static tiles and a IIIF [Image API](http://iiif.io/api/image/2.1/) ```info.json``` file for images that will be displayed in the Jekyll site. It uses [iiif_s3](https://github.com/cmoa/iiif_s3) and incorporates the [OpenSeadragon](https://openseadragon.github.io/) and [Mirador](http://projectmirador.org/) viewers. 

Demo: [Council of Constance](https://www.wallandbinkley.com/projects/2016/jekyll-iiif-demo/)

To use it:

- Install [Jekyll](https://jekyllrb.com/)
- Create a Jekyll instance with ```jekyll new```
- Within your Jekyll instance:
	- Create a Gemfile if there isn't one there already, and add to it:

		```
		gem 'jekyll-iiif', :github => 'pbinkley/jekyll-iiif'
		gem 'iiif_s3', :github => 'cmoa/iiif_s3'
		```

	- Add the jekyll-iiif gem to the ```_config.yml```: ```gems: [jekyll-iiif]``` or add ```- jekyll-iiif``` to an existing list of gems
	- Run ```bundle install``` to install the gem and dependencies. If necessary, install ```bundler``` with ```gem install bundler```.

## Add images

	- Create a directory ```_iiif``` and put source images into subdirectories within it (nice big high-resolution images are best, to show off what IIIF can do). The names of the subdirectories become the labels of Jekyll collections.
	- add those subdirectories to the collections in ```_config.yml```:

```
collections:
  narrenschiff:
    output: true
    iiif: true
    paged: true
  iiif_images:
    output: true
    iiif: true

defaults:
  - scope:
      path: ""
      type: iiif_collection
    values:
      layout: iiif_image
```

	- set ```paged: true``` if the collection represents pages in a book; leave it out for loose, independent images.
	- when you build the Jekyll site, ```jekyll-iiif``` will create pages for each of the collections (see below).

## Serve single image

To serve a single image, create a Markdown page such as ```iiif.md```, containing a yaml header and a call to the ```iiif``` plugin, like this:

```
---
title: jekyll-iiif demo
---

{% iiif <imagename> %}
```

(Using the base name, without file extension, of one of the images you put in the ```_iiif``` directory) 

Render and serve the site with ```jekyll s```. Tiles and IIIF artefacts will be generated for images that need them.

Visit the page at [http://127.0.0.1:4000/iiif.html](http://127.0.0.1:4000/iiif.html). You should see your image displayed by OpenSeadragon in a deeply-zoomable tiled IIIF display.

Tiles are stored in a directory at ```tiles/images/<filename>```, and will be copied to the Jekyll site as static files. Tiles are only generated if their target directory doesn't already exist. To force tiles to be regenerated, therefore, just delete the ```tiles``` directory.

Instead of specifying the image name in the ```iiif``` call, you can put it in the page yaml header as "iiif_image: imagename" (again without the filename extension), and invoke it simply with ```{% iiif %}```. 

A page can include more than one IIIF image.

The size of the IIIF viewer div is hardcoded in ```lib/_includes/iiif_image.html``` as ```width: 100%; height: 500px```. It can be overriden by overriding ```iiif_image.html``` (i.e. by making a modified copy in the ```_includes``` directory of your Jekyll instance), or simply by applying css rules to ```div.iiif_image```.

## Collection

You can have jekyll-iiif generate pages for a [Collection](https://jekyllrb.com/docs/collections/) based one-to-one on the images you provide. The idea is to make it easy to publish a set of images with minimal overhead: you can drop all the images in a subdirectory of the ```_iiif``` directory, and the necessary skeleton pages will be created for you. You can then edit those pages as needed.

- notice that the automatically generated pages use layout ```iiif_image```; you need to create this as a file in ```_layouts/iiif_image.html```:

```
---
layout: default
---

{% capture the_collection %}{{page.collection}}{% endcapture %}
  {% if page.collection %}
    {% assign documents = site[the_collection] %}
  {% endif %}
{% for link in documents  %}
  {% if link.title == page.title %}
    {% unless forloop.first %}
      {% assign prevurl = prev.url %}
      {% assign prevtitle = prev.title %}
    {% endunless %}
    {% unless forloop.last %}
      {% assign next = documents[forloop.index] %}
      {% assign nexturl = next.url %}
      {% assign nexttitle = next.title %}
    {% endunless %}
  {% endif %}
  {% assign prev = link %}
{% endfor %}

<div class="prevnext">
{% if prevurl %}Previous: <a href="{{site.baseurl}}{{prevurl}}" class="prev">{{prevtitle}}</a>{% endif %}<br />

{% if nexturl %}Next: <a href="{{site.baseurl}}{{nexturl}}" class="next">{{nexttitle}}</a>{% endif %}
</div>

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

The important thing is that the layout must contain the ```{% iiif %}``` tag, which will trigger the display of the image that is specified in the page's ```iiif_image``` yaml tag. (The presentation of previous and next links is based on [this](https://gist.github.com/budparr/3e637e575471401d01ec)).

When you start the server again, you can visit the collection at [http://127.0.0.1:4000/iiif_collection/](http://127.0.0.1:4000/iiif_collection/)

A directory ```_<directoryname>``` (note the leading underscore) will be created for each collection if it doesn't already exist. This will contain the markdown files corresponding to the images in ```_iiif``` (e.g. image ```page001.tiff``` triggers a file ```page001.md```). Files will be created by ```jekyll-iiif``` for any image that doesn't already have one, so it's easy to create the necessary skeleton pages and then edit them as needed. The default skeleton pages just contain the yaml header, populated with the filename:

```
---
layout: iiif
title: 'page001'
iiif_image: 'iiif_collection-1'
---
```

(Note that the title is from the original image name, but the ```iiif_image``` uses the new name provided by ```iiif_s3```, based on the collection name.) This markdown file can be modified to provide the proper title, add text to be displayed under the IIIF viewer, or anything else Jekyll can do. The file won't be overwritten by jekyll-iiif.

A page of thumbnails for the images in the collection can be generated using the ```iiif_gallery``` tag. One is generated automatically for each collection, providing the ```index.html``` in the collection directory. Each image is represented by a thumbnail; the formatting can be controlled by CSS applied to ```div.iiif_thumbnail```. Clicking a thumbnail will take you to the page for that image. Each thumbnail is accompanied by a IIIF logo, which supports [drag-and-drop](http://zimeon.github.io/iiif-dragndrop/) to another IIIF viewer.

## Manifests

Thanks to ```iiif_s3```, Presentation Manifests are created for each collection or image. This allows external IIIF clients to import the item and display it. All images belong to collections, but collections can be paged or unpaged. Paged collections are like books: the images are viewable as parts of a single item. Unpaged collections treat images as independent items. The status of a collection is controlled by the ```paged``` element in the collection's metadata in ```_config.yml```: ```paged: true``` or ```paged: false```. Paged collections get a single manifest containing all pages, unpaged collections get a separate manifest for each image.

To serve manifests to external clients over HTTP it is necessary to add a [CORS header](http://enable-cors.org/index.html). In the jekyll development environment, this is achieved by adding this configuration to ```_config.yml```:

```
webrick:
  headers:
    "Access-Control-Allow-Origin": "*"
```

In a production Apache environment, add ```Header set Access-Control-Allow-Origin "*"``` to a ```.htaccess``` file in the root of the jekyll deployment.

In either case you can find the manifest at ```tiles/<name>/manifest.json```. You can paste its url into a demo such as [Mirador](http://projectmirador.org/demo/).

Note that the manifest must include absolute urls to all IIIF resources, since it must be usable outside of the original site. This is awkward when moving between development and production jekyll environments. ```jekyll-iiif``` will use the default development host ```http://127.0.0.1:4000``` when building the manifest, unless the ```JEKYLL_ENV``` environment variable is set to "production". In that case it will use the ```url``` property set in ```_config.yml```. However, ```iiif_s3``` won't be aware of the change, and won't regenerate the manifests when the environment changes. When changing environments, therefore, it is currently necessary to delete the ```tiles``` directory to force the regeneration of all the tiles and manifests. 

## Next steps

- enable populating the [Presentation API manifests](http://iiif.io/api/presentation/2.0/#manifest) that IIIF_S3 generates with metadata for the collection
- develop ```_include``` files for other IIIF viewers beside OpenSeadragon and Mirador
- explore using Jekyll theme to make it easier to use default _includes or override them

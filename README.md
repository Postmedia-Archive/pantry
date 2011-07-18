# Pantry
A JSON/XML resource caching library based on Request

## Introduction

Pantry is an HTTP client cache used to minimize requests for external JSON and XML feeds.  The Pantry will cache resources to minimize round trips, utilizing the local cache when available and refresh the cache (asynchronously) as needed.

This package is in it's very early stages and should be considered 'Proof of Concept' at this point in time.  As it stands right now, only JSON data is supported.  There is no error handling, no support for XML.  Heck, I haven't even looked into any real efficiencies yet.

As with any of our projects, constructive criticism is encouraged.

## Installing

Just grab [node.js](http://nodejs.org/#download) and [npm](http://github.com/isaacs/npm) and you're set:

	npm install pantry
	
Note that Pantry was developed using [CoffeeScript](http://coffeescript.org) and uses the amazing [Request](https://github.com/mikeal/request) library for all HTTP requests.

## Using

Work in progress.  See the examples for the time being.

To utilize the pantry, simply require it, optionally override some default values, and then request your resource(s) via the fetch method

	pantry = require 'pantry'
	pantry.configure { shelfLife: 5 }
	
	pantry.fetch { uri: 'http://search.twitter.com/search.json?q=winning'}, (error, item) ->
		console.log "\t#{item.results[0].text}"

At this item, the following configuration options can be specified:

* shelfLife - number of seconds before a resource reaches it's best-before-date
* maxLife - number of seconds before a resource spoils
* capacity - the maximum number of items to keep in the pantry
* ideal - when cleaning up, the ideal number of items to keep in the pantry

When you request a resource from the pantry, a couple interesting things happen.  If the item is available in the pantry, and hasn't 'spoiled', it will be returned immediately via the callback.  If it has expired (it's beyond its best before date) but hasn't spoiled, it will still be returned and then refreshed in the background.

> Ode to my immigrant mother:  The best before date is treated as a recommendation.  If it hasn't visibly spoiled it's probably still good to use, so use it until we have a chance to go shopping.  Especially if it's salad dressing, that stuff never goes bad as long as it's in the fridge.

If the resource isn't available in the pantry, or the item has spoiled, then the item will be retrieved immediately and won't be passed on to the callback method until we have the resource on hand.

Finally, every time an item is added to pantry, we ensure we haven't reached capacity.  If we have, then we first start with throwing out any spoiled items.  After that, if we are still above capacity we will get rid of the expired items, and if we're really desperate we will need to throw out some good items just to make room.

## Outstanding Issues

A lot:

* Integrated testing framework
* Integrated benchmarks
* Logging/metrics
* Security considerations
* Error handling of any sort
* Support for retrieve multiple resources in parallel
* Support for conditional GETs (ETag)
* Support for XML Data
* More/Better examples
* Documentation, Documentation, Documentation

## Created by

* Edward de Groot

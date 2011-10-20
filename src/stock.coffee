EventEmitter = require('events').EventEmitter
request = require 'request'
xml2js = require 'xml2js'
Log = require 'coloured-log'

module.exports = class StockedItem extends EventEmitter
	constructor: (@options) ->
		@options = {uri: options} if typeof options is 'string'
		@options.shelfLife ?= 60
		@options.maxLife ?= 30
		@options.verbosity ?= 'ERROR'
		
		@log = new Log(@options.verbosity)
		
	hasExpired: ->
		@hasSpoiled() or (new Date()) > @bestBefore
		
	hasSpoiled: ->
		not @results? or (new Date()) > @spoilesOn
	
	fetch: (callback) ->
		
		# apply hook into stocked event
		@once 'stocked', callback
		
		# set headers for conditional GETs
		@options.headers ?= {}
		@options.headers['if-none-match'] = @eTag if @eTag
		@options.headers['if-modified-since'] = @lastModified if @lastModified

		request @options, (error, response, body) =>

			# cache-control header max-age value will by default overide configured shelfLife
			match = /max-age=(\d+)/.exec(response.headers['cache-control'])
			@options.shelfLife = parseInt(match[1]) if match and not @options.ignoreCacheControl
			
			unless error?
				switch response.statusCode
					when 304 # cached data is still good.  keep using it
						@log.info "cached data still good: #{@options.uri}"
						@stock(response, null)

					when 200 # new data available
						@log.info "new data available: #{@options.uri}"
						contentType = response.headers["content-type"]
						
						# parse JSON
						if @options.parser is 'json' or contentType.indexOf('application/json') is 0
							@stock(response, JSON.parse body)

						# parse XML
						else if @options.parser is 'xml' or contentType.search(/[\/\+]xml/) > 0
							# some xml is 'bad' but can be fixed, so let's try
							start = body.indexOf('<')
							body = body[start...body.length] if start
							
							# now we can parse
							parser = new xml2js.Parser(@options.xmlOptions)
							parser.on 'end', (results) =>
								@stock(response, results)
							parser.parseString body
						
						# that was unexpected
						else
							@oops("Invalid Response Type (#{contentType})")
							
					else
						# something wrong with the server or the request
						@oops("Invalid Response Code (#{response.statusCode})")
						
	stock: (response, results) ->

		if @firstPurchased?
			@lastPurchased = new Date()
		else
			@firstPurchased = new Date()
			@lastPurchased = new Date(@firstPurchased)
		
		@lastUsed = new Date(@lastPurchased)
			
		@bestBefore = new Date(@lastPurchased)
		@bestBefore.setSeconds @bestBefore.getSeconds() + @options.shelfLife

		@spoilesOn = new Date(@lastPurchased)
		@spoilesOn.setSeconds @spoilesOn.getSeconds() + @options.maxLife
		
		@eTag = response.headers['etag']
		@lastModified = response.headers['last-modified']
		
		@results = results if results?
		@emit 'stocked', null, @results
		
	oops: (error) ->
		@log.error "#{error}"
		@emit 'stocked', error
		
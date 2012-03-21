pantry = require '../src/pantry'
MemcachedStorage = require '../src/pantry-memcached'

delay = (ms, func) -> setTimeout func, ms

test = (id, sleep)->
	pantry.fetch "http://app.canada.com/southparc/query.svc/content/#{id}?format=json", (error, item) ->
		delay sleep, -> test id, sleep

pantry.configure { shelfLife: 10, maxLife: 30, caseSensitive: false, verbosity: 'DEBUG'}
pantry.storage = new MemcachedStorage 'localhost:11211', {}, 'DEBUG'

pantry.fetch "http://app.canada.com/southparc/query.svc/relatedcontent/764023?format=json", (error, list) ->
	max = if list.length > 30 then 30 else list.length
	for x in [0...max]
		do (x) ->
			sleep = (x + 1) * 500
			delay sleep, -> test list[x].ID, sleep

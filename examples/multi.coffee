pantry = require '../src/pantry'
MemoryStorage = require '../src/pantry-memory'

pantry.storage = new MemoryStorage({capacity: 18, ideal: 12, verbosity: 'DEBUG'})

delay = (ms, func) -> setTimeout func, ms

test = (id, sleep)->
	pantry.fetch "http://app.canada.com/southparc/query.svc/content/#{id}?format=json", (error, item) ->
		delay sleep, -> test id, sleep

pantry.configure { shelfLife: 2, maxLife: 3, caseSensitive: false, verbosity: 'DEBUG'}

pantry.fetch "http://app.canada.com/southparc/query.svc/relatedcontent/764023?format=json", (error, list) ->
	max = if list.length > 30 then 30 else list.length
	for x in [0...max]
		do (x) ->
			sleep = (x + 1) * 500
			delay sleep, -> test list[x].ID, sleep
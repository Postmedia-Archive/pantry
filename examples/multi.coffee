pantry = require '../src/pantry'
storage = require '../src/pantry-memory'

delay = (ms, func) -> setTimeout func, ms

test = (id, sleep)->
	pantry.fetch "http://app.canada.com/southparc/query.svc/content/#{id}?format=json", (error, item) ->
		console.log "#{id} - #{sleep}"
		delay sleep, -> test id, sleep

pantry.configure { shelfLife: 5, maxLife: 7, caseSensitive: false, verbosity: 'DEBUG', storage: storage.create({capacity: 20, ideal: 10}) }

pantry.fetch "http://app.canada.com/southparc/query.svc/relatedcontent/764023?format=json", (error, list) ->
	max = if list.length > 30 then 30 else list.length
	for x in [0...max]
		do (x) ->
			sleep = (x + 1) * 500
			delay sleep, -> test list[x].ID, sleep
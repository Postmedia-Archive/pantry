pantry = require '../src/pantry'

delay = (ms, func) -> setTimeout func, ms

test = (id, sleep)->
	pantry.fetch {
		uri: "http://app.canada.com/southparc/query.svc/content/#{id}?format=json"
	}, (error, item) ->
		delay sleep, -> test id, sleep

pantry.configure { shelfLife: 5, maxLife: 7, capacity: 20, ideal: 10}

delay 500, -> test 5095700, 500
delay 1000, -> test 5095701, 1000
delay 1500, -> test 5095702, 1500
delay 2000, -> test 5095703, 2000
delay 2500, -> test 5095704, 2500
delay 3000, -> test 5095705, 3000
delay 3500, -> test 5095706, 3500
delay 4000, -> test 5095707, 4000
delay 4500, -> test 5095708, 4500
delay 5000, -> test 5095709, 5000
delay 5500, -> test 5095710, 5500
delay 6000, -> test 5095711, 6000
delay 6500, -> test 5095712, 6500
delay 7000, -> test 5095713, 7000
delay 7500, -> test 5095714, 7500
delay 8000, -> test 5095715, 8000
delay 8500, -> test 5095716, 8500
delay 9000, -> test 5095717, 9000
delay 9500, -> test 5095718, 9500
delay 10000, -> test 5095719, 10000
delay 10500, -> test 5095720, 10500
delay 11000, -> test 5095721, 11000
delay 11500, -> test 5095722, 11500
delay 12000, -> test 5095723, 12000
delay 12500, -> test 5095724, 12500
pantry = require '../src/pantry'

# configure method returns all configuration options if you ask for it.
config = pantry.configure { shelfLife: 5, verbosity: 'INFO' }
console.log config


pantry.fetch { uri: 'http://app.canada.com/southparc/query.svc/content/5095700?format=xml'}, (error, results) ->
	if error?
		console.log error
	else	
		pantry.getStock (error, stock) ->
			console.log "\n\nCurrent stock count: #{stock.stockCount}"
			console.log "---------------------------\n"
			console.log stock # Displays current Stock
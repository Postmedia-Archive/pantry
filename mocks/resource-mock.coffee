mockCount = 0

module.exports = class MockResource
	constructor: (@state = 'fresh', @results) ->

		@options = {shelfLife: 60, maxLife: 120, key: "ID-#{mockCount++}"}
		
		@firstPurchased = new Date()
		@lastPurchased = new Date(@firstPurchased)
		@bestBefore = new Date(@firstPurchased)
		@spoilsOn = new Date(@firstPurchased)
		
		switch @state
			when 'expired'
				@bestBefore.setHours(@bestBefore.getHours() - 1)
				@spoilsOn.setHours(@spoilsOn.getHours() + 1)
			when 'spoiled'
				@bestBefore.setHours(@bestBefore.getHours() - 1)
				@spoilsOn.setHours(@spoilsOn.getHours() - 2)
			else
				@bestBefore.setHours(@bestBefore.getHours() + 1)
				@spoilsOn.setHours(@spoilsOn.getHours() + 2)

{ merge, typeOf } = require 'lutils'

###
	Creates a new coroutiner instance.
	
	@param newTypes {Object} An object which will merge with the coroutiner.types object
	@param Promise {Function Promise} Your own Promise implimentation
		@default require('bluebird')
###
module.exports = new Coroutiner = (options = {}) ->
	###
		Enumerates over an Object or Array, turning generator functions
		into Promise.coroutine()'s. Not recursive.

		@param obj {Object or Array or Function}
		@param validator {Function} (Optional)
			This function will be run for each property. When `false` is returned by validator, a property is skipped.
			
			@param key
			@param value
			@param parent
		
		@return obj
		
	###
	coroutiner = (obj, validator = coroutiner.validator, types = coroutiner.types) ->
		for key, val of obj
			continue if types.unowned is false and not obj.hasOwnProperty key

			if coroutiner.isGenerator val
				continue if ( validator? key, val, obj ) is false
				obj[ key ] = coroutiner.create val, types

		coroutiner.prototypeHandler obj, types, (proto) -> coroutiner proto, validator, types

		return obj
		
	coroutiner.prototypeHandler = (obj, types, iterator) ->
		if types.prototype
			type = typeOf obj
			if type is 'function' and obj.prototype
				iterator obj.prototype
			else if type is 'object' and Object.keys( obj.__proto__ ).length
				iterator obj.__proto__
	
	coroutiner.Promise		= options.Promise or require 'bluebird'
	coroutiner.transformer	= options.transformer or coroutiner.Promise.coroutine
	coroutiner.validator	= null
	coroutiner.depth		= options.depth or 20
	coroutiner.types		= { object: true, function: true, array: true, prototype: true, unowned: true, circular: false }
	
	merge.white coroutiner.types, options
	
	coroutiner.isGenerator	= (fn) -> typeOf.Function( fn ) and fn.constructor.name is 'GeneratorFunction'
	coroutiner.create		= (fn, types = coroutiner.types) ->
		newFn = coroutiner.transformer fn
		merge newFn, fn, 1, types
		
		return newFn

	###
		Enumerates over all properties and any iterable properties, such as Objects and Functions.
		
		@param obj {Object or Array or Function}
		@param depth {Number}
		@param validator {Function} (Optional)
			This function will be run for each property. When `false` is returned by validator, a property is skipped.
			
			@param key
			@param value
			@param parent
		
		@param types {Object}
			Determines which properties will be enumerated over in this structure:
				{ 'object': true }
			
			When an `object`, `function`, `array` etc. is `true`, it will be enumerated within `obj`.
	###
	coroutiner.all = (obj, validator = coroutiner.validator, depth = coroutiner.depth, types = coroutiner.types) ->
		cyclicStore = []
		
		iterator = (obj, validator, depth, types) ->
			if --depth > 0
				for key, val of obj
					continue if types.unowned is false and not obj.hasOwnProperty key
					
					type = typeOf val
					
					if type of types
						if types.circular is false
							continue if val in cyclicStore
							cyclicStore.unshift val
					
					if type is 'function' and coroutiner.isGenerator val
						continue if ( validator? key, val, obj ) is false
						
						if types.function
							iterator val, validator, depth, types

						obj[key] = coroutiner.create val, types
								
					else if type of types
						iterator val, validator, depth, types
						
				coroutiner.prototypeHandler obj, types, (proto) -> iterator proto, validator, depth, types
				
			return obj
		
		return iterator obj, validator, depth, types
	
	coroutiner.Coroutiner = Coroutiner

	return coroutiner

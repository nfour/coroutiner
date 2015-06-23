coroutiner	= require '../coroutiner'
Promise		= require 'bluebird'

{ clone } = require 'lutils'

getObj = ->
	obj = {}
	
	obj.array = [[111, [ -> yield new Promise (resolve) -> resolve 5 ]]]
	
	obj.yieldable	= -> yield new Promise (resolve) -> resolve 1
	obj.yieldable.a	= 1
	
	obj.Class = class Class
		yieldable	: -> yield new Promise (resolve) -> resolve 1
		a			: 1
		
	obj.obj2 = clone obj
	obj.obj2.obj3 = clone obj
		
	return obj

exports["coroutiner"] = (test) ->
	obj = coroutiner getObj()

	do Promise.coroutine ->
		test.equals 1, yield obj.yieldable()
		test.equals 1, obj.yieldable.a

		test.done()

exports["coroutiner.all"] = (test) ->
	do Promise.coroutine ->
		coroutiner = new coroutiner.Coroutiner { prototype: true }

		obj = coroutiner.all getObj()
		
		test.equals 1, yield obj.yieldable()
		test.equals 1, obj.yieldable.a
		
		instance = new obj.Class()
		
		test.ok instance.yieldable.constructor.name isnt 'GeneratorFunction'
		
		console.log instance.yieldable.constructor.name
		
		test.equals 1, yield instance.yieldable()
		test.equals 1, instance.a
		
		# Array nested generators
		test.equals 5, yield obj.array[0][1][0]()

		test.done()
		
exports["benchmark"] = (test) ->
	iterations	= 1000
	getSubjects	= -> ( getObj() for i in [0..iterations] )

	subjects	= getSubjects()
	start		= new Date()
	coroutiner obj for obj in subjects
	
	console.log "coroutiner		x#{iterations} took #{new Date() - start}ms"

	subjects	= getSubjects()
	start		= new Date()
	coroutiner.all obj for obj in subjects
	
	console.log "coroutiner.all		x#{iterations} took #{new Date() - start}ms"


	test.done()

# Coroutiner
A convenience transformer to turn every `GeneratorFunction` into a `Promise.coroutine`.

```js

coroutiner = require('coroutiner')

obj = {
	fn: function*() {
		yield Promise.delay(500)
		return new Promise(function(resolve) { resolve(1000) })
	}
	
	normalFn: function() { return 5 }
}

coroutiner( obj )

obj.fn().then(function(number) {
	number // returns 1000
})


Promise.coroutine(function*() {
	yield obj.fn() // returns 1000
}

obj.normalFn() // returns 5
```

### Why?

Instead of calling `Promise.coroutine` on every generator function, just call coroutiner on a parent object. This allows one to build an application utilizing `yield` much more conveniently when every generator is already promisified.

Just be careful what you run this over. When `prototype: true` (default) is enabled this will work on `class (){}.prototype`, `function(){}.prototype` and `{}.__proto__`, which includes instances of classes.

You can also do it recursively.

```js
// Create a new coroutiner, which also enumerates over a functions prototype
coroutiner = require('coroutiner')

fn = function*() {}
fn.prop = 1

obj = {
	fn: fn
	anArray: [
		{
			fn: function*(){} // coroutined, due to { array: true }
		}
	]
	klass: class Class {
		fn: function*() {} // coroutined, due to { prototype: true }
	}
}

// This is run on every matched GeneratorFunction
// Returning `false` will skip it from being transformed
validatorFunction = function(key, value, parent) {
	if ( key.match(/idontwantyou/) ) {
		return false // skipping
	}
}

coroutiner.all(obj, validatorFunction)

// Properties of GeneratorFunctions will be copied over
obj.fn.prop // returns 1
```

### Caveats and Warnings
Coroutiner will behave weirdly in this CoffeeScript example
```coffee
class Test
	fn: => 
		# A bound function!
		yield return
		
class NewTest extends Test
	newFn: -> yield return

test = new NewTest()

coroutiner { test, NewTest }

yield test.fn() # Error, because .fn() never got coroutined before being extended
yield test.newFn() # Works because it was defined in NewTest's prototype
yield new NewTest().fn() # Works because the instance was created with the coroutined prototype
```

### The transformer
Make sure `require('bluebird')` works if you aren't specifying your own transformer. Bluebird's `Promise.coroutine` is used as a transformer by default, but by creating your own coroutiner instance that can change.

#### coroutiner( obj, ?validatorFn?, ?types? )
Returned by `require('coroutiner')`.

Transforms `GeneratorFunctions` within the obj with the transformer. Will also enumerate over the `fn.prototype` if prototypes are enabled.

This is not recursive.

#### coroutiner.all( obj, ?validator?, ?depth?, ?types? )
Recursively transforms properties, like `coroutiner()`.
Be careful with this. Only run it over an object that exposes your generators. If this touches a library that expects generators then things will break.

#### coroutiner.Coroutiner( options )
Creates a new coroutiner instance.

`options {Object}`
- `validator {Function}` A default validator function
- `transformer {Function}` A default transformer instead of `Promise.coroutine`
- `array {Boolean} true` Whether to iterate over arrays items
- `object {Boolean} true` Whether to iterate over object properties
- `function {Boolean} true` Whether to iterate over function properties
- `prototype {Boolean} true` Whether to iterate over function/object prototypes

This controls which properties are enumerated over to look for transformable properties.

#### coroutiner.create( fn, ?types? )
Create a coroutined function and copies over its properties into a new returned function.
This is called by `coroutiner()` and `coroutiner.all()`

#### coroutiner.types
```
{
	object: true, function: true, array: true
	prototype: true, unowned: true, circular: false
}
```

`unowned` as `false` if you only want `.hasOwnProperty` properties
`circular` as `true` will remove cyclic recursion protection

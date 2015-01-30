Module Definition

	module = angular.module "angular-clazz", []

Provider Definition

	module.provider("Clazz", () ->

		OO = {}

Credit for the base class goes to Elad Ossadon as seen on [devign.me](http://www.devign.me/angular-dot-js-coffeescript-controller-base-class)

		class OO.Injectable
			@inject: (args...) ->
				(args.push(injectee) if args.indexOf(injectee) is -1) for injectee in [(@$inject ? [])...]
				@$inject = args
				@

A Base Class for all Controllers

		class OO.Ctrl extends OO.Injectable

We need to focus, almost always, so let's default at least the scope in all our controllers

			@inject "$scope"

Providing a registering mechanism

			@register: (app, name) ->
				name ?= @name or @toString().match(/function\s*(.*?)\(/)?[1]
				if typeof app is "string" then angular.module(app).controller name, @
				else app.controller name, @
				@

Thx for the basic mixin pattern: [the Coffeescript-Cookbook](http://coffeescriptcookbook.com/chapters/classes_and_objects/mixins)

			@mixin: (mixins...) ->
				class Mixed extends @
				for mixin in mixins
					for name, method of mixin.prototype
						(() ->
							m = method
							_m = Mixed::[name]
							n = name
							if name is "initialize" and Mixed::initialize?
								Mixed::initialize = () ->
									m.call @
									_m.call @
							else if name isnt "constructor" and not Mixed::[name]? then Mixed::[name] = m
						)()
					(Mixed[name] = method) for own name, method of mixin when angular.isFunction method
					Mixed.inject.apply Mixed, mixin.$inject
				Mixed

Pattern to enforce certain precisely named functionality in to be created/derived Child-Controllers

			@implements: (interfaces...) ->
				class Interfaced extends @
				for Interface in interfaces
					do (Interface) ->
						Interfaced::[Interface] = () -> throw {
							msg: "Looks like the interface _#{Interface}_ hasn't been implemented! This will lead to unpredictable behaviour!"
						}
				Interfaced

Runtime Initiation

			constructor: (args...) ->

Bring public methods into the $scope and attach all DI-injected services to `this`

				(@[key] = args[index]) for key, index in @constructor.$inject
				for key, fn of @constructor.prototype when typeof fn is "function" and ["constructor", "initialize"].indexOf(key) is -1 and key[0] isnt "_"

					do (key, fn) =>

Behavioural Initialization --- basically registering Event Listeners

						if key.match "::"
							t = key.split "::"
							if t[2]? and t[2].indexOf(">") isnt -1 then t = t.splice(0, 2).concat t[0].split ">"
							for el, i in (t[0] and $(t[0], @element?.context ? document.body) or [@$element?.context])
								do (el, i) =>
									listenerO = [t[1]]
									listenerO.push(t[2]) if t[2]?
									listenerO.push (args...) =>

We are aiming to provide a variable @$scope.n, which is the pendant of a ng-repeated element's index()-foo as usually passed from the template

										if t[2]?
											ev = args[0]
											if t[3]? then @$scope.n = $(ev.currentTarget).closest(t[3]).index()
											else (@$scope.n = j) for el, j in $(ev.currentTarget).parent().children().get() when el is ev.currentTarget
										fn.apply @, args

Recalculate scoped vars so two-way-databinding is instantly functional

										if not @$scope.$$phase then @$scope.$digest()

									angular.element(el).on.apply angular.element(el), listenerO
						else
							@$scope[key] = (args...) =>
								fn.apply @, args
								@

Quasi-Constructor = Initialization of child classes as it is advised to not write custom constructors for child classes

				@initialize?()

		class OO.DynamicComponent extends OO.Ctrl
			@inject "$element"

			initialize: () ->
				@$scope.data = {}

The state var is a CSS-state-descriptor/helper
Add your own variables, they'll be reflected in the container-element as CSS-classes on val "true"

				@$scope.state = {
					loading: true
					selected: null
					busy: null
					error: null
				}

Aspect Oriented Feature here.
You can actually initialize a db-store (api-result-set) with a value or set values each api-cycle
Syntax is: Set a var ```@transform = {
	descriptor: name #of DataService without the DataService-suffix in small letters
	init: [
		# i is the id ... 0 - length-1 ... or -1 for all datasets
		{ i: 0, prop: "loading", val: false }
		{ i: -1, prop: "selected", val: (db, id) -> id is 0 }
	]
	digest: [
		{ i: -1, prop: "selected", val: (db, id) -> (db.store.find (el, i, arr) => el.id is id).special is @$scope.someConditional }
	]
}```

				for dataset, i in (@transform ? [])
					do (dataset, i) =>
						Service = @[dataset.descriptor.capitalize() + "DataService"]
						Service.aspect((() => Service.set(p)), true) for p in (dataset.init ? [])
						Service.aspect () => Service.set(p) for p in (data.digest ? [])

Each injected DataService is automatically subscribed to
This means, that each api-cycle of each service will trigger a ```_transform```-function on each subscriber.
So a Component can differentiate the different calls to it's _transform-function, two params are passed in:
```(ServiceDescriptor, db) ->```
ServiceDescriptor being the name of the DataService in small letters without the "DataService"-suffix
db being the actual pointer to the in-memory api-result-sets.

				for key, Service of @ when /DataService/.test key
					do (key, Service) =>
						descriptor = key.remove("DataService").toLowerCase()
						Service.subscribe @_transform.bind(@, descriptor)
						if Service.db?.ready is true then Service.digest()

				@$element.addClass key for own k, v of @$scope.state when v is true
				for own k, v of @$scope.state
					do (k, v) =>
						@$scope.$watch "state.#{k}", (n, o) =>
							if n is true and not @$element.hasClass k then @$element.addClass k
							else if @$element.hasClass k then @$element.removeClass k
							if o is n or (not o? and not n) then return
							@$scope.$emit "state.#{k}", {
								obj: @toString().match(/function\s*(.*?)\(/)?[1]
								val: n
							}

The default transform function
* initializes the pointer of the actual Service-DB,
* updates the current dataset of the service
* returns a Boolean as to if the Services DB is empty
Because of this, in your overriding special _transform foo you should always
* call super first
* return and do nothing if super returns false

			_transform: (descriptor, db) ->
				@$scope.data[descriptor] ?= @[descriptor.substring(0, 1).toUpperCase() + descriptor.substring(1) + "DataService"].db.store
				@$scope.data.current ?= {}
				@$scope.data.current[descriptor] = db.current ? null
				if not @$scope.data[descriptor]?.length
					console.warn "The dataset of #{descriptor} was empty"
					false
				else true

			_digest: () ->
				try
					@$scope.$digest()
				catch e
					"hogus bogus"

		class OO.Service extends OO.Injectable

			@register: (app, name) ->
				name ?= @name or @toString().match(/function\s*(.*?)\(/)?[1]
				if typeof app is "string" then angular.module(app).service name, @
				else app.service name, @
				@
			constructor: (args...) ->
				(@[key] = args[index]) for key, index in @constructor.$inject
				@initialize?()

DB Functionality, utilizing Pouch DB with a localStorage Adapter, encapsulating flow into two Controller Types:
* View Controllers and Deriveds
* Widget Controllers and Deriveds
View Controllers are Main Page Controllers of an Angular Route, they hold all DBs and therefor dynamic Data of the Page
Widget Controllers listen to that db-collections and transform and store that adapted data into their own local dbs

		class OO.DataService extends OO.Service
			@inject "$resource", "$interval", "$q", "$timeout"

Create the DB

			_db: (api, { @name, @oneshot, @interval}) ->
				@oneshot = @oneshot is true or not @interval?
				if @db?.busy is true then @$timeout () =>
					if @oneshot is true then @q.reject()
					else @q.notify false
				, 0
				@q = @$q.defer()
				@db =
					busy: false
					ready: false
					handle: if api? then @$resource(api) else null
					store: []

				if @oneshot is false then @q.promise.then [
					() => true
					(notification) => @$timeout @_api, @interval
					() => false
				]...
				@_api()
				@q.promise

AJAX Mechanism

			_api: () ->
				if @db.busy is true then return
				@db.busy = true
				@db.handle.get().$promise
					.then (data) =>
						console.info "#{(new Date()).toLocaleTimeString('en-US')} :: API/#{@name}: Success"
						@_store(data[@name] ? data)
						@db.busy = false
						if @oneshot isnt false
							@q?.resolve()
							@q = null
							@q = @$q.defer()
						else @q.notify(true)
						@db.ready = true
					.catch (err) =>
						console.warn "#{(new Date()).toLocaleTimeString('en-US')} :: API/#{@name}: Error :: #{err.toString()}"
						if @oneshot isnt false
							@q?.reject()
							@q = null
							@q = @$q.defer()
						else
							@q.notify(false)

Storage Mechanism

			_store: (data) ->

Usually the API returns an Array of 0-n datasets
Should your API return non-arrays in certain cases, these probably singular objects are "arrayified"

				_data = if Object.prototype.toString.call(data) is "[object Array]" then data else [data]

Set all exisiting datasets to "stale" = eligible=false ...
Please use this in your filters.
Outdated/old/deleted datasets are kept in memory, but marked as eligible=false

				(o.eligible = false) for o in @db.store

Then, step by step, as to
* mark the current sets as what they are -> eligible=true
* not loose angulars hash-vals or whatever special data you might have set on (some) dataset(s)

				for o in _data
					do (o) =>
						if @db.store.filter((el, i, arr) -> el.id is o.id).length
							(@db.store[i][k] = o[k]) for own k, v of o
							@db.store[i].eligible = true
						else
							@db.store.push o
							@db.store[@db.store.length - 1].eligible = true

		class OO.DynamicDataService extends OO.DataService

			subscribe: (callback, oneshot = false) ->
				@subscribers ?= []
				@once_subscribers ?= []
				if oneshot is true then @once_subscribers.push callback
				else @subscribers.push callback
			aspects: (injection, oneshot = false) ->
				@aspects ?= []
				@once_aspects ?= []
				@once_aspects.compact()
				if oneshot is true then @once_aspects.push injection
				else @aspects.push injection
			get: (matcher) ->
				@db.store.filter (el, i, arr) ->
					return false for own k, v of matcher when not (v?(el[k]) ? (el[k] is v))
					true
			set: (opts) ->
				if opts.i is -1 then (doc[opts.prop] = opts.val?(@db, doc.id) ? opts.val) for doc, i in @db.store
				else @db.store[opts.i?(@db) ? opts.i]?[opts.prop] = (opts.val?(@db, @db.store[opts.i?(@db) ? opts.i].id) ? opts.val)
			digest: () ->
				if @db.ready is false then return

				@db.resolved ?= false

				for once_aspect, i in (@once_aspects ? [])
					once_aspect?(@db)
					@once_aspects[i] = null
				@once_aspects = []

				for d, i in @db.store
					if d.eligible is false then d.selected = false
					else if d.selected is true then @db.current = d
					else if not d.selected? then d.selected = false

				@db.resolved = true
				aspect(@db) for aspect in (@aspects ? [])

				for callback, i in (@once_subscribers ? [])
					callback?(@db)
					@once_subscribers[i] = null
				@once_subscribers = []
				callback(@db) for callback in (@subscribers ? [])
				true

		class AbstractOneshotDataService extends OO.DynamicDataService
			initialize: (path, descriptor) ->
				@promise = @_db path, { name: descriptor, oneshot: true }
				super

		@$get = () -> OO

		return
	)

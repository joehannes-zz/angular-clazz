Dependency on Selector Engine -- Choose Sizzle or jQuery

	window.Sizzle ?= window.$ ? null

Module Definition

	module = angular.module "angular-clazz", []

Provider Definition

	module.provider("Clazz", () ->

		try
			_DB = angular.injector(['pouchdb'])?.get? 'pouchdb'
		catch err
			console.info "Angular-PouchDB not available - you can't use local persistance, but volatile version is available"
		OO = {}

Credit for the base class goes to Elad Ossadon as seen on [devign.me](http://www.devign.me/angular-dot-js-coffeescript-controller-base-class)

		class OO.Injectable
			@inject: (args...) ->
				(args.push(injectee) if args.indexOf(injectee) is -1) for injectee in [(@$inject ? [])..., "$scope"]
				@$inject = args
				@

A Base Class for all Controllers

		class OO.Ctrl extends OO.Injectable

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
							console.log key
							t = key.split "::"
							for el, i in (t[0] and Sizzle(t[0], @element?.context ? document.body) or [@$element?.context])
								do (el, i) =>
									listenerO = [t[1]]
									listenerO.push(t[2]) if t[2]?
									listenerO.push (args...) =>
										console.log key
										if t[2]?
											ev = args[0]
											(i = j) for el, j in $(ev.currentTarget).parent().children().get() when el is ev.currentTarget
										@$scope.n = i #provide a counter var for lists and similar (ng-)repeated els
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
			@inject "$resource", "$interval", "$q"

Create the DB

			_db: (api, { @name, @persistant, @oneshot, @interval}) ->
				@persistant ?= false
				@oneshot = not @interval?
				@q ?= @$q.defer()
				@db =
					busy: false
					ready: false
					handle: if api? then @$resource api else null
					store: @persistant and _DB.create(@name) or []
			
				@_api()
				@oneshot or @$interval @_api.bind(@), @interval
				@q.promise

AJAX Mechanism

			_api: () ->
				if @db.busy is true then return
				@db.busy = true
				@db.handle.get().$promise
					.then (data) =>
						@_store(data[@name] ? data)
						@db.busy = false
						if not @persistant
							if @oneshot is true 
								@q.resolve()
								@q = null
							else @q.notify(true)
					.catch (err) =>
						if @oneshot is true 
							@q.reject()
							@q = null
						else 
							@q.notify(false)


Storage Mechanism

			_store: (data) ->
				if not @volatile
					for o in data
						do (o) =>
							@db.store.query((doc, emit) -> if doc.id is o.id then emit doc)
								.then (doc) =>
									console.info '#Data for id _#{o.id}_ will be updated now'
									if doc.error isnt "not_found" and doc.total_rows is 1
										o._id = doc.rows[0].key._id
										o._rev = doc.rows[0].key._rev
								.catch (err) =>
									console.warn "db error: couldn't query for #{o.id}"
									throw err.toString()
								.finally (args...) =>
									@db.store.put(o, o.id, o._rev)
										.then (response) =>
											if @oneshot is true 
												@q.resolve()
												@q = null
											else @q.notify(true)
										.catch (err) =>
											console.warn "db error: couldn't put #{o.toString()}"
											if @oneshot is true 
												@q.reject()
												@q = null
											else 
												@q.notify(false)
				else
					(o.deleted = true) for o in @db.store
					for o in data
						do (o) =>
							if (i = @db.store.findIndex((el) -> el.id is o.id)) isnt -1
								(@db.store[i][k] = o[k]) for own k, v of o
								@db.store[i].deleted = false
							else 
								@db.store.push o
								@db.store[@db.store.length - 1].deleted = false
				@db.ready = true

		class OO.Widget extends OO.Ctrl
			@inject "$element"

		@$get = () -> OO

		return
	)

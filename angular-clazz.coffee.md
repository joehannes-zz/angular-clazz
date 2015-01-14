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

			_db: (api, { @name, @persistant, @oneshot, @interval}) ->
				@persistant ?= false
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
					store: @persistant and _DB.create(@name) or []

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
						if not @persistant
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
				_data = if Object.prototype.toString.call(data) is "[object Array]" then data else [data]
				if @persistant
					for o in _data
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
					for o in _data
						do (o) =>
							if (i = @db.store.indexOf(@db.store.filter (el) -> el.id is o.id)) isnt -1
								(@db.store[i][k] = o[k]) for own k, v of o
								@db.store[i].deleted = false
							else
								@db.store.push o
								@db.store[@db.store.length - 1].deleted = false

		class OO.Widget extends OO.Ctrl
			@inject "$element"

		@$get = () -> OO

		return
	)

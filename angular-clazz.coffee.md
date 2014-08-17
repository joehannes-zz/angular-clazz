Module Definition

	module = angular.module "angular-clazz", ['pouchdb']

Provider Definition

	module.provider("Clazz", () ->

		_DB = angular.injector(['pouchdb']).get 'pouchdb'
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

DB Functionality, utilizing Pouch DB with a localStorage Adapter, encapsulating flow into two Controller Types:
* View Controllers and Deriveds
* Widget Controllers and Deriveds
View Controllers are Main Page Controllers of an Angular Route, they hold all DBs and therefor dynamic Data of the Page
Widget Controllers listen to that db-collections and transform and store that adapted data into their own local dbs

		class OO.DB extends OO.Injectable
			@inject "$resource", "$interval"

Create the DB and initiate on Controller-Type

			_createDB: (api, name, @volatile = false) ->
				@$scope.db ?= {}
				@api ?= {}
				@$scope.db[name] =
					busy: false
					handle: if api? then @$resource api else null
					raw: []
					store: @volatile and [] or _DB.create name

				if @ instanceof OO.View then @$interval (() => @_api(name)), 7000
				else if @ instanceof OO.Widget
					@_listen name
					@$scope.db[name].store.info()
						.then (info) =>
							if parseInt(info.doc_count) is 0 then @_api(name)
							else @_broadcast name, { db: @$scope.db[name].store, doc: [], count: parseInt(info.doc_count) }
						.catch (err) ->
							console.log "error in db #{name} while trying to see if it existed already ..."
							throw err.toString()

AJAX Mechanism

			_api: (name) ->
				if @$scope.db[name].busy is true then return
				@$scope.db[name].busy = true
				@$scope.db[name].handle.get().$promise.then (data) =>
					@_store name, data
					@$scope.db[name].busy = false

Storage Mechanism

			_store: (name, data) ->
				if not @volatile
					for o in data.contents
						do (o) =>
							@$scope.db[name].store.query((doc, emit) -> if doc.id is o.id then emit doc)
								.then (doc) =>
									console.info '#Data for id _#{o.id}_ will be updated now'
									if doc.error isnt "not_found" and doc.total_rows is 1
										o._id = doc.rows[0].key._id
										o._rev = doc.rows[0].key._rev
								.catch (err) =>
									console.warn "db error: couldn't query for #{o.id}"
									throw err.toString()
								.finally (args...) =>
									@$scope.db[name].store.put(o, o.id, o._rev)
										.then (response) => @_broadcast name, { db: @$scope.db[name].store, doc: [o], count: 1 }
										.catch (err) =>
											console.warn "db error: couldn't put #{o.toString()}"
											throw err.toString()
				else
					(o.deleted = true) for o in @$scope.db[name].store
					for o in data.contents
						do (o) =>
							if (i = @$scope.db[name].store.findIndex((el) -> el.id is o.id)) isnt -1
								(@$scope.db[name].store[i][k] = o[k]) for own k, v of o
								@$scope.db[name].store[i].deleted = false
							else 
								@$scope.db[name].store.push o
								@$scope.db[name].store[@$scope.db[name].store.length - 1].deleted = false
					@_broadcast name, { db: @$scope.db[name].store, doc: data.contents, count: data.contents.length }

Broadcast mechanism - View Ctrls only

			_broadcast: (name, data) -> @$scope.$broadcast "db.changed.#{name}", data

Listen mechanism - Widget Ctrls only

			_listen: (name) ->
				@$scope.$on "db.changed.#{name}", (ev, args...) =>
					args.unshift name
					@_transform.apply @, args

		class OO.View extends OO.Ctrl
			@inject()

		class OO.DynamicView extends OO.View
		.mixin OO.DB

		class OO.Widget extends OO.Ctrl
			@inject "$element"

		class OO.DynamicWidget extends OO.Ctrl
		.mixin OO.DB
		.implements "_transform"

		@$get = () -> OO

		return
	)

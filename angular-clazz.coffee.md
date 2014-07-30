Module Definition

	module = angular.module "angular-clazz", ['pouchdb']

Provider Definition

	module.provider("Clazz", (pouchdb) ->

		DB = pouchdb
		OO = {}

Credit for the base class goes to Elad Ossadon as seen on [devign.me](http://www.devign.me/angular-dot-js-coffeescript-controller-base-class)

		class OO.Injectable
			@inject: (args...) ->
				(args.push injectee if args.indexOf injectee is -1) for injectee in (@$inject?.push?(["$scope", "$element", "$attrs"]) or ["$scope", "$element", "$attrs"])
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
					for name, method of mixin:: by -1
						(() ->
							m = method
							_m = Mixed::[name]
							n = name
							if name is "initialize" and Mixed::initialize?
								Mixed::initialize = () ->
									m.call @
									_m.call @
							else Mixed::[name] = m
						)()
					(Mixed[name] = method) for own name, method of mixin when angular.isFunction method
				Mixed

Pattern to enforce certain precisely named functionality in to be created/derived Child-Controllers

			@implements: (interfaces...) ->
				class Interfaced extends @
				for interface in interfaces
					do (interface) ->
						Interfaced::[interface] = () -> throw {
							msg: "Looks like the interface _#{interface}_ hasn't been implemented! This will lead to unpredictable behaviour!"
						}
				Interfaced

Runtime Initiation

			constructor: (args...) ->

Bring public methods into the $scope and attach all DI-injected services to `this`

				(@[key] = args[index]) for key, index in @constructor.$inject
				for key, fn of @constructor.prototype when typeof fn is "function" and ["constructor", "initialize"].indexOf key is -1 and key[0] isnt "_"
					@$scope[key] = (args...) =>
						fn.apply @, args
						@

Behavioural Initialization --- basically registering Event Listeners

				for trigger, behaviour of @ when trigger.match "::"
					do (trigger, behaviour) =>
						t = trigger.split "::"
						for el, i in Sizzle(t[0], @$element[0])
							do (el, i) =>
								angular.element(el).on t[1], (args...) =>
									@$scope.n = i #provide a counter var for lists and similar (ng-)repeated els
									behaviour.apply @, args

Recalculate scoped vars so two-way-databinding is instantly functional

									@$scope.$apply()

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

			_createDB: (api, name) ->
				@$scope.db ?= {}
				@api ?= {}
				@$scope.db[name] =
					busy: false
					handle: @$resource api
					raw: []
					store: DB.create @name

				if @ instanceof OO.View then @$interval () => @_api(name), 15000
				else if @ instanceof OO.Widget then @_listen name

AJAX Mechanism

			_api: (name) ->
				if @$scope.db[name].busy is true then return
				@$scope.db[name].busy = true
				@$scope.db[name].handle.get().$promise.then (data) =>
					@_store name, data
					@$scope.db[name].busy = false

Storage Mechanism

			_store: (name, data) ->
				console.log "Schreibe das jetzt in die Datenbank"
				console.log data
				#change that so gets updated, not entirely overwritten
				for o in data
					@$scope.db[name].store.put(o)
						.then (response) => @$scope.db[name].raw.push { data: data, id: response.id, rev: response.rev }
						.catch (err) => console.log "db error: couldn't put #{o}"
				if @ instanceof OO.View then @_broadcast name

Broadcast mechanism - View Ctrls only

			_broadcast: (name) -> @$scope.$broadcast "db.changed.#{name}", @$scope.db[name].store

Listen mechanism - Widget Ctrls only

			_listen: (name) -> @$scope.$on "db.changed.#{name}", (ev, args...) => @_transform.apply @, args

		class OO.View extends OO.Ctrl
			@inject()

		class OO.DynamicView extends OO.View
		.mixin OO.DB

		class OO.Widget extends OO.Ctrl
			@inject()

		class OO.DynamicWidget extends OO.Ctrl
		.mixin OO.DB
		.implements "_transform"

		@$get = () -> OO

	)

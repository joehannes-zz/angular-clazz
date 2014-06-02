Module Definition

	module = angular.module "angular-clazz", []

Provider Definition

	module.provider("Clazz", () ->

		@$get = () ->

			OO = {}

Credit for the base class goes to Elad Ossadon as seen on [devign.me](http://www.devign.me/angular-dot-js-coffeescript-controller-base-class)

			class OO.Ctrl
				@register: (app, name) ->
					name ?= @name || @toString().match(/function\s*(.*?)\(/)?[1]
					if typeof app is "string" then angular.module(app).controller name, @
					else app.controller name, @
					@

				@inject: (args...) -> 
					(args.push injectee if args.indexOf injectee is -1) for injectee in ["$scope", "$element", "$attrs"]
					@$inject = args
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
								else Mixed::[name] = method
							)()
						(Mixed[name] = method) for own name, method of mixin when angular.isFunction method
					Mixed

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

Quasi-Constructor = Initialization of child classes as it is advised to not write custom constructors for child classes

					@initialize?()

			OO
		null
	)
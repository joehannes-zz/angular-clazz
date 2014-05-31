Module Definition

	clazzy = angular.module "angular-clazzy", []

Provider Definition

	clazzy.provider "Clazz", () ->
		@$get = ($scope) ->

Credit for the base class goes to Elad Ossadon as seen on [devign.me](http://www.devign.me/angular-dot-js-coffeescript-controller-base-class)

			class OO
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
						constructor: () -> super
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

				@behaviours: (map) ->
					if not @::behaviours? then @::_behaviours = () -> map
					else
						behaviours = @::_behaviours.call window
						(behaviours[k] = v) for own k, v of map
						@::_behaviours = () -> behaviours

				constructor: (args...) ->
					(@[key] = args[index]) for key, index in @constructor.$inject
					for key, fn of @constructor.prototype when typeof fn is "function" and ["constructor", "initialize"].indexOf key is -1 and key[0] isnt "_"
						@$scope[key] = (args...) => 
							fn.apply @, args
							@
					@initialize()

				initialize: () ->
					for own trigger, behaviour of @_behaviours()
						t = trigger.split "::"
						for el in Sizzle(t[0], $element)
							angular.element(el).on t[1], () =>
								for own foo, params of behaviour
									break if foo.apply(@, (if angular.isString param then @scope[param] else param) for param in params) is false					

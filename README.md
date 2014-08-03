**Welcome, Geek!**

This package enables for use in Angular in combination with Coffeescript:

* Multiple prototype-based (functional rather than via scope) Inheritance via a Mixin mechanism
	* Preserves and facilitates Angulars Dependency Injection
	* Provides private methods mechanism (via underscore-prefix) for not exposing protected/private functionality to scope
* Behaviour Oriented Programming - bringing the control of UX back to the controller (as opposed to attributal event-diretives in the template)
	* Easy CSS Selector Mechanism via Sizzle, the selector engine jQuery uses
	* Plain Old (cross browser) jQuery-Events -> Naming conventions
	* Super easy to build a custom behaviour-library as private methods to be called/chained to the evented methods

**Dependencies**

* Sizzle or full-blown jQuery
* angular-pouchdb (either the author WSpringer accpeted my pull-request, or `git clone git@github.com:joehannes/angular-pouchdb.git`)

**Example Usage**


Module Definition
```
	app = angular.module('myModule', ['angular-clazz'])

	app.config ($routeProvider, ClazzProvider) ->
		Clazz = ClazzProvider.$get()


		class Main extends Clazz.DynamicView
			@inject "$routeParams"
			@register app
```
Create the DBs and connect them to the API
```
			initialize: () ->
				promise = @_createDB "/api/somepath/", "someDbName"
				promise.then(
					() ->
						#do something on promise resolved
					,
					(err) -> throw {
						msg: "Database update on /api/somepath failed"
						e: err
					}
					,
					(name) =>
						#if you poll in an interval you can as well never resolve the promise and do ...
						#fetch all exact session data and add to db
				)
```
Auto Event Handling and relocation for Logout
```
			".logout.button::click": () ->
					@_clearMyToken()
					window.location = "/"
```
The Actual Routing ...
```

		$routeProvider
			.when '/console/:layout',
				templateUrl: 'views/main.html'
				controller: Main
			.otherwise
				redirectTo: '/console/default'
```
An Example Widget
```
	app.directive('dummy', (Clazz) ->
		class Dummy extends Clazz.DynamicWidget
			@register app
			initialize: () -> @_listen "someDbName"
			_transform: (name, args...) ->
				@$scope.data ?= {}
				doc = args[0]
				if name is "someDbName"
					@$scope.data.someDbData ?= []
					if not doc.count? or doc.count is 0 then return
					@$scope.data.someDbData.push {
						id: doc.id
						flower: doc.power
						stars: doc.dream
						superhero: doc.myOwnPersonalJesus
					}
				else if name is "someOtherDbName"
					#and so on, should you have different datasources for this single widget, this should be useful
			".links::click": () ->
				@_count @$scope.n #if .links is a class attached to eg. a list, @$scope.n will reflect the $index of the clicked el
				@_alert @$scope.greeter.first, @$scope.greeter.last
			"::mouseleave": () -> alert "Goodbye, Mouseleave!"
			_count: (c) -> alert "element nr #{c}"
			_alert: (f, l) -> alert "Welcome, #{f}, also, #{l}!"

		controller: Dummy
		templateUrl: "views/dummy.html"
		replace: false
		restrict: "A"
	)
```

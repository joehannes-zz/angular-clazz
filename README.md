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

* Sizzle (if you `bower install angular-clazz` Sizzle should be pulled automatically, but don't forget to include it in your index.html)

**Example Usage**

```
	mod = angular.module('myModule', ['angular-clazz'])

	mod.directive('dummy', (Clazz) ->
		class Dummy extends Clazz.Ctrl
			@inject()
			@register mod
			initialize: () -> #do important preparations
			".links::click": () -> 
				@_count @$scope.n
				@_alert @$scope.greeter.first, @$scope.greeter.last
			"::mouseleave": () -> alert "Goodbye, Mouseleave!"
			_count: (c) -> alert "element nr #{c}"
			_alert: (f, l) -> alert "Welcome, #{f}, also, #{l}!"

		controller: Dummy
		templateUrl: "views/dummy.html"
		replace: false
		restrict: "EA"
	)
```

**Restrictions**

Multiple Inheritance is provided via the static `mixin` method. 
If you want to give it a shot just write something like

```
		class Dummy extends Clazz.Ctrl
		.mixin MyCollection.Base, MyCollection.Behaviours.StandardBehvaiours
			@inject()
			@register mod
			initialize: () -> #do important preparations

```
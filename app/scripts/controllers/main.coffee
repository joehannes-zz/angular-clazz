mod = angular.module('App')

Clazz = angular.injector(['angular-clazz'])?.get? 'Clazz'

class Hero extends Clazz.Widget

	@register mod, "Hero"

	initialize: () ->
		@$scope.css = {
			hero: ""
		}
		@$element.css "background-color", net.brehaut.Color "hsl(#{Math.round(Math.random * 360)}, 75%, 50%)"



class Navbar extends Clazz.Widget

	@register mod, "Navbar"

	initialize: () -> 
		@$scope.menuItems = {
			"Home": "home.html"
			"Example Usage": "example.html"
			"Docs": "docs.html"
			"About": "about.html"
		}

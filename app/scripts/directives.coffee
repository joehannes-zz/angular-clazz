mod = angular.module "App"

mod.directive 'herounit', () ->
	controller: "Hero"
	templateUrl: "views/hero.html"
	replace: true
	scope: {}
	transclude: true
	restrict: "E"

mod.directive 'navbar', () ->
	controller: "navbar"
	templateUrl: "views/navbar.html"
	replace: true
	scope: {}
	restrict: "E"
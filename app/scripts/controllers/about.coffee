'use strict'

###*
 # @ngdoc function
 # @name angularClazzApp.controller:AboutCtrl
 # @description
 # # AboutCtrl
 # Controller of the angularClazzApp
###
angular.module('angularClazzApp')
  .controller 'AboutCtrl', ($scope) ->
    $scope.awesomeThings = [
      'HTML5 Boilerplate'
      'AngularJS'
      'Karma'
    ]

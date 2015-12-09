AcpcPokerGuiClient.MatchStartConfigRoute = Ember.Route.extend({
  model: ()=>
    this.store.find(Routes.match_start_constants_path())
})

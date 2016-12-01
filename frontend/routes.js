const Routes = {
  match_home_path: function () {
    return '/match_start/sign_in';
  },
  root_path: function () {
    return '/';
  },
  leave_match_path: function () {
    return '/player_actions/leave_match';
  },
  update_match_queue_path: function () {
    return '/match_start/update_match_queue';
  },
  check_for_match_started_path: function () {
    return '/player_actions/check_for_match_started';
  },
  play_action_path: function () {
    return '/player_actions/play_action';
  }
};
export default Routes;

require('expose?$!expose?jQuery!jquery');
require('jquery-ujs');

require('jquery-ui/ui/core');
require('jquery-ui/ui/widget');
require('jquery-ui/ui/effect');
require('jquery-ui/themes/base/core.css');
require('jquery-ui/themes/base/theme.css');

require("./stylesheets/application.sass");
require('bootstrap-sass/assets/javascripts/bootstrap.min.js');

require("./jquery-titlealert/jquery.titlealert.js");
require("./jquery.hotkeys/jquery.hotkeys.js");

import Routes from './routes.js';
window.Routes = Routes;

// TODO Shared
window.wagerAmountField = () => $('.wager_amount-num_field > input#modifier');
window.wagerSubmission = () => $('.wager');

import ActionDashboard from './project_specific/action_dashboard.js';
window.ActionDashboard = ActionDashboard;

import AjaxCommunicator from './project_specific/ajax_communicator.js';
window.AjaxCommunicator = AjaxCommunicator;

import BotSelection from './project_specific/bot_selection.js';
window.BotSelection = BotSelection;

import ChipStackMutator from './project_specific/chip_stack_mutator.js';
window.ChipStackMutator = ChipStackMutator;

import CounterQueue from './project_specific/counter_queue.js';
window.CounterQueue = CounterQueue;

import DynamicSelector from './project_specific/dynamic_selector.js';
window.DynamicSelector = DynamicSelector;

import GameInterface from './project_specific/game_interface.js';
window.GameInterface = GameInterface;

import Hotkey from './project_specific/hotkey.js';
window.Hotkey = Hotkey;

import {
  WindowManager,
  ConsoleLogManager
} from './project_specific/realtime.js';
window.WindowManager = WindowManager;
window.ConsoleLogManager = ConsoleLogManager;

import {
  Timer,
  ActionTimer
} from './project_specific/timer.js';
window.Timer = Timer;
window.ActionTimer = ActionTimer;

import WagerAmountSlider from './project_specific/wager_amount_slider.js';
window.WagerAmountSlider = WagerAmountSlider;

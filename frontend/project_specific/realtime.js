// TODO this is a bit of a hack
const CONFIG = {
  "ON_TIMEOUT": "leave"
};

class ConsoleLogManager {
  static initClass() {
    this.CONSOLE_LOG = console.log;
    this.consoleIsEnabled = false;
  }
  static enableLogger() {
    return console.log = this.CONSOLE_LOG;
  }
  static disableLogger() {
    return console.log = function () {};
  }
}
ConsoleLogManager.initClass();

class Poller {
  constructor(pollFn, period) {
    this.pollFn = pollFn;
    this.period = period;
    this._timer = new Timer;
  }
  stop() {
    return this._timer.clear();
  }
  start() {
    return this._timer.start(this.pollFn, this.period);
  }
};

class PollingSubWindow {
  constructor(poller) {
    this.poller = poller;
  }
  poll() {
    return WindowManager.onLoadCallbacks.push(() => this.poller.start());
  }
  stop() {
    return this.poller.stop();
  }
  close() {
    this.stop();
    return null;
  }
  matchData() {
    return null;
  }
  showMatchEntryPage(alertMessage = null) {
    console.log(`PollingSubWindow#showMatchEntryPage: alertMessage: ${alertMessage}`);
    if (alertMessage != null) {
      return AjaxCommunicator.get(Routes.root_path(), {
        alert_message: alertMessage
      });
    } else {
      return AjaxCommunicator.get(Routes.root_path());
    }
  }
  leaveMatch(alertMessage = null) {
    if (this.matchData() != null) {
      console.log(`PollingSubWindow#leaveMatch: alertMessage: ${alertMessage}`);
      let params = this.matchData();
      params.alert_message = alertMessage;
      return this._reload(() => AjaxCommunicator.post(Routes.leave_match_path(), params));
    } else {
      return this._reload(() => this.showMatchEntryPage(alertMessage));
    }
  }
  _reload(reloadMethod) {
    this.stop();
    return reloadMethod();
  }
};

class PollingWindow {
  constructor(subWindow) {
    this.subWindow = subWindow;
  }
  replace(newPollingSubWindow) {
    this.subWindow.close();
    return this.subWindow = newPollingSubWindow;
  }
  close() {
    return this.subWindow.close();
  }
  leaveMatch(alertMessage = null) {
    return this.subWindow.leaveMatch(alertMessage);
  }
  showMatchEntryPage(alertMessage = null) {
    return this.subWindow.showMatchEntryPage(alertMessage);
  }
};

let MatchStartWindow = undefined;
let PlayerActionsWindow = undefined;
class WindowManager {
  static initClass() {

    this.onLoadCallbacks = [];

    let MatchQueueUpdateWindow = undefined;
    let WaitingForMatchWindow = undefined;
    MatchStartWindow = class MatchStartWindow extends PollingWindow {
      static initClass() {
        let MatchQueueUpdatePoller = undefined;
        MatchQueueUpdateWindow = class MatchQueueUpdateWindow extends PollingSubWindow {
          static initClass() {
            MatchQueueUpdatePoller = class MatchQueueUpdatePoller extends Poller {
              static initClass() {
                this.PERIOD = 2000;
              }
              constructor(pollFn) {
                console.log("MatchQueueUpdatePoller#constructor");
                super(pollFn, MatchQueueUpdatePoller.PERIOD);
              }
            };
            MatchQueueUpdatePoller.initClass();
          }

          constructor() {
            console.log("MatchQueueUpdateWindow#constructor");
            super(new MatchQueueUpdatePoller(() => {
              return
            }));
          }
        };
        MatchQueueUpdateWindow.initClass();

        let WaitingForMatchPoller = undefined;
        WaitingForMatchWindow = class WaitingForMatchWindow extends PollingSubWindow {
          static initClass() {
            WaitingForMatchPoller = class WaitingForMatchPoller extends Poller {
              static initClass() {
                this.PERIOD = 2000;
              }
              constructor(pollFn) {
                console.log("WaitingForMatchPoller#constructor");
                super(pollFn, WaitingForMatchPoller.PERIOD);
              }
            };
            WaitingForMatchPoller.initClass();
          }

          constructor(matchData_) {
            console.log(`WaitingForMatchWindow#constructor`);
            super(
              new WaitingForMatchPoller(
                () => AjaxCommunicator.post(
                  Routes.check_for_match_started_path(),
                  params
                )
              )
            );
            this.matchData_ = matchData_;
            console.log(`WaitingForMatchWindow#constructor: matchData: ${JSON.stringify(this.matchData_)}`);
            let params = this.matchData_;
            params.load_previous_messages = true;
          }
          matchData() {
            return this.matchData_;
          }
        };
        WaitingForMatchWindow.initClass();
      }

      constructor(alertMessage = null) {
        console.log(`MatchStartWindow#constructor: alertMessage: ${alertMessage}`);
        super(new MatchQueueUpdateWindow);
        this.matchData_ = null;
        this.showMatchEntryPage(alertMessage);
      }
      matchData() {
        return this.matchData_;
      }
      waitForMatchToStart(matchData_) {
        this.matchData_ = matchData_;
        console.log(`MatchStartWindow#waitForMatchToStart: matchData: ${JSON.stringify(this.matchData_)}`);
        if (!this.isWaitingForMatchToStart()) {
          console.log("MatchStartWindow#waitForMatchToStart: Not waiting yet");
          this.replace(new WaitingForMatchWindow(this.matchData_));
          console.log("MatchStartWindow#waitForMatchToStart: Not waiting yet 3");
          return this.subWindow.poll();
        }
      }
      isWaitingForMatchToStart() {
        console.log("MatchStartWindow#isWaitingForMatchToStart");
        return this.subWindow instanceof WaitingForMatchWindow;
      }
    };
    MatchStartWindow.initClass();
    let MatchSliceWindow = undefined;
    PlayerActionsWindow = class PlayerActionsWindow extends PollingWindow {
      static initClass() {
        let SummaryInformationManager = undefined;
        let MatchSliceWindowPoller = undefined;
        MatchSliceWindow = class MatchSliceWindow extends PollingSubWindow {
          static initClass() {
            SummaryInformationManager = class SummaryInformationManager {
              constructor() {
                this.savedSummaryInfo = $('.summary_information').html();
              }

              update() {
                console.log('SummaryInformationManager#update');
                $('.summary_information').prepend(this.savedSummaryInfo);
                let summaryInfo = document.getElementById('summary_information');
                summaryInfo.scrollTop = summaryInfo.scrollHeight;
                return console.log('SummaryInformationManager#update: Returning');
              }
            };
            MatchSliceWindowPoller = class MatchSliceWindowPoller extends Poller {
              static initClass() {
                this.PERIOD = 1000;
              }
              constructor(pollFn) {
                super(pollFn, MatchSliceWindowPoller.PERIOD);
              }
            };
            MatchSliceWindowPoller.initClass();
          }
          constructor(matchData_, onActionTimeout) {
            super(new MatchSliceWindowPoller(() => this.updateState()));
            this.matchData_ = matchData_;
            this.isSpectating = false;
            this.timer = new ActionTimer(onActionTimeout);
          }
          matchData() {
            return this.matchData_;
          }
          close() {
            this.timer.clear();
            return super.close();
          }
          updateState() {
            console.log("MatchSliceWindow#updateState");
            this.timer.pause();
            return this._reload(() => this._updateState());
          }
          playAction(actionArg) {
            console.log(`MatchSliceWindow#playAction: actionArg: ${actionArg}`);
            this.timer.stop();
            let params = this.matchData_;
            params.poker_action = actionArg;
            return this._reload(() => AjaxCommunicator.post(Routes.play_action_path(), params));
          }
          nextHand() {
            return this.updateState();
          }
          finishUpdating(newMatchData, sliceData) {
            console.log(`MatchSliceWindow#finishUpdating: newMatchData: ${JSON.stringify(newMatchData)}, sliceData: ${JSON.stringify(sliceData)}`);
            this._updateActionTimer(newMatchData);
            if (this.summaryInfoManager != null) {
              this.summaryInfoManager.update();
            }
            this.matchData_ = newMatchData;
            GameInterface.adjustScale();
            this._wireActions(sliceData);
            return this._checkToStartPolling(sliceData);
          }
          leaveMatch(alertMessage = null) {
            console.log(`MatchSliceWindow#leaveMatch: alertMessage: ${alertMessage}`);
            this.timer.stop();
            return super.leaveMatch(alertMessage);
          }

          _wireActions(sliceData) {
            console.log(`MatchSliceWindow#_wireActions: sliceData: ${JSON.stringify(sliceData)}`);
            if (sliceData.match_has_ended) {
              return $(".leave-btn").click(() => this.leaveMatch());
            } else if (sliceData.next_hand_button_is_visible) {
              return $(".next_hand_id").click(() => this.nextHand());
            } else {
              $(".fold").click(() => this.playAction("f"));
              $(".pass").click(() => this.playAction("c"));
              return $(".wager").click(() => {
                let wagerAmount = wagerAmountField().val();
                let action = 'r';
                if (!WindowManager.isBlank(wagerAmount)) {
                  action += wagerAmount;
                }
                return this.playAction(action);
              });
            }
          }

          _setInitialFocus(sliceData) {
            if (sliceData.match_has_ended) {
              return $(".leave-btn").focus();
            } else if (sliceData.next_hand_button_is_visible) {
              return $(".next_hand_id").focus();
            } else {
              return wagerAmountField().focus();
            }
          }

          _updateActionTimer(newMatchData) {
            console.log(`MatchSliceWindow#_updateActionTimer: newMatchData: ${JSON.stringify(newMatchData)}`);
            if (newMatchData.match_slice_index >= this.matchData_.match_slice_index || !this.timer.isCounting()) {
              console.log("MatchSliceWindow#_updateActionTimer: Starting action timer");
              return this.timer.start();
            } else if (this.matchData_.match_has_ended) {
              return this.timer.clear();
            } else {
              console.log("MatchSliceWindow#_updateActionTimer: Resuming action timer");
              return this.timer.resume();
            }
          }

          _checkToStartPolling(sliceData) {
            console.log(`MatchSliceWindow#_checkToStartPolling: sliceData: ${JSON.stringify(sliceData)}`);
            if (sliceData.is_users_turn_to_act || sliceData.next_hand_button_is_visible || sliceData.match_has_ended) {
              console.log("MatchSliceWindow#finishUpdatingPlayerActionsWindow: No polling");
              return this.stop();
            } else {
              console.log("MatchSliceWindow#finishUpdatingPlayerActionsWindow: Started polling");
              return this.poll();
            }
          }

          _reload(reloadMethod) {
            this.summaryInfoManager = new SummaryInformationManager;
            return super._reload(reloadMethod);
          }

          _updateState() {
            console.log("MatchSliceWindow#forceUpdateState");
            return AjaxCommunicator.post(Routes.match_home_path(), this.matchData_);
          }
        };
        MatchSliceWindow.initClass();
      }

      constructor(matchData, onActionTimeout) {
        console.log(`PlayerActionsWindow#constructor: matchData: ${JSON.stringify(matchData)}`);
        super(new MatchSliceWindow(matchData, onActionTimeout));
      }

      finishUpdating(matchData, sliceData) {
        console.log("PlayerActionsWindow#finishUpdating");
        return this.subWindow.finishUpdating(matchData, sliceData);
      }

      matchData() {
        return this.subWindow.matchData();
      }

      emitChatMessage(user, msg) {
          return console.log("PlayerActionsWindow#emitChatMessage");
        }
        // @socket.emit(
        //   @constructor.constants.PLAYER_COMMENT,
        //   {
        //     matchId: @matchId,
        //     user: user,
        //     message: msg
        //   }
        // )

      onPlayerComment(data = '') {
        return console.log(`PlayerActionsWindow#onPlayerComment: data: ${data}`);
      }
    };
    PlayerActionsWindow.initClass();
  }
  static isBlank(str) {
    return (!str || /^[\"\'\s]*$/.test(str));
  }
  static isEmpty(el) {
    return !$.trim(el.html());
  }
  static loadComplete() {
    console.log(`WindowManager::loadComplete: @onLoadCallbacks.length: ${this.onLoadCallbacks.length}`);
    while (this.onLoadCallbacks.length > 0) {
      this.onLoadCallbacks.shift()();
    }
    return console.log("WindowManager::loadComplete: Finished all callbacks");
  }

  static packageMatchData(matchId, sliceIndexString) {
    return {
      match_id: matchId,
      match_slice_index: parseInt(sliceIndexString, 10)
    };
  }

  constructor() {
    this.window = new MatchStartWindow;
  }

  waitForMatchToStart(matchData) {
    console.log(`WindowManager#waitForMatchToStart: matchData: ${JSON.stringify(matchData)}`);
    if ('waitForMatchToStart' in this.window) {
      if (matchData.match_slice_index < 0) {
        matchData.match_slice_index = 0;
      }
      return this.window.waitForMatchToStart(matchData);
    } else {
      return console.log("WindowManager#waitForMatchToStart: WARNING: Called when @window is not a MatchStartWindow!");
    }
  }

  showMatchEntryPage(alertMessage = null) {
    this.window.close();
    return this.window = new MatchStartWindow(alertMessage);
  }

  leaveMatch(alertMessage = null) {
    return this.window.leaveMatch(alertMessage);
  }

  // onMatchHasStarted: ->
  // console.log "WindowManager#onMatchHasStarted"
  // Chat.init(
  //   @userName,
  //   (id, user, msg)=>
  //     @emitChatMessage user, msg
  // )
  // @_initPlayerActionsWindow @window.matchData

  finishUpdating() {
    console.log("WindowManager#finishUpdating");
    return this.window.subWindow.poll();
  }

  finishUpdatingMatchStartWindow() {
    console.log("WindowManager#finishUpdatingMatchStartWindow");
    return this.finishUpdating();
  }

  finishUpdatingPlayerActionsWindow(matchData, sliceData) {
    console.log(
      "WindowManager#finishUpdatingPlayerActionsWindow: matchData:" +
      ` ${JSON.stringify(matchData)}, sliceData: ${JSON.stringify(sliceData)}`
    );
    matchData.match_slice_index += 1;
    if (!(this.window instanceof PlayerActionsWindow)) {
      $.titleAlert(
        'Match Started!', {
          requireBlur: true,
          stopOnFocus: true,
          duration: 55000,
          interval: 700
        }
      );
      this._initPlayerActionsWindow(matchData);
    }
    this.window.finishUpdating(matchData, sliceData);
    return console.log("WindowManager#finishUpdatingPlayerActionsWindow: Returning");
  }

  _initPlayerActionsWindow(matchData) {
    this.window.close();
    let onActionTimeout = CONFIG.ON_TIMEOUT === 'fold' ?
      () => {
        if ($(".next_hand_id").length !== 0) {
          console.log("WindowManager#_initPlayerActionsWindow: onActionTimeout: Pressing next hand button.");
          return $(".next_hand_id").click();
        } else if ($(".fold").attr('disabled') !== 'disabled') {
          console.log("WindowManager#_initPlayerActionsWindow: onActionTimeout: Pressing fold button.");
          return $(".fold").click();
        } else {
          console.log("WindowManager#_initPlayerActionsWindow: onActionTimeout: Pressing pass button.");
          return $(".pass").click();
        }
      } :
      () => {
        // if @isSpectating
        //   alert('The match has timed out.')
        // else
        return this.leaveMatch('The match has timed out.');
      };
    return this.window = new PlayerActionsWindow(matchData, onActionTimeout);
  }
}
WindowManager.initClass();

export {
  ConsoleLogManager,
  WindowManager
};

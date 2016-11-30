class Timer {
  constructor() {
    this.timeoutId = null;
  }
  isCounting() {
    return (this.timeoutId != null);
  }
  clear() {
    if (this.timeoutId != null) {
      clearTimeout(this.timeoutId);
      return this.timeoutId = null;
    }
  }
  start(fn, period) {
    if (this.isCounting()) {
      this.stop();
    }
    return this.timeoutId = setTimeout(fn, period);
  }
  stop() {
    return this.clear();
  }
}

class ActionTimer extends Timer {
  constructor(onTimeout) {
    super();
    this.onTimeout = onTimeout;
  }
  getTimeRemaining() {
    return parseInt($('.time-remaining').text(), 10);
  }
  setTimeRemaining(timeRemaining) {
    if ((timeRemaining == null) || isNaN(timeRemaining)) {
      return;
    }
    if (timeRemaining < 0) {
      timeRemaining = 0;
    }
    return $('.time-remaining').text(timeRemaining);
  }
  start() {
    return super.start(
      () => this.afterEachSecond(this.onTimeout),
      1000
    );
  }
  afterEachSecond() {
    let timeRemaining = this.getTimeRemaining();
    if (timeRemaining != null) {
      if (timeRemaining <= 0) {
        return this.onTimeout();
      } else {
        this.setTimeRemaining(timeRemaining - 1);
        return this.start(() => this.afterEachSecond(this.onTimeout));
      }
    } else {
      return this.start(() => this.afterEachSecond(this.onTimeout));
    }
  }
  pause() {
    return this.timeRemaining = this.getTimeRemaining();
  }
  resume() {
    return this.setTimeRemaining(this.timeRemaining);
  }
}
export {
  Timer,
  ActionTimer
};

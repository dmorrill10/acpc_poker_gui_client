class CounterQueue {
  constructor(length=0){
    this.length = length;
  }

  push(){ return this.length += 1; }
  pop(){ if (!this.isEmpty()) { return this.length -= 1; } }
  reset(){ return this.length = 0; }
  isEmpty(){ return this.length === 0; }
}
export default CounterQueue;

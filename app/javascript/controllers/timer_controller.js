import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    seconds: {type: Number}
  }

  connect() {
    this.remaining = this.secondsValue;
    this.interval = setInterval(() => this.tick(), 1000);
  }

  tick() {
    console.log('tick', this.remaining);
    this.remaining--;
    this.element.textContent = this.remaining;

    if (this.remaining <= 10) {
      this.element.classList.add("text-error");
      this.element.classList.remove("text-primary");
    }

    if (this.remaining <= 0) {
      clearInterval(this.interval);
    }
  }

  disconnect() {
    clearInterval(this.interval);
  }
}
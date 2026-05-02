import { Controller } from "@hotwired/stimulus"
import GameChannel from "channels/game_channel"

export default class extends Controller {
  static values = {
    roomId: Number,
    isDrawer: Boolean
  }

  connect() {
    this.currentUserId = parseInt(
      document.querySelector('meta[name="current-user-id"]')?.content
    )

    GameChannel.subscribe(this.roomIdValue)
    GameChannel.on("chat", (data) => this.receiveMessage(data))

    this.setupChatInput()
  }

  setupChatInput() {
    // use event delegation on the controller element
    // works even when input/button are added later via Turbo Stream
    this.element.addEventListener("click", (e) => {
      if (e.target.closest("#send-guess")) {
        this.sendMessage()
      }
    })

    this.element.addEventListener("keydown", (e) => {
      if (e.key === "Enter" && e.target.id === "guess-input") {
        this.sendMessage()
      }
    })
  }

  sendMessage() {
    const input = document.getElementById("guess-input")
    if (!input) return
    const message = input.value.trim()
    if (!message) return

    GameChannel.perform("chat", {
      message: message,
      room_id: this.roomIdValue,
      userId: this.currentUserId,
    })

    input.value = ""
  }

  receiveMessage(data) {
    const chatMessages = document.getElementById("chat-messages")
    if (!chatMessages) return

    // close messages only shown to the person who sent it
    if (data.status === "close" && data.user_id !== this.currentUserId) return

    const div = document.createElement("div")

    if (data.status === "correct") {
      div.className = "p-2 bg-green-100 border-l-4 border-green-600 text-green-800 font-bold text-sm rounded-r"
      div.textContent = `🎉 ${data.user} guessed the word!`
    } else if (data.status === "close") {
      div.className = "p-2 bg-secondary-container border-l-4 border-secondary font-bold text-sm rounded-r"
      div.textContent = `🔥 So close! Keep trying...`
    } else {
      div.className = "flex gap-2 text-sm py-1"
      div.innerHTML = `<span class="font-bold text-tertiary">${data.user}:</span><span>${data.message}</span>`
    }

    chatMessages.appendChild(div)
    chatMessages.scrollTop = chatMessages.scrollHeight
  }
}

window.addEventListener("beforeunload", () => {
  GameChannel.unsubscribe()
})
import consumer from "channels/consumer"

const GameChannel = {
  subscription: null,
  handlers: {},

  subscribe(roomId){
    if (this.subscription) return

    this.subscription = consumer.subscriptions.create(
      { channel: "GameChannel", room_id: roomId },
      {
        received: (data)=> {
          const handler = this.handlers[data.type]
          if (handler) handler(data)
        }
      }
    )
  },

  on(type, callback) {
    this.handlers[type] = callback
  },

  perform(action, data) {
    this.subscription?.perform(action, data)
  },
  
  unsubscribe() {
    this.subscription?.unsubscribe()
    this.subscription = null
    this.handlers = {}
  }
}

export default GameChannel
